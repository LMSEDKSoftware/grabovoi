#!/usr/bin/env python3
"""Genera roku-tv/audio/intro.mp3: la voz que dice "Bienvenidos a
ManiGrab, secuencias Grabovoi", con la misma voz e instrucciones de tono
que usa generar_video_narrado.py para las instrucciones de pilotaje (voz
'coral' de OpenAI TTS) -- para que suene a la misma locutora en toda la
app, no una voz distinta solo para la cortinilla.

Uso:
  python3 scripts/generar_audio_intro.py

Pide OPENAI_API_KEY si hace falta (.env, variable de entorno, o por
consola). Despues de correr esto hay que volver a generar el video con
scripts/generar_intro.py (la duracion del video sigue la del audio).
"""

import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generar_assets_secuencias import RAIZ, cargar_env  # noqa: E402

TTS_VOZ = 'coral'
TTS_INSTRUCCIONES = (
    'Habla en español neutro, pronunciación clara y natural, como una '
    'locutora hispanohablante nativa. Tono cálido, alegre y celebratorio, '
    'ritmo pausado.'
)
TEXTO = 'Bienvenidos a ManiGrab, secuencias Grabovoi.'
DESTINO = os.path.join(RAIZ, 'roku-tv', 'audio', 'intro.mp3')


def main():
    env = cargar_env()
    api_key = env.get('OPENAI_API_KEY')
    if not api_key:
        sys.exit('Falta OPENAI_API_KEY (no se proporciono).')

    os.makedirs(os.path.dirname(DESTINO), exist_ok=True)
    payload = json.dumps({
        'model': 'gpt-4o-mini-tts',
        'voice': TTS_VOZ,
        'input': TEXTO,
        'instructions': TTS_INSTRUCCIONES,
        'response_format': 'mp3',
    })
    r = subprocess.run(
        ['curl', '-s', '-S', 'https://api.openai.com/v1/audio/speech',
         '-H', f'Authorization: Bearer {api_key}',
         '-H', 'Content-Type: application/json',
         '-d', payload,
         '-o', DESTINO],
        capture_output=True, text=True,
    )
    if r.returncode != 0 or not os.path.isfile(DESTINO) or os.path.getsize(DESTINO) < 1000:
        sys.exit(f'Fallo generando el audio: {r.stderr}')

    print(f'Listo -> {DESTINO} ({os.path.getsize(DESTINO)} bytes)')


if __name__ == '__main__':
    main()
