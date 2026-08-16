#!/usr/bin/env python3
"""Genera UN video por secuencia con la voz ya integrada, para Roku.

Por que existe: el reproductor de Roku (PlayerScreen) intentaba reproducir
un Video de fondo Y un Audio con la voz al mismo tiempo, y Roku no lo
permite -- "only one playing instance supported" (error -5). La misma
lección que ya aprendimos con Alexa (que tampoco podía encadenar decenas
de clips sueltos) aplica aqui: en vez de dos streams peleando por el mismo
reproductor, se renderiza UN solo archivo -- loop visual + voz mezclada --
y Roku lo reproduce con un solo nodo Video (el audio va incrustado en el
propio MP4, no es un segundo stream).

Fondo visual: un video REAL de la esfera (no generado -- el usuario lo
grabo/proveyo), assets/portadas/esfera_video_base.mp4 -- ya transcodificado
desde el .MOV original (HEVC 1920x1080) a H.264 1280x720 sin audio, listo
para -stream_loop.

El codigo SI va horneado en el video (pedido explicito: "se ve mas
premium" con un video por secuencia). Cada digito se dibuja siempre en
version "apagada", y se enciende (color dorado) solo durante la(s)
ventana(s) de tiempo exactas en que su clip de voz suena -- una ventana
por repeticion. Esas ventanas salen de construir_audio(), que arma el
audio pieza por pieza llevando la cuenta del tiempo acumulado (nunca
concatena bloques ya armados sin saber sus offsets). El "_" separador de
grupos no tiene clip de voz (pedido explicito: sin decir "espacio", solo
el hueco) y no se enciende nunca, solo ocupa mas ancho en pantalla.

Cierre: outro hablado y personalizado por secuencia ("...tu secuencia
para {nombre}"), generado con TTS y cacheado en output/tts_cache/ para no
regenerar en cada re-render.

El intro (las instrucciones de como prepararse) YA NO se genera aqui: es
igual para las ~1000 secuencias, asi que se renderiza UNA sola vez en
scripts/generar_intro_cortinilla.py y este script solo antepone ese
archivo por copia de stream (ffmpeg -c copy, practicamente gratis) al
final -- eso es lo que hace que generar cientos de videos sea viable en
vez de pagar el costo del intro una y otra vez. Hay que correr
generar_intro_cortinilla.py una vez antes de usar este script.

Duracion: las repeticiones apuntan a ~120s (pedido explicito: "2 minutos
+- algunos segundos para terminar la ultima repeticion completa"). Si
las 10 repeticiones no caben, se reducen (igual que render_alexa_audio.py,
con un piso de 3).

Uso:
  python3 scripts/generar_video_narrado.py --codigo 919_819_714 --voz female
  python3 scripts/generar_video_narrado.py --codigo 919_819_714 --voz female --subir
  python3 scripts/generar_video_narrado.py --limite 10 --voz female --subir

Pide SUPABASE_URL, SB_SERVICE_ROLE_KEY y OPENAI_API_KEY si hace falta
(.env, variable de entorno, o por consola; nada se escribe a disco) --
esta ultima solo hace falta si no se pasa --sin-outro.
"""

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_assets_secuencias import (  # noqa: E402
    RAIZ, cargar_env, obtener_secuencias, subir_archivo,
)

DIR_VOCES = os.path.join(RAIZ, 'assets', 'audios', 'voice_numbers')
DIR_MUSICA = os.path.join(RAIZ, 'assets', 'audios')
DIR_SALIDA = os.path.join(RAIZ, 'output', 'videos_narrados')
DIR_CACHE_TTS = os.path.join(RAIZ, 'output', 'tts_cache')
ESFERA_VIDEO_BASE = os.path.join(RAIZ, 'assets', 'portadas', 'esfera_video_base.mp4')
# Cortinilla de intro pre-renderizada (ver generar_intro_cortinilla.py),
# antepuesta por copia de stream -- ya no se genera intro por secuencia.
CORTINILLA_MP4 = os.path.join(RAIZ, 'output', 'intro_cortinilla', 'intro_cortinilla.mp4')

