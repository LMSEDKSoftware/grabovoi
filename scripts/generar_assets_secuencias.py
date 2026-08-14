#!/usr/bin/env python3
"""Genera portada (imagen) y video-loop por secuencia de codigos_grabovoi.

Pensado para probar con pocas secuencias antes de correrlo sobre toda la
tabla (ver --limite / --todas). No sube nada a Supabase: solo escribe
archivos locales en output/ para que se puedan revisar antes de publicar.

PORTADA (imagen, Pillow):
  Un master de 840x510 (3x del tamano de tarjeta 280x170 que ya usa
  SequenceCard.brs en Roku, mismo aspect ratio exacto). El fondo es UNA
  sola imagen compartida (assets/portadas/fondo_base.png, provista por el
  usuario) recortada a cover-fit, con un scrim negro al 30% encima para
  que el texto sea legible, y arriba: barra de acento del color de
  categoria, marca, categoria, el codigo grande y el nombre de la
  secuencia. Se puede reescalar hacia abajo para Roku, grid de la app,
  thumbnails, etc. sin recortes raros porque el aspect ratio coincide.
  El video-loop (mas abajo) sigue con su degradado animado por color de
  categoria -- no usa esta imagen, es solo para la portada estatica.

VIDEO LOOP (ffmpeg, sin material de stock):
  Un video por secuencia seria carisimo de generar y no aporta nada
  distinto por secuencia mas alla del color y el codigo. En vez de eso:
  1) Un fondo animado por COLOR DE CATEGORIA (no por secuencia) generado
     con el filtro `gradients` de ffmpeg -- no depende de ningun archivo
     de video externo, es 100% procedural. Se cachea en
     output/videos_loop/_base/<color>.mp4 y se reutiliza para todas las
     secuencias que compartan esa categoria/color.
  2) Un pase rapido de `drawtext` que superpone el codigo (con un fundito
     de entrada y un flote vertical suave) sobre esa base, por secuencia.
  El paso 2 es barato (segundos por secuencia); el paso 1 solo se paga
  una vez por color, no una vez por secuencia. Esto es lo que hace viable
  correrlo sobre cientos de secuencias.

Uso:
  python3 scripts/generar_assets_secuencias.py --limite 10
  python3 scripts/generar_assets_secuencias.py --limite 10 --solo-portadas
  python3 scripts/generar_assets_secuencias.py --limite 10 --solo-videos
  python3 scripts/generar_assets_secuencias.py --todas

Requiere SUPABASE_URL y SB_SERVICE_ROLE_KEY en .env (raiz del repo).
"""

import argparse
import json
import os
import re
import subprocess
import sys
import textwrap

from PIL import Image, ImageDraw, ImageFont

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_PORTADAS = os.path.join(RAIZ, 'output', 'portadas')
DIR_VIDEOS = os.path.join(RAIZ, 'output', 'videos_loop')
DIR_BASES = os.path.join(DIR_VIDEOS, '_base')
FUENTE = os.path.join(RAIZ, 'assets', 'fonts', 'noto', 'NotoSans-Regular.ttf')

ANCHO_IMG = 840
ALTO_IMG = 510
FONDO_BASE = os.path.join(RAIZ, 'assets', 'portadas', 'fondo_base.png')
OPACIDAD_SCRIM = 0.30


def cargar_fondo_base():
    # Una sola imagen compartida por TODAS las portadas (no una por
    # secuencia/categoria como el video-loop) -- la pidio el usuario
    # explicitamente para reemplazar el degradado generado por Pillow.
    base = Image.open(FONDO_BASE).convert('RGB')
    # Cover-fit: la imagen (1875x839, mas ancha que 840x510) se escala por
    # altura y se recorta el sobrante a los lados, para llenar el marco
    # sin deformarla ni dejar franjas vacias.
    escala = ALTO_IMG / base.height
    ancho_escalado = round(base.width * escala)
    base = base.resize((ancho_escalado, ALTO_IMG), Image.LANCZOS)
    recorte_x = (ancho_escalado - ANCHO_IMG) // 2
    return base.crop((recorte_x, 0, recorte_x + ANCHO_IMG, ALTO_IMG))

DURACION_LOOP_S = 6
RES_VIDEO = '840x510'


