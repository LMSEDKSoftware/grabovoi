#!/usr/bin/env python3
"""Genera la cortinilla de apertura del canal Roku (roku-tv/video/intro.mp4):
fondo de esfera (el mismo de las portadas) con zoom lento, el logo con
fundido de entrada/salida encima, y el audio de roku-tv/audio/intro.mp3
mezclado -- la duracion del video sigue exactamente la del audio.

Uso:
  python3 scripts/generar_intro.py

Requiere ffmpeg y Pillow. No sube nada a ningun lado, solo escribe
roku-tv/video/intro.mp4 (mas los PNG intermedios en output/, que no se
suben con el canal).
"""

import os
import subprocess
import sys

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONDO_PATH = os.path.join(RAIZ, 'assets', 'portadas', 'fondo_base.png')
LOGO_PATH = os.path.join(RAIZ, 'roku-tv', 'images', 'manigrab_logo.png')
AUDIO_PATH = os.path.join(RAIZ, 'roku-tv', 'audio', 'intro.mp3')
SALIDA = os.path.join(RAIZ, 'roku-tv', 'video', 'intro.mp4')

DIR_TMP = os.path.join(RAIZ, 'output', 'intro_tmp')
FONDO_TMP = os.path.join(DIR_TMP, 'fondo.png')
LOGO_TMP = os.path.join(DIR_TMP, 'logo_overlay.png')

W, H = 1280, 720
ANCHO_LOGO = 420
FPS = 30


def duracion_audio():
    salida = subprocess.run(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'default=noprint_wrappers=1:nokey=1', AUDIO_PATH],
        capture_output=True, text=True,
    )
    if salida.returncode != 0:
        sys.exit(f'ffprobe fallo leyendo {AUDIO_PATH}: {salida.stderr}')
    return float(salida.stdout.strip())


def generar_fondo():
    fondo = Image.open(FONDO_PATH).convert('RGB')
    escala = H / fondo.height
    ancho_escalado = round(fondo.width * escala)
    base = fondo.resize((ancho_escalado, H), Image.LANCZOS)
    recorte_x = (ancho_escalado - W) // 2
    base = base.crop((recorte_x, 0, recorte_x + W, H))

    scrim = Image.new('RGB', (W, H), (0, 0, 0))
    img = Image.blend(base, scrim, 0.35)
    img.save(FONDO_TMP)


def generar_logo_overlay():
    logo = Image.open(LOGO_PATH).convert('RGBA')
    escala = ANCHO_LOGO / logo.width
    logo = logo.resize((ANCHO_LOGO, round(logo.height * escala)), Image.LANCZOS)

    canvas = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    x = (W - logo.width) // 2
    y = (H - logo.height) // 2
    canvas.paste(logo, (x, y), logo)
    canvas.save(LOGO_TMP)


def generar_video(duracion):
    # Logo entra a los 1.0s (dura 1.2s el fundido), se queda, y sale 1.2s
    # antes del final; toda la imagen hace un fundido a negro en el
    # ultimo medio segundo para que no corte seco.
    entrada = 1.0
    salida_logo = max(entrada + 1.2, duracion - 1.6)
    fundido_final = max(0.0, duracion - 0.6)

    filtro = (
        f"[0:v]scale={W}:{H},"
        f"zoompan=z='min(zoom+0.0006,1.08)':d=1:"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={FPS}[bg];"
        f"[1:v]fade=t=in:st={entrada}:d=1.2:alpha=1,"
        f"fade=t=out:st={salida_logo}:d=1.2:alpha=1[logo];"
        f"[bg][logo]overlay=0:0:format=auto,"
        f"fade=t=out:st={fundido_final}:d=0.6[v]"
    )

    cmd = [
        'ffmpeg', '-y', '-v', 'error',
        '-loop', '1', '-i', FONDO_TMP,
        '-loop', '1', '-i', LOGO_TMP,
        '-i', AUDIO_PATH,
        '-filter_complex', filtro,
        '-map', '[v]', '-map', '2:a',
        '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '22', '-pix_fmt', 'yuv420p',
        '-c:a', 'aac', '-b:a', '128k',
        '-t', str(duracion), '-movflags', '+faststart',
        SALIDA,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'ffmpeg fallo: {r.stderr}')


def main():
    if not os.path.isfile(AUDIO_PATH):
        sys.exit(f'Falta {AUDIO_PATH}')
    os.makedirs(DIR_TMP, exist_ok=True)
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)

    duracion = duracion_audio()
    print(f'Audio: {duracion:.2f}s')

    generar_fondo()
    generar_logo_overlay()
    generar_video(duracion)

    print(f'Listo -> {SALIDA}')


if __name__ == '__main__':
    main()