# Bajado de 280 -> 450: a 280ms sonaba "atropellado", pedido explicito de
# bajar la velocidad al decir los numeros.
GAP_DIGITOS_MS = 450
# Ya no se dice la palabra "espacio" (pedido explicito) -- esto es solo
# el hueco de silencio que la reemplaza entre grupos.
PAUSA_SEPARADOR_MS = 550
PAUSA_NUEVAMENTE_MS = 1800
PAUSA_ANTES_OUTRO_MS = 900
REPETICIONES = 10
MIN_REPETICIONES = 3
# Bajado de 180 -> 120 ("2 minutos +- algunos segundos", pedido
# explicito) al separar el intro en su propia cortinilla reutilizable:
# ya no hace falta que las repeticiones carguen con el presupuesto de
# duracion del intro tambien.
MAX_DURACION_S = 120
# El 0.75 que usa render_alexa_audio.py (compensando la normalizacion de
# amix) tapaba la voz aqui. Bajado primero a 0.2, seguia alta -- a 12%.
VOLUMEN_MUSICA = 0.12
# El mp3 del TTS (intro y outro) sale ~11 dB mas bajo que los clips de voz
# grabados (voice_numbers/*), asi que sin esto suena como si la locutora
# "bajara la voz". alimiter evita que la ganancia sature/distorsione los
# picos.
TTS_GANANCIA_DB = 9
TTS_VOZ = 'coral'
TTS_INSTRUCCIONES = (
    'Habla en español neutro, pronunciación clara y natural, como una '
    'locutora hispanohablante nativa. Tono cálido, alegre y celebratorio, '
    'ritmo pausado.'
)
SR = 24000

# Este pipeline corre en varias maquinas (Mac, Windows) para repartir el
# render de las ~1000 secuencias -- las rutas de fuentes del sistema y el
# encoder de video disponible no son los mismos en cada una, asi que se
# resuelven segun el sistema operativo en vez de venir fijos a mano.
SISTEMA = platform.system()  # 'Darwin' (mac), 'Windows', 'Linux'


def _ruta_fuente(candidatas, descripcion):
    for ruta in candidatas:
        if os.path.isfile(ruta):
            return ruta
    sys.exit(
        f'No encuentro una fuente de sistema para {descripcion} en este SO ({SISTEMA}). '
        f'Probe: {candidatas}. Instala alguna de esas fuentes o ajusta la ruta a mano.'
    )


# Digitos horneados en el video: apagados por default, dorado mientras
# suena su clip. El ffmpeg de esta maquina no tiene libfreetype (no hay
# filtro drawtext -- "No such filter"), asi que el texto se dibuja con
# PIL a PNGs transparentes y se componen con el filtro 'overlay' (nucleo,
# siempre disponible) en vez de horneable directo por ffmpeg. Fuente
# monoespaciada para que el ancho por caracter sea predecible.
if SISTEMA == 'Windows':
    FONT_PATH = _ruta_fuente([r'C:\Windows\Fonts\courbd.ttf'], 'los digitos (Courier Bold)')
elif SISTEMA == 'Darwin':
    FONT_PATH = _ruta_fuente(
        ['/System/Library/Fonts/Supplemental/Courier New Bold.ttf'], 'los digitos (Courier Bold)'
    )
else:
    FONT_PATH = _ruta_fuente([
        '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf',
    ], 'los digitos (Courier Bold)')

ANCHO_VIDEO = 1280
ALTO_VIDEO = 720
MAX_ANCHO_DIGITOS = 1100
ANCHO_SEPARADOR_FACTOR = 1.5
COLOR_APAGADO_RGBA = (255, 255, 255, 70)   # blanco ~28% opacidad
COLOR_ENCENDIDO_RGBA = (255, 215, 0, 255)  # dorado solido
# Borde negro sutil en el digito encendido: sin esto el dorado se pierde
# contra la esfera dorada de fondo. Proporcional al tamaño de fuente
# (que varia con el largo del codigo) para que se vea igual de sutil en
# codigos cortos y largos.
COLOR_BORDE_ENCENDIDO_RGBA = (0, 0, 0, 255)
FACTOR_BORDE_ENCENDIDO = 0.025

VOCES_SLUG = {'female': 'female', 'male': 'male', 'male 2': 'male2'}