def cargar_env():
    env = {}
    ruta = os.path.join(RAIZ, '.env')
    if not os.path.isfile(ruta):
        sys.exit(f'No encuentro {ruta}')
    with open(ruta, encoding='utf-8') as f:
        for linea in f:
            linea = linea.strip()
            if not linea or linea.startswith('#') or '=' not in linea:
                continue
            k, v = linea.split('=', 1)
            env[k.strip()] = v.strip().strip('"').strip("'")
    for req in ('SUPABASE_URL', 'SB_SERVICE_ROLE_KEY'):
        if not env.get(req):
            sys.exit(f'Falta {req} en .env')
    return env


# El SSL de Python esta roto en esta maquina (CERTIFICATE_VERIFY_FAILED),
# asi que el HTTP va por curl, igual que en publicar_alexa_audio.py.
def curl(args):
    r = subprocess.run(['curl', '-s', '-S'] + args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'curl fallo: {r.stderr}')
    return r.stdout


def obtener_secuencias(env, limite):
    url = (
        f"{env['SUPABASE_URL']}/rest/v1/codigos_grabovoi"
        "?select=id,codigo,nombre,categoria,color,descripcion"
        "&order=categoria.asc,nombre.asc"
    )
    if limite:
        url += f'&limit={limite}'
    salida = curl([
        url,
        '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
        '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
    ])
    try:
        return json.loads(salida)
    except json.JSONDecodeError:
        sys.exit(f'Respuesta inesperada de Supabase: {salida[:300]}')


def hex_a_rgb(color_hex):
    color_hex = (color_hex or '#6C757D').lstrip('#')
    if len(color_hex) != 6:
        color_hex = '6C757D'
    return tuple(int(color_hex[i:i + 2], 16) for i in (0, 2, 4))


def codigo_visual(codigo):
    # Algunos codigos ya vienen con "_" como separador de grupos (igual
    # que en la respuesta de /roku-sequence); el resto se deja tal cual,
    # son secuencias de digitos de largo variable.
    return (codigo or '').replace('_', '  ')


def nombre_archivo(sec):
    base = re.sub(r'[^a-z0-9]+', '_', sec['nombre'].lower()).strip('_')
    return f"{sec['codigo']}_{base}"[:80]


def fuente(tam):
    return ImageFont.truetype(FUENTE, tam)


def tam_codigo_segun_largo(texto):
    # Codigos van de 3 a 15+ digitos; sin esto los largos se salen del
    # marco. Reduce el tamano de fuente segun cuantos caracteres hay.
    n = len(texto.replace(' ', ''))
    if n <= 4:
        return 92
    if n <= 7:
        return 76
    if n <= 10:
        return 60
    return 46


_fondo_base_cache = None


def generar_portada(sec, ruta_salida):
    global _fondo_base_cache
    if _fondo_base_cache is None:
        _fondo_base_cache = cargar_fondo_base()

    rgb_cat = hex_a_rgb(sec.get('color'))
    img = _fondo_base_cache.copy()

    # Scrim negro parejo para que el texto sea legible sobre la foto,
    # pedido explicitamente por el usuario (30% de opacidad).
    scrim = Image.new('RGB', (ANCHO_IMG, ALTO_IMG), (0, 0, 0))
    img = Image.blend(img, scrim, OPACIDAD_SCRIM)

    draw = ImageDraw.Draw(img)

    # Barra de acento del color de categoria, borde izquierdo.
    draw.rectangle([0, 0, 10, ALTO_IMG], fill=rgb_cat)

    # Marca, arriba a la izquierda.
    f_marca = fuente(22)
    draw.text((36, 28), 'MANIGRAB', font=f_marca, fill=(255, 215, 0, 180))

    # Categoria, como etiqueta pequena.
    f_cat = fuente(24)
    draw.text((36, 66), (sec.get('categoria') or '').upper(), font=f_cat, fill=rgb_cat)

    # Codigo, grande, con stroke para simular negrita (no hay variante
    # bold de Noto Sans empaquetada en assets/fonts).
    texto_codigo = codigo_visual(sec['codigo'])
    f_codigo = fuente(tam_codigo_segun_largo(texto_codigo))
    draw.text(
        (36, 190), texto_codigo, font=f_codigo, fill=(255, 255, 255),
        stroke_width=2, stroke_fill=(255, 255, 255),
    )

    # Nombre de la secuencia, envuelto a 2 lineas si hace falta.
    f_nombre = fuente(32)
    lineas = textwrap.wrap(sec['nombre'], width=28)[:2]
    y = ALTO_IMG - 40 - 40 * len(lineas)
    for linea in lineas:
        draw.text((36, y), linea, font=f_nombre, fill=(230, 230, 230))
        y += 40

    img.save(ruta_salida, quality=92)


