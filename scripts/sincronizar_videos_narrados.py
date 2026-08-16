#!/usr/bin/env python3
"""Sincroniza videos narrados: elige N secuencias al azar de la DB que
TODAVIA NO tengan video subido y las va generando una por una con
generar_video_narrado.generar_video_narrado() -- mismo pipeline ya
aprobado (voz female, musica 432hz_harmony, digitos horneados con
encendido, intro fijo + outro personalizado por secuencia).

Por que "sincronizar" y no solo "generar N": antes de sortear, lista lo
que YA existe en el bucket (videos_narrados/female/) y lo excluye del
sorteo. Asi cada corrida avanza la cobertura de la biblioteca hacia
adelante sin volver a gastar render+TTS en secuencias ya hechas -- correr
este script varias veces (hoy, mañana, la próxima semana) eventualmente
cubre las 1191 secuencias sin coordinacion manual de "cuales ya hice".

Espacio en disco: cada video se sube y se borra del disco local de
inmediato (--conservar-local para desactivar esto si se quiere revisar
localmente). Sin eso, el disco solo tiene UN video a la vez (~15-20 MB)
mas la cache de outros TTS (mp3 chicos, unos pocos MB por cientos de
secuencias).

Uso:
  python3 scripts/sincronizar_videos_narrados.py
  python3 scripts/sincronizar_videos_narrados.py --cantidad 20
  python3 scripts/sincronizar_videos_narrados.py --cantidad 5 --conservar-local

Si no se pasa --cantidad, lo pregunta por consola.

Pide SUPABASE_URL, SB_SERVICE_ROLE_KEY y OPENAI_API_KEY si hace falta
(.env, variable de entorno, o por consola; nada se escribe a disco).
"""

import argparse
import json
import os
import random
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_assets_secuencias import BUCKET, cargar_env, obtener_secuencias  # noqa: E402
from generar_video_narrado import (  # noqa: E402
    DIR_MUSICA, DIR_SALIDA, VOCES_SLUG, generar_video_narrado,
)
from generar_assets_secuencias import subir_archivo  # noqa: E402

VOZ = 'female'
MUSICA_ARCHIVO = '432hz_harmony'