def sh(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'ffmpeg fallo:\n{" ".join(args)}\n{r.stderr[-2000:]}')
    return r


def duracion(path):
    r = sh(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path])
    return float(r.stdout.strip())


_ENCODER_VIDEO_CACHE = None


def _encoder_disponible(nombre, args_extra):
    prueba = subprocess.run(
        ['ffmpeg', '-y', '-v', 'error', '-f', 'lavfi', '-i', 'color=black:s=64x64:d=0.1',
         '-c:v', nombre] + args_extra + ['-f', 'null', '-'],
        capture_output=True, text=True,
    )
    return prueba.returncode == 0


def obtener_encoder_video():
    """Encoder por hardware si esta disponible (~4x mas rapido que
    libx264, ver el aviso en generar_video_narrado()), probado con un
    encode real de 0.1s -- que ffmpeg lo liste en -encoders no garantiza
    que el hardware este presente y funcionando. Cae a libx264 (mas
    lento pero universal) si no hay ninguno. Se prueba una sola vez por
    corrida (cacheado) para no repetir el sondeo en cada video."""
    global _ENCODER_VIDEO_CACHE
    if _ENCODER_VIDEO_CACHE is not None:
        return _ENCODER_VIDEO_CACHE

    candidatos = []
    if SISTEMA == 'Darwin':
        candidatos.append(('h264_videotoolbox', ['-b:v', '800k', '-maxrate', '1000k']))
    else:
        # Windows/Linux: NVIDIA, Intel, AMD, en ese orden -- el que este
        # presente en la maquina se detecta con el intento de encode.
        candidatos.append(('h264_nvenc', ['-b:v', '800k', '-maxrate', '1000k']))
        candidatos.append(('h264_qsv', ['-b:v', '800k', '-maxrate', '1000k']))
        candidatos.append(('h264_amf', ['-b:v', '800k', '-maxrate', '1000k']))
    candidatos.append(('libx264', ['-preset', 'veryfast', '-crf', '26']))

    for nombre, args_extra in candidatos:
        if _encoder_disponible(nombre, args_extra):
            print(f'Encoder de video: {nombre}', file=sys.stderr)
            _ENCODER_VIDEO_CACHE = ['-c:v', nombre] + args_extra
            return _ENCODER_VIDEO_CACHE

    sys.exit('Ningun encoder de video funciono (ni siquiera libx264) -- revisa la instalacion de ffmpeg.')


def a_wav(origen, destino):
    sh(['ffmpeg', '-y', '-v', 'error', '-i', origen, '-ac', '1', '-ar', str(SR), destino])


def tts_a_wav(origen, destino):
    """Como a_wav, pero con la ganancia que compensa que el TTS sale mas
    bajo que los clips de voz grabados (ver TTS_GANANCIA_DB)."""
    sh(['ffmpeg', '-y', '-v', 'error', '-i', origen,
        '-af', f'volume={TTS_GANANCIA_DB}dB,alimiter=limit=0.97',
        '-ac', '1', '-ar', str(SR), destino])


def silencio(ms, destino):
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'lavfi',
        '-i', f'anullsrc=r={SR}:cl=mono', '-t', f'{ms / 1000:.3f}', destino])


def concat(piezas, destino, tmp):
    lista = os.path.join(tmp, f'lista_{os.path.basename(destino)}.txt')
    with open(lista, 'w') as f:
        for p in piezas:
            f.write(f"file '{p}'\n")
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', lista, '-c', 'copy', destino])