def generar_base_loop(color_hex, ruta_salida):
    if os.path.isfile(ruta_salida):
        return
    rgb = hex_a_rgb(color_hex)
    hex_limpio = ('%02x%02x%02x' % rgb)
    # `gradients` de ffmpeg dibuja un degradado animado entre paletas de
    # color, 100% procedural (sin material de stock ni licencias). Se
    # anima solo con rotacion/velocidad lenta para que se sienta como un
    # fondo ambiental, no una animacion llamativa.
    filtro = (
        f"gradients=size={RES_VIDEO}:duration={DURACION_LOOP_S}:speed=0.02:"
        f"c0=0x0B132B:c1=0x{hex_limpio}:x0=100:y0=100:x1=740:y1=410,"
        "format=yuv420p"
    )
    cmd = [
        'ffmpeg', '-y', '-v', 'error',
        '-f', 'lavfi', '-i', filtro,
        '-t', str(DURACION_LOOP_S),
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-an',
        ruta_salida,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'ffmpeg (base loop) fallo para {color_hex}: {r.stderr}')


def generar_png_overlay(sec, ruta_png):
    # El ffmpeg de esta maquina no trae libfreetype (sin filtro drawtext),
    # asi que el texto se renderiza con Pillow -- mismo control de fuente
    # que la portada -- y ffmpeg solo compone la imagen (RGBA, fondo
    # transparente) sobre el loop animado con el filtro `overlay`.
    texto_codigo = codigo_visual(sec['codigo'])
    tam = tam_codigo_segun_largo(texto_codigo)

    img = Image.new('RGBA', (ANCHO_IMG, ALTO_IMG), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    f_codigo = fuente(tam)
    bbox = draw.textbbox((0, 0), texto_codigo, font=f_codigo, stroke_width=2)
    x = (ANCHO_IMG - (bbox[2] - bbox[0])) // 2
    y = int(ALTO_IMG * 0.42)
    draw.text(
        (x, y), texto_codigo, font=f_codigo, fill=(255, 255, 255, 255),
        stroke_width=3, stroke_fill=(0, 0, 0, 160),
    )

    f_nombre = fuente(30)
    bbox_n = draw.textbbox((0, 0), sec['nombre'], font=f_nombre, stroke_width=2)
    xn = (ANCHO_IMG - (bbox_n[2] - bbox_n[0])) // 2
    yn = y + (bbox[3] - bbox[1]) + 24
    draw.text(
        (xn, yn), sec['nombre'], font=f_nombre, fill=(255, 215, 0, 255),
        stroke_width=2, stroke_fill=(0, 0, 0, 160),
    )

    img.save(ruta_png)


def generar_video_secuencia(sec, ruta_base, ruta_salida):
    ruta_png = ruta_salida + '.overlay.png'
    generar_png_overlay(sec, ruta_png)

    cmd = [
        'ffmpeg', '-y', '-v', 'error',
        '-i', ruta_base,
        '-loop', '1', '-i', ruta_png,
        '-filter_complex', '[0:v][1:v]overlay=0:0:format=auto',
        '-t', str(DURACION_LOOP_S),
        # crf alto + preset lento = mismo aspecto visual con bastante
        # menos peso; son loops de fondo, no necesitan calidad maxima.
        '-c:v', 'libx264', '-preset', 'slow', '-crf', '30',
        '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an',
        ruta_salida,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    os.remove(ruta_png)
    if r.returncode != 0:
        sys.exit(f'ffmpeg (overlay) fallo para {sec["codigo"]}: {r.stderr}')


BUCKET = 'roku'


def subir_archivo(env, ruta_local, ruta_bucket, content_type):
    url = f"{env['SUPABASE_URL']}/storage/v1/object/{BUCKET}/{ruta_bucket}"
    r = subprocess.run(
        [
            'curl', '-s', '-S', '-X', 'POST', url,
            '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
            '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
            '-H', f'Content-Type: {content_type}',
            '-H', 'x-upsert: true',
            '--data-binary', f'@{ruta_local}',
        ],
        capture_output=True, text=True,
    )
    if r.returncode != 0 or '"error"' in r.stdout.lower():
        sys.exit(f'Subida fallo para {ruta_bucket}: {r.stdout} {r.stderr}')
    return f"{env['SUPABASE_URL']}/storage/v1/object/public/{BUCKET}/{ruta_bucket}"


def actualizar_urls(env, sec_id, imagen_url, video_url):
    url = f"{env['SUPABASE_URL']}/rest/v1/codigos_grabovoi?id=eq.{sec_id}"
    payload = {}
    if imagen_url:
        payload['imagen_url'] = imagen_url
    if video_url:
        payload['video_loop_url'] = video_url
    r = subprocess.run(
        [
            'curl', '-s', '-S', '-X', 'PATCH', url,
            '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
            '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
            '-H', 'Content-Type: application/json',
            '-H', 'Prefer: return=minimal',
            '-d', json.dumps(payload),
        ],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        sys.exit(f'PATCH fallo para {sec_id}: {r.stderr}')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--limite', type=int, default=10, help='cuantas secuencias procesar (default 10, prueba)')
    ap.add_argument('--todas', action='store_true', help='ignora --limite, procesa toda la tabla')
    ap.add_argument('--solo-portadas', action='store_true')
    ap.add_argument('--solo-videos', action='store_true')
    ap.add_argument('--subir', action='store_true', help='sube portada+video al bucket "roku" y actualiza imagen_url/video_loop_url')
    ap.add_argument('--base-personalizada', metavar='RUTA', help='usa este video (sin texto) como fondo en vez del degradado generado; el codigo/nombre se sigue componiendo encima igual')
    args = ap.parse_args()

    os.makedirs(DIR_PORTADAS, exist_ok=True)
    os.makedirs(DIR_VIDEOS, exist_ok=True)
    os.makedirs(DIR_BASES, exist_ok=True)

    if args.base_personalizada and not os.path.isfile(args.base_personalizada):
        sys.exit(f'No encuentro {args.base_personalizada}')

    env = cargar_env()
    limite = None if args.todas else args.limite
    secuencias = obtener_secuencias(env, limite)
    print(f'{len(secuencias)} secuencias obtenidas de Supabase.')

    hacer_portadas = not args.solo_videos
    hacer_videos = not args.solo_portadas

    for i, sec in enumerate(secuencias, 1):
        base = nombre_archivo(sec)
        print(f'[{i}/{len(secuencias)}] {sec["codigo"]} - {sec["nombre"]}')
        imagen_url = None
        video_url = None

        if hacer_portadas:
            ruta_img = os.path.join(DIR_PORTADAS, base + '.jpg')
            generar_portada(sec, ruta_img)
            print(f'  portada -> {ruta_img}')
            if args.subir:
                imagen_url = subir_archivo(env, ruta_img, f'portadas/{sec["codigo"]}.jpg', 'image/jpeg')
                print(f'  subida  -> {imagen_url}')

        if hacer_videos:
            if args.base_personalizada:
                ruta_base = args.base_personalizada
            else:
                color_hex = (sec.get('color') or '#6C757D').lstrip('#')
                ruta_base = os.path.join(DIR_BASES, f'{color_hex}.mp4')
                generar_base_loop(sec.get('color'), ruta_base)
            ruta_video = os.path.join(DIR_VIDEOS, base + '.mp4')
            generar_video_secuencia(sec, ruta_base, ruta_video)
            print(f'  video   -> {ruta_video}')
            if args.subir:
                video_url = subir_archivo(env, ruta_video, f'videos_loop/{sec["codigo"]}.mp4', 'video/mp4')
                print(f'  subida  -> {video_url}')

        if args.subir and (imagen_url or video_url):
            actualizar_urls(env, sec['id'], imagen_url, video_url)

    print('Listo.')


if __name__ == '__main__':
    main()
