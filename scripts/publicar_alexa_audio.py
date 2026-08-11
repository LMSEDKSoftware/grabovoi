#!/usr/bin/env python3
"""Renderiza y publica el audio de una secuencia para el skill de Alexa.

Genera el MP3 (voz de la app + música, ver render_alexa_audio.py) para
cada voz, lo sube al bucket público `alexa` de Supabase Storage y deja
la fila correspondiente en alexa_audio_cache para que el skill sepa que
existe.

Uso:
  python3 scripts/publicar_alexa_audio.py --codigo 719_819_714
  python3 scripts/publicar_alexa_audio.py --del-dia      # la de hoy
  python3 scripts/publicar_alexa_audio.py --del-dia --volumen-musica 1.3

Requiere SUPABASE_URL y SB_SERVICE_ROLE_KEY en .env (en la raíz del repo).
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RENDER = os.path.join(RAIZ, 'scripts', 'render_alexa_audio.py')
BUCKET = 'alexa'
VOCES = ['female', 'male', 'male 2']


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


# El SSL de Python está roto en esta máquina (CERTIFICATE_VERIFY_FAILED),
# así que todo el HTTP va por curl, que sí funciona.
def curl(args, entrada=None):
    r = subprocess.run(['curl', '-s', '-S'] + args, capture_output=True,
                       text=(entrada is None), input=entrada)
    if r.returncode != 0:
        err = r.stderr if isinstance(r.stderr, str) else r.stderr.decode()
        sys.exit(f'curl falló: {err}')
    return r.stdout if isinstance(r.stdout, str) else r.stdout.decode()


def secuencia_del_dia(env):
    salida = curl([
        '-X', 'POST', f"{env['SUPABASE_URL']}/rest/v1/rpc/obtener_codigo_del_dia",
        '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
        '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
        '-H', 'Content-Type: application/json', '-d', '{}',
    ])
    filas = json.loads(salida)
    if not filas:
        sys.exit('obtener_codigo_del_dia no devolvió nada')
    return filas[0]['codigo'], filas[0].get('nombre')


def subir(env, ruta_local, ruta_remota):
    with open(ruta_local, 'rb') as f:
        datos = f.read()
    salida = curl([
        '-X', 'POST',
        f"{env['SUPABASE_URL']}/storage/v1/object/{BUCKET}/{ruta_remota}",
        '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
        '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
        '-H', 'Content-Type: audio/mpeg',
        '-H', 'x-upsert: true',
        '-H', 'Cache-Control: max-age=31536000',
        '--data-binary', '@-',
    ], entrada=datos)
    if 'error' in salida.lower() and 'Key' not in salida:
        sys.exit(f'Error subiendo {ruta_remota}: {salida[:300]}')
    return f"{env['SUPABASE_URL']}/storage/v1/object/public/{BUCKET}/{ruta_remota}"


def registrar(env, filas):
    salida = curl([
        '-X', 'POST', f"{env['SUPABASE_URL']}/rest/v1/alexa_audio_cache",
        '-H', f"apikey: {env['SB_SERVICE_ROLE_KEY']}",
        '-H', f"Authorization: Bearer {env['SB_SERVICE_ROLE_KEY']}",
        '-H', 'Content-Type: application/json',
        '-H', 'Prefer: resolution=merge-duplicates',
        '-d', json.dumps(filas),
    ])
    if salida.strip() and 'message' in salida:
        sys.exit(f'Error registrando en alexa_audio_cache: {salida[:300]}')


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--codigo')
    g.add_argument('--del-dia', action='store_true')
    ap.add_argument('--musica', default='crystal_bowls')
    ap.add_argument('--volumen-musica', type=float, default=0.75)
    ap.add_argument('--repeticiones', type=int, default=10)
    args = ap.parse_args()

    env = cargar_env()
    if args.del_dia:
        codigo, nombre = secuencia_del_dia(env)
        print(f'Secuencia del día: {codigo} — {nombre}')
    else:
        codigo = args.codigo

    slug = re.sub(r'[^0-9_]', '', codigo)
    if not slug.strip('_'):
        sys.exit(f'Código sin dígitos utilizables: {codigo}')

    filas = []
    with tempfile.TemporaryDirectory(prefix='pub_alexa_') as tmp:
        for voz in VOCES:
            local = os.path.join(tmp, f'{voz.replace(" ", "")}.mp3')
            r = subprocess.run([
                sys.executable, RENDER,
                '--codigo', codigo, '--voz', voz, '--musica', args.musica,
                '--volumen-musica', str(args.volumen_musica),
                '--repeticiones', str(args.repeticiones),
                '--salida', local,
            ], capture_output=True, text=True)
            if r.returncode != 0:
                sys.exit(f'Render falló para {voz}:\n{r.stdout}\n{r.stderr}')
            if r.stderr.strip():
                print(f'  {r.stderr.strip()}')

            partes = r.stdout.strip().split('|')
            dur = float(partes[1].strip().rstrip('s'))
            reps_reales = int(partes[3].strip().split()[0])

            remota = f'secuencias/{slug}/{voz.replace(" ", "")}.mp3'
            url = subir(env, local, remota)
            print(f'  {voz:8} -> {url}  ({dur:.0f}s)')

            filas.append({
                'codigo': codigo, 'voz': voz, 'musica': args.musica,
                'url': url, 'duracion_s': round(dur, 2),
                'repeticiones': reps_reales,
                'volumen_musica': args.volumen_musica,
                'updated_at': 'now()',
            })

    registrar(env, filas)
    print(f'Listo: {len(filas)} audios publicados para {codigo}')


if __name__ == '__main__':
    main()