def listar_ya_generados(env, voz_slug):
    """Todos los codigos que ya tienen mp4 en videos_narrados/{voz}/ --
    pagina de a 1000 porque el listado de Supabase Storage no devuelve
    todo de una."""
    encontrados = set()
    offset = 0
    tam_pagina = 1000
    while True:
        cuerpo = json.dumps({'prefix': f'videos_narrados/{voz_slug}/', 'limit': tam_pagina, 'offset': offset})
        r = subprocess.run(
            ['curl', '-s', '-S', f"{env['SUPABASE_URL']}/storage/v1/object/list/{BUCKET}",
             '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
             '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
             '-H', 'Content-Type: application/json',
             '-d', cuerpo],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            sys.exit(f'Fallo listando videos existentes: {r.stderr}')
        try:
            pagina = json.loads(r.stdout)
        except json.JSONDecodeError:
            sys.exit(f'Respuesta inesperada listando videos existentes: {r.stdout[:500]}')
        if not isinstance(pagina, list):
            sys.exit(f'Respuesta inesperada listando videos existentes: {r.stdout[:500]}')
        for item in pagina:
            nombre = item.get('name', '')
            if nombre.endswith('.mp4'):
                encontrados.add(nombre[:-4])
        if len(pagina) < tam_pagina:
            break
        offset += tam_pagina
    return encontrados


def pedir_cantidad(disponibles):
    while True:
        try:
            texto = input(f'¿Cuántas secuencias quieres generar ahora? (hay {disponibles} pendientes): ').strip()
        except EOFError:
            sys.exit('No se recibió una cantidad (entrada no interactiva). Usa --cantidad N.')
        if not texto.isdigit() or int(texto) <= 0:
            print('Ingresa un número entero mayor a 0.')
            continue
        return int(texto)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--cantidad', type=int, help='cuantas secuencias procesar; si se omite, lo pregunta por consola')
    ap.add_argument('--conservar-local', action='store_true', help='no borrar el mp4 local despues de subirlo')
    args = ap.parse_args()

    env = cargar_env()
    api_key = env.get('OPENAI_API_KEY')
    if not api_key:
        sys.exit('Falta OPENAI_API_KEY (necesaria para el outro personalizado; no se proporciono).')

    musica = os.path.join(DIR_MUSICA, f'{MUSICA_ARCHIVO}.mp3')
    if not os.path.isfile(musica):
        sys.exit(f'No existe la música: {musica}')

    print('Consultando secuencias en la base de datos...')
    todas = obtener_secuencias(env, None)
    print(f'  {len(todas)} secuencias en total en codigos_grabovoi.')

    print('Revisando cuales ya tienen video narrado subido...')
    vozSlug = VOCES_SLUG[VOZ]
    ya_generados = listar_ya_generados(env, vozSlug)
    print(f'  {len(ya_generados)} ya tienen video.')

    pendientes = [s for s in todas if s['codigo'] not in ya_generados]
    print(f'  {len(pendientes)} pendientes.')

    if not pendientes:
        print('No queda ninguna secuencia pendiente. Listo.')
        return

    cantidad = args.cantidad
    if cantidad is None:
        cantidad = pedir_cantidad(len(pendientes))
    if cantidad > len(pendientes):
        print(f'aviso: pediste {cantidad} pero solo quedan {len(pendientes)} pendientes; se generan esas {len(pendientes)}.')
        cantidad = len(pendientes)

    elegidas = random.sample(pendientes, cantidad)

    os.makedirs(DIR_SALIDA, exist_ok=True)

    exitosas = []
    fallidas = []
    inicio_lote = time.time()

    for i, sec in enumerate(elegidas, 1):
        print(f'\n[{i}/{cantidad}] {sec["codigo"]} - {sec["nombre"]}')
        ruta_salida = os.path.join(DIR_SALIDA, f'{sec["codigo"]}_{vozSlug}.mp4')
        inicio = time.time()
        try:
            dur = generar_video_narrado(
                sec, VOZ, ruta_salida, api_key,
                incluir_outro=True, musica=musica,
            )
            mb = os.path.getsize(ruta_salida) / 1024 / 1024
            print(f'  video generado ({dur:.0f}s, {mb:.1f} MB, {time.time() - inicio:.0f}s de render)')

            url = subir_archivo(env, ruta_salida, f'videos_narrados/{vozSlug}/{sec["codigo"]}.mp4', 'video/mp4')
            print(f'  subida -> {url}')

            exitosas.append(sec['codigo'])
        except SystemExit as e:
            # Los helpers del pipeline (sh(), generar_outro_tts, etc.)
            # usan sys.exit() en vez de excepciones para fallar fuerte en
            # una corrida de una sola secuencia -- aqui, en lote, eso se
            # captura para no tirar abajo el resto.
            print(f'  FALLO: {e}')
            fallidas.append((sec['codigo'], sec['nombre'], str(e)))
        except Exception as e:
            print(f'  FALLO inesperado: {e}')
            fallidas.append((sec['codigo'], sec['nombre'], str(e)))
        finally:
            if not args.conservar_local and os.path.isfile(ruta_salida):
                os.remove(ruta_salida)

    minutos = (time.time() - inicio_lote) / 60
    print(f'\nListo en {minutos:.1f} min. {len(exitosas)} generadas, {len(fallidas)} fallidas.')
    if fallidas:
        print('\nFallidas:')
        for codigo, nombre, error in fallidas:
            print(f'  {codigo} - {nombre}: {error}')

    restantes = len(pendientes) - len(exitosas)
    print(f'\nQuedan {restantes} secuencias pendientes en la biblioteca (de {len(todas)} en total).')


if __name__ == '__main__':
    main()
