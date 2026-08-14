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

El codigo NO va horneado en el video -- ese texto lo dibuja Roku encima
(PlayerScreen.xml/.brs, campo codigoLabel), no este script. Es un video
exclusivo para el canal de Roku (no se reutiliza en la app movil), asi que
no hace falta que el texto quede incrustado en los pixeles: dibujarlo del
lado de Roku es mas simple, mas nitido, y garantiza que el codigo se vea
siempre del mismo tamaño/posicion sin importar como haya quedado el
render. Este script solo genera loop visual + voz mezclada.

Duracion: maximo 180s (pedido explicito). Roku en general es formato largo
sin limite (ver PlayerScreen.brs), pero ESTE video puntual se recorta --
si las 10 repeticiones no caben en 180s se reducen (igual que
render_alexa_audio.py, con un piso de 3 repeticiones).

Reutiliza el mismo patron de mezcla de voz (concat de clips + silencios)
que render_alexa_audio.py, sin la mezcla de musica de fondo (se puede
agregar despues si se quiere).

Uso:
  python3 scripts/generar_video_narrado.py --codigo 919_819_714 --voz male
  python3 scripts/generar_video_narrado.py --codigo 919_819_714 --voz male --subir
  python3 scripts/generar_video_narrado.py --limite 10 --voz male --subir

Requiere SUPABASE_URL y SB_SERVICE_ROLE_KEY en .env (raiz del repo).
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_assets_secuencias import (  # noqa: E402
    RAIZ, cargar_env, obtener_secuencias, subir_archivo,
)

DIR_VOCES = os.path.join(RAIZ, 'assets', 'audios', 'voice_numbers')
DIR_SALIDA = os.path.join(RAIZ, 'output', 'videos_narrados')
ESFERA_VIDEO_BASE = os.path.join(RAIZ, 'assets', 'portadas', 'esfera_video_base.mp4')

GAP_DIGITOS_MS = 280
SILENCIO_ESPACIO_MS = 100
PAUSA_NUEVAMENTE_MS = 1800
REPETICIONES = 10
MIN_REPETICIONES = 3
MAX_DURACION_S = 180
SR = 24000

VOCES_SLUG = {'female': 'female', 'male': 'male', 'male 2': 'male2'}


def sh(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'ffmpeg fallo:\n{" ".join(args)}\n{r.stderr[-2000:]}')
    return r


def duracion(path):
    r = sh(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path])
    return float(r.stdout.strip())


def a_wav(origen, destino):
    sh(['ffmpeg', '-y', '-v', 'error', '-i', origen, '-ac', '1', '-ar', str(SR), destino])


def silencio(ms, destino):
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'lavfi',
        '-i', f'anullsrc=r={SR}:cl=mono', '-t', f'{ms / 1000:.3f}', destino])


def concat(piezas, destino, tmp):
    lista = os.path.join(tmp, f'lista_{os.path.basename(destino)}.txt')
    with open(lista, 'w') as f:
        for p in piezas:
            f.write(f"file '{p}'\n")
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', lista, '-c', 'copy', destino])


def construir_audio(codigo, voz, tmp):
    dir_voz = os.path.join(DIR_VOCES, voz)
    if not os.path.isdir(dir_voz):
        sys.exit(f'No existe la carpeta de voz: {dir_voz}')

    tokens = [c for c in codigo if c.isdigit() or c == '_']
    if not any(c.isdigit() for c in tokens):
        sys.exit(f'El codigo no tiene digitos: {codigo}')

    clips = {}
    for nombre in set(t if t != '_' else 'espacio' for t in tokens) | {'nuevamente'}:
        origen = os.path.join(dir_voz, f'{nombre}.mp3')
        if not os.path.isfile(origen):
            sys.exit(f'Falta el clip de voz: {origen}')
        destino = os.path.join(tmp, f'clip_{nombre}.wav')
        a_wav(origen, destino)
        clips[nombre] = destino

    sil_gap = os.path.join(tmp, 'sil_gap.wav')
    sil_esp = os.path.join(tmp, 'sil_esp.wav')
    sil_nue = os.path.join(tmp, 'sil_nue.wav')
    silencio(GAP_DIGITOS_MS, sil_gap)
    silencio(SILENCIO_ESPACIO_MS, sil_esp)
    silencio(PAUSA_NUEVAMENTE_MS, sil_nue)

    piezas = []
    for t in tokens:
        if t == '_':
            piezas += [sil_esp, clips['espacio'], sil_esp]
        else:
            piezas += [clips[t], sil_gap]
    rep = os.path.join(tmp, 'rep.wav')
    concat(piezas, rep, tmp)

    enlace = os.path.join(tmp, 'enlace.wav')
    concat([sil_nue, clips['nuevamente'], sil_nue], enlace, tmp)

    # Tope de 180s: si las 10 repeticiones no caben, se reducen (piso de
    # 3) -- mismo calculo que render_alexa_audio.py.
    d_rep, d_enlace = duracion(rep), duracion(enlace)
    cabe = int((MAX_DURACION_S + d_enlace) // (d_rep + d_enlace))
    reps = max(MIN_REPETICIONES, min(REPETICIONES, cabe))
    if reps < REPETICIONES:
        print(f'aviso: {codigo} es largo ({d_rep:.0f}s por repeticion); se usan {reps} repeticiones en vez de {REPETICIONES} para caber en {MAX_DURACION_S}s.', file=sys.stderr)

    completa = os.path.join(tmp, 'voz.wav')
    concat([rep] + [enlace, rep] * (reps - 1), completa, tmp)
    return completa


def generar_video_narrado(sec, voz, ruta_salida):
    if not os.path.isfile(ESFERA_VIDEO_BASE):
        sys.exit(f'No encuentro {ESFERA_VIDEO_BASE}')

    tmp = tempfile.mkdtemp(prefix='roku_video_narrado_')
    try:
        audio_wav = construir_audio(sec['codigo'], voz, tmp)
        dur = duracion(audio_wav)

        cmd = [
            'ffmpeg', '-y', '-v', 'error',
            '-stream_loop', '-1', '-i', ESFERA_VIDEO_BASE,
            '-i', audio_wav,
            '-map', '0:v', '-map', '1:a',
            '-t', f'{dur:.3f}',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '26', '-pix_fmt', 'yuv420p',
            '-c:a', 'aac', '-b:a', '96k',
            '-movflags', '+faststart',
            ruta_salida,
        ]
        sh(cmd)
        return dur
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--codigo', help='una sola secuencia por codigo (para pruebas rapidas)')
    ap.add_argument('--limite', type=int, help='procesa las primeras N secuencias de la tabla')
    ap.add_argument('--todas', action='store_true')
    ap.add_argument('--voz', default='male', choices=['female', 'male', 'male 2'])
    ap.add_argument('--subir', action='store_true', help='sube al bucket "roku" tras generar')
    args = ap.parse_args()

    os.makedirs(DIR_SALIDA, exist_ok=True)
    env = cargar_env()

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
        dur = generar_video_narrado(sec, args.voz, ruta_salida)
        mb = os.path.getsize(ruta_salida) / 1024 / 1024
        print(f'  video -> {ruta_salida}  ({dur:.0f}s, {mb:.1f} MB)')

        if args.subir:
            url = subir_archivo(env, ruta_salida, f'videos_narrados/{vozSlug}/{sec["codigo"]}.mp4', 'video/mp4')
            print(f'  subida -> {url}')

    print('Listo.')


if __name__ == '__main__':
    main()