def generar_outro_tts(nombre, codigo, api_key):
    """Cierre hablado y personalizado ("...tu secuencia para {nombre}").
    Cacheado por codigo para no regenerar (ni pagar la llamada a OpenAI)
    en cada re-render de prueba."""
    os.makedirs(DIR_CACHE_TTS, exist_ok=True)
    destino = os.path.join(DIR_CACHE_TTS, f'outro_{codigo}.mp3')
    if os.path.isfile(destino) and os.path.getsize(destino) > 1000:
        return destino

    if not api_key:
        sys.exit('Falta OPENAI_API_KEY (necesaria para generar el outro; usa --sin-outro para omitirlo, o proporciona la clave).')

    texto = f'Felicidades, acabas de activar satisfactoriamente tu secuencia para {nombre}.'
    payload = json.dumps({
        'model': 'gpt-4o-mini-tts',
        'voice': TTS_VOZ,
        'input': texto,
        'instructions': TTS_INSTRUCCIONES,
        'response_format': 'mp3',
    })
    r = subprocess.run(
        ['curl', '-s', '-S', 'https://api.openai.com/v1/audio/speech',
         '-H', f'Authorization: Bearer {api_key}',
         '-H', 'Content-Type: application/json',
         '-d', payload,
         '-o', destino],
        capture_output=True, text=True,
    )
    if r.returncode != 0 or not os.path.isfile(destino) or os.path.getsize(destino) < 1000:
        sys.exit(f'Fallo generando outro TTS para "{nombre}": {r.stderr}')
    return destino


def mezclar_musica(voz_wav, musica_mp3, tmp):
    """Musica en bucle recortada al largo de la voz, con fundido de
    entrada/salida, mezclada debajo de la voz (mismo patron que
    render_alexa_audio.py)."""
    dur = duracion(voz_wav)
    fade = 2.0
    salida = os.path.join(tmp, 'con_musica.wav')
    sh(['ffmpeg', '-y', '-v', 'error',
        '-stream_loop', '-1', '-i', musica_mp3,
        '-i', voz_wav,
        '-filter_complex',
        f'[0:a]atrim=0:{dur:.3f},volume={VOLUMEN_MUSICA},'
        f'afade=t=in:st=0:d={fade},afade=t=out:st={max(0, dur - fade):.3f}:d={fade}[mus];'
        f'[mus][1:a]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,'
        f'alimiter=limit=0.95[out]',
        '-map', '[out]', '-ac', '1', '-ar', str(SR),
        salida])
    return salida


