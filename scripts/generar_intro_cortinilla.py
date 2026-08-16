#!/usr/bin/env python3
"""Genera UNA VEZ la cortinilla de intro (misma esfera de fondo + voz de
instrucciones + captions sincronizados), que despues se antepone a CADA
video de secuencia por copia de stream (sin recodificar), en vez de
volver a renderizarla en cada una de las ~1000 secuencias.

Por que existe: generar_video_narrado.py mezclaba el intro (fijo, igual
en todo el catalogo) DENTRO de cada video -- eso significaba pagar el
costo de renderizado (voz + filtros + encode) de esos ~30s una y otra
vez, cientos de veces, para un contenido que nunca cambia. Separandolo:
esta cortinilla se renderiza una sola vez y sincronizar_videos_narrados.py
la concatena (ffmpeg -c copy, practicamente gratis) al final de cada
video de secuencia.

Cortinilla visual: la esfera de fondo sigue en movimiento (no es una
imagen estatica), con una "cortina" negra al 40% de opacidad encima (para
que el texto se lea claro) y el logo de ManiGraB arriba. El texto de las
instrucciones va apareciendo frase por frase, sincronizado con la voz --
cada frase es un clip de TTS aparte (no un solo audio largo) para saber
el instante exacto en que empieza y termina cada una, sin adivinar.

Uso:
  python3 scripts/generar_intro_cortinilla.py
  python3 scripts/generar_intro_cortinilla.py --forzar   # regenera aunque ya exista

Pide OPENAI_API_KEY si hace falta (.env, variable de entorno, o por consola). Salida: output/intro_cortinilla/intro_cortinilla.mp4
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_assets_secuencias import RAIZ, cargar_env  # noqa: E402
from generar_video_narrado import (  # noqa: E402
    ALTO_VIDEO, ANCHO_VIDEO, DIR_CACHE_TTS, ESFERA_VIDEO_BASE, SISTEMA, SR,
    TTS_INSTRUCCIONES, TTS_VOZ, _ruta_fuente, concat, construir_cadena_overlays,
    duracion, obtener_encoder_video, sh, silencio, tts_a_wav,
)

CORTINILLA_DIR = os.path.join(RAIZ, 'output', 'intro_cortinilla')
CORTINILLA_MP4 = os.path.join(CORTINILLA_DIR, 'intro_cortinilla.mp4')
LOGO_PATH = os.path.join(RAIZ, 'roku-tv', 'images', 'manigrab_logo.png')

FRASES = [
    'Bienvenido a tu pilotaje con ManiGrab.',
    'Busca un lugar tranquilo, respira profundo y relaja tu cuerpo.',
    'Visualiza tu intención con claridad, como si ya se hubiera cumplido, '
    'y sostén esa sensación mientras escuchas la secuencia repetirse.',
    'No necesitas memorizar los números, solo mantente receptivo y en calma.',
    'Cuando estés listo, comenzamos.',
]

PAUSA_INICIAL_MS = 1200  # ver PAUSA_INICIAL_MS en generar_video_narrado.py
PAUSA_ENTRE_FRASES_MS = 500
PAUSA_FINAL_MS = 900  # respiro antes de que arranquen los numeros (parte 2)

SCRIM_ALPHA = 102  # negro al 40% (255*0.4)
LOGO_ANCHO = 280
LOGO_Y = 50

if SISTEMA == 'Windows':
    FONT_CAPTION_PATH = _ruta_fuente([r'C:\Windows\Fonts\arialbd.ttf'], 'los captions (Arial Bold)')
elif SISTEMA == 'Darwin':
    FONT_CAPTION_PATH = _ruta_fuente(
        ['/System/Library/Fonts/Supplemental/Arial Bold.ttf'], 'los captions (Arial Bold)'
    )
else:
    FONT_CAPTION_PATH = _ruta_fuente([
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
        '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
    ], 'los captions (Arial Bold)')
TAM_FUENTE_CAPTION = 46
MAX_ANCHO_CAPTION = 1000
MARGEN_INFERIOR_CAPTION = 90
COLOR_CAPTION_RGBA = (255, 255, 255, 255)
COLOR_BORDE_CAPTION_RGBA = (0, 0, 0, 255)


def generar_frase_tts(texto, indice, api_key):
    os.makedirs(DIR_CACHE_TTS, exist_ok=True)
    destino = os.path.join(DIR_CACHE_TTS, f'intro_frase_{indice}.mp3')
    if os.path.isfile(destino) and os.path.getsize(destino) > 1000:
        return destino
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
        sys.exit(f'Fallo generando frase {indice} del intro: {r.stderr}')
    return destino


def construir_audio_cortinilla(tmp, api_key):
    """Cada frase es un clip de TTS aparte -- asi se sabe el instante
    exacto en que empieza/termina cada una (para el caption), en vez de
    adivinar cortes dentro de un audio largo continuo."""
    piezas = []
    tiempo = 0.0
    eventos_por_frase = []

    def agregar(path, dur):
        nonlocal tiempo
        piezas.append(path)
        inicio = tiempo
        tiempo += dur
        return inicio, tiempo

    sil_inicial = os.path.join(tmp, 'sil_inicial.wav')
    silencio(PAUSA_INICIAL_MS, sil_inicial)
    agregar(sil_inicial, PAUSA_INICIAL_MS / 1000.0)

    for i, frase in enumerate(FRASES):
        mp3 = generar_frase_tts(frase, i, api_key)
        wav = os.path.join(tmp, f'frase_{i}.wav')
        tts_a_wav(mp3, wav)
        dur = duracion(wav)
        inicio, fin = agregar(wav, dur)
        eventos_por_frase.append((inicio, fin))
        if i < len(FRASES) - 1:
            sil = os.path.join(tmp, f'sil_frase_{i}.wav')
            silencio(PAUSA_ENTRE_FRASES_MS, sil)
            agregar(sil, PAUSA_ENTRE_FRASES_MS / 1000.0)

    sil_final = os.path.join(tmp, 'sil_final.wav')
    silencio(PAUSA_FINAL_MS, sil_final)
    agregar(sil_final, PAUSA_FINAL_MS / 1000.0)

    completa = os.path.join(tmp, 'audio_cortinilla.wav')
    concat(piezas, completa, tmp)
    return completa, eventos_por_frase


def envolver_texto(texto, font, max_ancho, draw):
    palabras = texto.split()
    lineas = []
    actual = ''
    for palabra in palabras:
        candidata = (actual + ' ' + palabra).strip()
        if draw.textlength(candidata, font=font) <= max_ancho:
            actual = candidata
        else:
            if actual:
                lineas.append(actual)
            actual = palabra
    if actual:
        lineas.append(actual)
    return lineas


def generar_overlays_cortinilla(eventos_por_frase, tmp):
    """Base (scrim + logo, siempre visible) + un PNG por frase (solo
    texto, transparente en todo lo demas) visible unicamente durante su
    ventana -- mismo patron que los digitos horneados."""
    base = Image.new('RGBA', (ANCHO_VIDEO, ALTO_VIDEO), (0, 0, 0, 0))
    draw = ImageDraw.Draw(base)
    draw.rectangle([0, 0, ANCHO_VIDEO, ALTO_VIDEO], fill=(0, 0, 0, SCRIM_ALPHA))

    if os.path.isfile(LOGO_PATH):
        logo = Image.open(LOGO_PATH).convert('RGBA')
        escala = LOGO_ANCHO / logo.width
        logo = logo.resize((LOGO_ANCHO, round(logo.height * escala)))
        x_logo = (ANCHO_VIDEO - logo.width) // 2
        base.alpha_composite(logo, (x_logo, LOGO_Y))

    base_path = os.path.join(tmp, 'cortinilla_base.png')
    base.save(base_path)

    font = ImageFont.truetype(FONT_CAPTION_PATH, TAM_FUENTE_CAPTION)
    alto_linea = TAM_FUENTE_CAPTION + 14

    capas = [(base_path, None)]
    for i, frase in enumerate(FRASES):
        img = Image.new('RGBA', (ANCHO_VIDEO, ALTO_VIDEO), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        lineas = envolver_texto(frase, font, MAX_ANCHO_CAPTION, d)
        alto_bloque = len(lineas) * alto_linea
        y = ALTO_VIDEO - MARGEN_INFERIOR_CAPTION - alto_bloque
        for linea in lineas:
            ancho_linea = d.textlength(linea, font=font)
            x = (ANCHO_VIDEO - ancho_linea) / 2
            d.text(
                (x, y), linea, font=font, fill=COLOR_CAPTION_RGBA,
                stroke_width=2, stroke_fill=COLOR_BORDE_CAPTION_RGBA,
            )
            y += alto_linea
        ruta = os.path.join(tmp, f'cortinilla_frase_{i}.png')
        img.save(ruta)
        capas.append((ruta, [eventos_por_frase[i]]))
    return capas


def generar_cortinilla(api_key):
    if not os.path.isfile(ESFERA_VIDEO_BASE):
        sys.exit(f'No encuentro {ESFERA_VIDEO_BASE}')

    os.makedirs(CORTINILLA_DIR, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix='cortinilla_')
    try:
        audio_wav, eventos_por_frase = construir_audio_cortinilla(tmp, api_key)
        dur = duracion(audio_wav)

        capas = generar_overlays_cortinilla(eventos_por_frase, tmp)
        entradas_overlay, filtro_overlay, etiqueta_final = construir_cadena_overlays(capas, 2)

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
            CORTINILLA_MP4,
        ]
        sh(cmd)
        return dur
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--forzar', action='store_true', help='regenerar aunque ya exista')
    args = ap.parse_args()

    if os.path.isfile(CORTINILLA_MP4) and not args.forzar:
        print(f'Ya existe {CORTINILLA_MP4} (usa --forzar para regenerar).')
        return

    env = cargar_env()
    api_key = env.get('OPENAI_API_KEY')
    if not api_key:
        sys.exit('Falta OPENAI_API_KEY (no se proporciono).')

    print('Generando cortinilla de intro...')
    dur = generar_cortinilla(api_key)
    mb = os.path.getsize(CORTINILLA_MP4) / 1024 / 1024
    print(f'Listo -> {CORTINILLA_MP4} ({dur:.1f}s, {mb:.1f} MB)')


if __name__ == '__main__':
    main()
