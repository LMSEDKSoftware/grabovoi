#!/usr/bin/env python3
"""Genera y sube una imagen por categoria (no por secuencia) para
CategoryScreen.brs en Roku: mismo diseño de portada (fondo esfera + barra
del color de la categoria + logo, sin texto horneado -- SequenceCard.brs
ya dibuja el nombre encima), pero una sola por categoria en vez de una por
secuencia. Sube a bucket "roku"/categorias/<slug>.jpg y guarda la URL en
la tabla categoria_imagenes (ver
supabase/migrations/20260815130100_categoria_imagenes.sql), que
roku_categorias_resumen() ya lee via LEFT JOIN.

Uso:
  python3 scripts/generar_imagenes_categorias.py            # solo genera local
  python3 scripts/generar_imagenes_categorias.py --subir    # genera y sube + actualiza DB

Requiere SUPABASE_URL y SB_SERVICE_ROLE_KEY en .env (raiz del repo).
"""

import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_assets_secuencias import (  # noqa: E402
    cargar_env, curl, generar_portada, subir_archivo, DIR_PORTADAS,
)

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_CATEGORIAS = os.path.join(DIR_PORTADAS, 'categorias')


def obtener_categorias(env):
    url = (
        f"{env['SUPABASE_URL']}/rest/v1/rpc/roku_categorias_resumen"
    )
    salida = curl([
        '-X', 'POST', url,
        '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
        '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
        '-H', 'Content-Type: application/json',
        '-d', '{}',
    ])
    try:
        filas = json.loads(salida)
    except json.JSONDecodeError:
        sys.exit(f'Respuesta inesperada de Supabase: {salida[:300]}')
    return [f for f in filas if f.get('categoria') and f.get('color')]


def slug(categoria):
    s = re.sub(r'[^a-z0-9]+', '_', categoria.lower()).strip('_')
    return s


def upsert_categoria_imagen(env, categoria, imagen_url):
    url = f"{env['SUPABASE_URL']}/rest/v1/categoria_imagenes"
    r = subprocess.run(
        [
            'curl', '-s', '-S', '-X', 'POST', url,
            '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
            '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
            '-H', 'Content-Type: application/json',
            '-H', 'Prefer: resolution=merge-duplicates,return=minimal',
            '-d', json.dumps({'categoria': categoria, 'imagen_url': imagen_url}),
        ],
        capture_output=True, text=True,
    )
    if r.returncode != 0 or '"error"' in r.stdout.lower() or '"message"' in r.stdout.lower():
        sys.exit(f'upsert categoria_imagenes fallo para {categoria}: {r.stdout} {r.stderr}')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--subir', action='store_true', help='sube al bucket "roku" y actualiza categoria_imagenes')
    args = ap.parse_args()

    os.makedirs(DIR_CATEGORIAS, exist_ok=True)
    env = cargar_env()
    categorias = obtener_categorias(env)
    print(f'{len(categorias)} categorias obtenidas de Supabase.')

    for i, cat in enumerate(categorias, 1):
        nombre = cat['categoria']
        color = cat['color']
        s = slug(nombre)
        ruta_img = os.path.join(DIR_CATEGORIAS, f'{s}.jpg')
        print(f'[{i}/{len(categorias)}] {nombre} ({color})')
        generar_portada({'color': color}, ruta_img, incluir_logo=False)
        print(f'  imagen -> {ruta_img}')

        if args.subir:
            imagen_url = subir_archivo(env, ruta_img, f'categorias/{s}.jpg', 'image/jpeg')
            print(f'  subida -> {imagen_url}')
            upsert_categoria_imagen(env, nombre, imagen_url)
            print('  DB actualizada')

    print('Listo.')


if __name__ == '__main__':
    main()