def construir_audio(codigo, nombre, voz, tmp, api_key, incluir_outro=True):
    """Arma el audio completo pieza por pieza, llevando la cuenta del
    tiempo acumulado, para poder devolver tambien las ventanas de tiempo
    exactas en que suena cada digito (eventos_por_slot) -- eso es lo que
    despues sincroniza el "encendido" del digito horneado en el video."""
    dir_voz = os.path.join(DIR_VOCES, voz)
    if not os.path.isdir(dir_voz):
        sys.exit(f'No existe la carpeta de voz: {dir_voz}')

    tokens = [c for c in codigo if c.isdigit() or c == '_']
    if not any(c.isdigit() for c in tokens):
        sys.exit(f'El codigo no tiene digitos: {codigo}')

    clips = {}
    clips_dur = {}
    for nombre_clip in set(t for t in tokens if t != '_') | {'nuevamente'}:
        origen = os.path.join(dir_voz, f'{nombre_clip}.mp3')
        if not os.path.isfile(origen):
            sys.exit(f'Falta el clip de voz: {origen}')
        destino = os.path.join(tmp, f'clip_{nombre_clip}.wav')
        a_wav(origen, destino)
        clips[nombre_clip] = destino
        clips_dur[nombre_clip] = duracion(destino)

    sil_gap = os.path.join(tmp, 'sil_gap.wav')
    sil_separador = os.path.join(tmp, 'sil_separador.wav')
    sil_nue = os.path.join(tmp, 'sil_nue.wav')
    silencio(GAP_DIGITOS_MS, sil_gap)
    silencio(PAUSA_SEPARADOR_MS, sil_separador)
    silencio(PAUSA_NUEVAMENTE_MS, sil_nue)
    d_gap = GAP_DIGITOS_MS / 1000.0
    d_separador = PAUSA_SEPARADOR_MS / 1000.0
    d_nue = PAUSA_NUEVAMENTE_MS / 1000.0

    d_rep = sum((d_separador if t == '_' else clips_dur[t] + d_gap) for t in tokens)
    d_enlace = 2 * d_nue + clips_dur['nuevamente']

    # Tope de ~120s para las repeticiones (el outro se suma aparte, el
    # intro ya no vive aqui -- ver CORTINILLA_MP4): si las 10 no caben,
    # se reducen (piso de 3) -- mismo calculo que render_alexa_audio.py.
    cabe = int((MAX_DURACION_S + d_enlace) // (d_rep + d_enlace))
    reps = max(MIN_REPETICIONES, min(REPETICIONES, cabe))
    if reps < REPETICIONES:
        print(f'aviso: {codigo} es largo ({d_rep:.0f}s por repeticion); se usan {reps} repeticiones en vez de {REPETICIONES} para caber en {MAX_DURACION_S}s.', file=sys.stderr)

    piezas = []
    eventos_por_slot = {j: [] for j, t in enumerate(tokens) if t != '_'}
    tiempo = 0.0

    def agregar(path, dur):
        nonlocal tiempo
        piezas.append(path)
        inicio = tiempo
        tiempo += dur
        return inicio, tiempo

    for r in range(reps):
        for j, t in enumerate(tokens):
            if t == '_':
                agregar(sil_separador, d_separador)
            else:
                inicio, fin = agregar(clips[t], clips_dur[t])
                eventos_por_slot[j].append((inicio, fin))
                agregar(sil_gap, d_gap)
        if r < reps - 1:
            agregar(sil_nue, d_nue)
            agregar(clips['nuevamente'], clips_dur['nuevamente'])
            agregar(sil_nue, d_nue)

    if incluir_outro:
        outro_mp3 = generar_outro_tts(nombre, codigo, api_key)
        sil_outro = os.path.join(tmp, 'sil_outro.wav')
        silencio(PAUSA_ANTES_OUTRO_MS, sil_outro)
        agregar(sil_outro, PAUSA_ANTES_OUTRO_MS / 1000.0)

        outro_wav = os.path.join(tmp, 'outro.wav')
        tts_a_wav(outro_mp3, outro_wav)
        agregar(outro_wav, duracion(outro_wav))

    completa = os.path.join(tmp, 'voz.wav')
    concat(piezas, completa, tmp)
    return completa, tokens, eventos_por_slot


def calcular_posiciones_digitos(tokens):
    """Ancho/tamaño de fuente que se ajustan al numero de caracteres para
    que codigos largos sigan cabiendo en MAX_ANCHO_DIGITOS. El "_" ocupa
    mas ancho (separador de grupos) pero no tiene posicion de glifo. La
    fila completa se centra verticalmente en el cuadro (pedido explicito,
    no una posicion fija) -- para eso se mide el alto real del glifo con
    getbbox() en vez de asumir una altura de linea generica: (x,y) de
    PIL es la esquina superior del cuadro de la fuente, que casi siempre
    tiene aire de mas arriba/abajo del trazo visible."""
    n_efectivo = sum(ANCHO_SEPARADOR_FACTOR if t == '_' else 1 for t in tokens)
    ancho_char = max(40.0, min(95.0, MAX_ANCHO_DIGITOS / n_efectivo))
    tam_fuente = round(ancho_char * 1.3)
    anchos = [ancho_char * ANCHO_SEPARADOR_FACTOR if t == '_' else ancho_char for t in tokens]
    ancho_total = sum(anchos)
    cursor = (ANCHO_VIDEO - ancho_total) / 2

    font = ImageFont.truetype(FONT_PATH, tam_fuente)
    izquierda, arriba, derecha, abajo = font.getbbox('0123456789')
    y = (ALTO_VIDEO - (abajo - arriba)) / 2 - arriba

    posiciones = {}
    for j, t in enumerate(tokens):
        if t != '_':
            posiciones[j] = (cursor, y)
        cursor += anchos[j]
    return posiciones, tam_fuente, font


def generar_overlays_digitos(tokens, eventos_por_slot, tmp):
    """PNGs transparentes con el texto ya dibujado (PIL), para componer
    con el filtro 'overlay' -- este ffmpeg no tiene libfreetype (drawtext
    no existe: "No such filter: 'drawtext'"). Un PNG base con todos los
    digitos "apagados" (siempre visible) mas un PNG por digito con SOLO
    ese digito en dorado (transparente en todo lo demas), superpuesto
    encima del base unicamente durante sus ventanas de tiempo -- como
    coinciden en fuente/tamaño/posicion con el digito apagado de abajo,
    lo tapa por completo y se ve como si "se encendiera".
    Devuelve una lista [(ruta_png, eventos_o_None), ...] en orden de
    composicion (None = siempre visible)."""
    posiciones, tam_fuente, font = calcular_posiciones_digitos(tokens)

    base = Image.new('RGBA', (ANCHO_VIDEO, ALTO_VIDEO), (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)
    for j, (x, y) in posiciones.items():
        draw.text((x, y), tokens[j], font=font, fill=COLOR_APAGADO_RGBA)
    base_path = os.path.join(tmp, 'overlay_base.png')
    base.save(base_path)

    ancho_borde = max(1, round(tam_fuente * FACTOR_BORDE_ENCENDIDO))

    capas = [(base_path, None)]
    for j, (x, y) in posiciones.items():
        eventos = eventos_por_slot.get(j) or []
        if not eventos:
            continue
        img = Image.new('RGBA', (ANCHO_VIDEO, ALTO_VIDEO), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.text(
            (x, y), tokens[j], font=font, fill=COLOR_ENCENDIDO_RGBA,
            stroke_width=ancho_borde, stroke_fill=COLOR_BORDE_ENCENDIDO_RGBA,
        )
        ruta = os.path.join(tmp, f'overlay_{j}.png')
        img.save(ruta)
        capas.append((ruta, eventos))
    return capas


def construir_cadena_overlays(capas, indice_input_inicial):
    """Arma los argumentos -loop 1 -i por cada PNG y la cadena de filtros
    overlay encadenados (cada capa se compone sobre la salida de la
    anterior). Devuelve (args_de_entrada, texto_filter_complex,
    etiqueta_de_salida_final)."""
    entradas = []
    partes = []
    etiqueta_previa = '0:v'
    idx = indice_input_inicial
    for i, (ruta, eventos) in enumerate(capas):
        entradas += ['-loop', '1', '-i', ruta]
        etiqueta_salida = f'ov{i}'
        if eventos is None:
            partes.append(f'[{etiqueta_previa}][{idx}:v]overlay=x=0:y=0[{etiqueta_salida}]')
        else:
            ventanas = '+'.join(f'between(t,{i0:.3f},{i1:.3f})' for i0, i1 in eventos)
            partes.append(f"[{etiqueta_previa}][{idx}:v]overlay=x=0:y=0:enable='{ventanas}'[{etiqueta_salida}]")
        etiqueta_previa = etiqueta_salida
        idx += 1
    return entradas, ';'.join(partes), etiqueta_previa


def concatenar_con_cortinilla(parte2, ruta_salida, tmp):
    """Antepone la cortinilla de intro pre-renderizada por copia de
    stream -- ambos archivos salen del mismo comando ffmpeg (mismo
    codec/resolucion/pix_fmt), asi que -c copy solo remuxea, no
    recodifica: el costo es el de leer y escribir el archivo, nada mas."""
    if not os.path.isfile(CORTINILLA_MP4):
        sys.exit(
            f'Falta la cortinilla de intro: {CORTINILLA_MP4}\n'
            'Corre primero: python3 scripts/generar_intro_cortinilla.py'
        )
    lista = os.path.join(tmp, 'concat_final.txt')
    with open(lista, 'w') as f:
        f.write(f"file '{CORTINILLA_MP4}'\n")
        f.write(f"file '{parte2}'\n")
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', lista, '-c', 'copy', ruta_salida])


def generar_video_narrado(sec, voz, ruta_salida, api_key, incluir_outro=True, musica=None):
    if not os.path.isfile(ESFERA_VIDEO_BASE):
        sys.exit(f'No encuentro {ESFERA_VIDEO_BASE}')
    if not os.path.isfile(CORTINILLA_MP4):
        sys.exit(
            f'Falta la cortinilla de intro: {CORTINILLA_MP4}\n'
            'Corre primero: python3 scripts/generar_intro_cortinilla.py'
        )

    tmp = tempfile.mkdtemp(prefix='roku_video_narrado_')
    try:
        audio_wav, tokens, eventos_por_slot = construir_audio(
            sec['codigo'], sec['nombre'], voz, tmp, api_key, incluir_outro=incluir_outro,
        )
        if musica:
            audio_wav = mezclar_musica(audio_wav, musica, tmp)
        dur = duracion(audio_wav)

        capas = generar_overlays_digitos(tokens, eventos_por_slot, tmp)
        # input 0 = esfera (en loop), input 1 = audio; las capas de PNG
        # empiezan en el indice 2.
        entradas_overlay, filtro_overlay, etiqueta_final = construir_cadena_overlays(capas, 2)

        # Encoder por hardware si esta disponible (~4x mas rapido que
        # libx264 -- con cientos de secuencias por generar,
        # sincronizar_videos_narrados.py, libx264+preset medio hacia que
        # cada video tardara varios minutos). Se auto-detecta segun la
        # maquina (Mac/Windows/Linux), ver obtener_encoder_video().
        parte2 = os.path.join(tmp, 'parte2.mp4')
        cmd = [
            'ffmpeg', '-y', '-v', 'error',
            '-stream_loop', '-1', '-i', ESFERA_VIDEO_BASE,
            '-i', audio_wav,
        ] + entradas_overlay + [
            '-filter_complex', filtro_overlay,
            '-map', f'[{etiqueta_final}]', '-map', '1:a',
            '-t', f'{dur:.3f}',
        ] + obtener_encoder_video() + [
            '-pix_fmt', 'yuv420p',
            '-c:a', 'aac', '-b:a', '96k',
            '-movflags', '+faststart',
            parte2,
        ]
        sh(cmd)

        concatenar_con_cortinilla(parte2, ruta_salida, tmp)
        return duracion(ruta_salida)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--codigo', help='una sola secuencia por codigo (para pruebas rapidas)')
    ap.add_argument('--limite', type=int, help='procesa las primeras N secuencias de la tabla')
    ap.add_argument('--todas', action='store_true')
    ap.add_argument('--voz', default='male', choices=['female', 'male', 'male 2'])
    ap.add_argument('--musica', default='432hz_harmony', help='nombre del archivo en assets/audios (sin .mp3)')
    ap.add_argument('--sin-musica', action='store_true')
    ap.add_argument('--sin-outro', action='store_true')
    ap.add_argument('--subir', action='store_true', help='sube al bucket "roku" tras generar')
    args = ap.parse_args()

    musica = None
    if not args.sin_musica:
        musica = os.path.join(DIR_MUSICA, f'{args.musica}.mp3')
        if not os.path.isfile(musica):
            sys.exit(f'No existe la música: {musica}')

    os.makedirs(DIR_SALIDA, exist_ok=True)
    env = cargar_env()
    api_key = env.get('OPENAI_API_KEY')
    if not args.sin_outro and not api_key:
        sys.exit('Falta OPENAI_API_KEY (necesaria para el outro; usa --sin-outro para omitirlo, o proporciona la clave).')

    if args.codigo:
        secuencias = [s for s in obtener_secuencias(env, None) if s['codigo'] == args.codigo]
        if not secuencias:
            sys.exit(f'No encuentro la secuencia con codigo {args.codigo}')
    else:
        limite = None if args.todas else (args.limite or 10)
        secuencias = obtener_secuencias(env, limite)

    print(f'{len(secuencias)} secuencias a narrar con voz "{args.voz}".')
    vozSlug = VOCES_SLUG[args.voz]

    for i, sec in enumerate(secuencias, 1):
        print(f'[{i}/{len(secuencias)}] {sec["codigo"]} - {sec["nombre"]}')
        ruta_salida = os.path.join(DIR_SALIDA, f'{sec["codigo"]}_{vozSlug}.mp4')
        dur = generar_video_narrado(
            sec, args.voz, ruta_salida, api_key,
            incluir_outro=not args.sin_outro, musica=musica,
        )
        mb = os.path.getsize(ruta_salida) / 1024 / 1024
        print(f'  video -> {ruta_salida}  ({dur:.0f}s, {mb:.1f} MB)')

        if args.subir:
            url = subir_archivo(env, ruta_salida, f'videos_narrados/{vozSlug}/{sec["codigo"]}.mp4', 'video/mp4')
            print(f'  subida -> {url}')

    print('Listo.')


if __name__ == '__main__':
    main()
