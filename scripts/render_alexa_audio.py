#!/usr/bin/env python3
"""Renderiza el audio de una secuencia para el skill de Alexa.

Alexa limita cuántos archivos de audio puede reproducir en una respuesta
(5 en SSML, ~15 en APLA), y una secuencia de 9 dígitos repetida 10 veces
son 90 clips. Imposible por esa vía. La salida de este script es UN solo
MP3 con todo ya mezclado: la voz grabada de la app + la música de fondo,
con las mismas pausas que usa NumbersVoiceService. Alexa solo reproduce
ese archivo.

Replica exactamente lib/services/numbers_voice_service.dart:
  - 280ms entre dígitos            (_gapBetweenDigits)
  - 100ms antes y después del      (_silenceAroundEspacio)
    clip "espacio" de los "_"
  - 1800ms -> "nuevamente" ->      (_pauseBefore/_pauseAfterNuevamente)
    1800ms entre repeticiones
  - música al 40% mientras         (AudioManagerService().setVolume(0.4))
    suena la voz

Uso:
  python3 scripts/render_alexa_audio.py --codigo 520_741_889 \
      --voz female --salida /tmp/salida.mp3
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_VOCES = os.path.join(RAIZ, 'assets', 'audios', 'voice_numbers')
DIR_MUSICA = os.path.join(RAIZ, 'assets', 'audios')

GAP_DIGITOS_MS = 280
SILENCIO_ESPACIO_MS = 100
PAUSA_ANTES_NUEVAMENTE_MS = 1800
PAUSA_DESPUES_NUEVAMENTE_MS = 1800
# En la app la música va al 40% pero en un reproductor aparte, a su
# volumen natural. Aquí es una mezcla, y hay que compensar dos cosas:
# amix normaliza dividiendo entre el número de entradas (-6 dB), y las
# pistas de ambiente son de por sí suaves. Sin compensar, la música
# quedaba a -42 dB en las pausas: técnicamente presente, inaudible en
# la práctica. Se usa normalize=0 y este volumen ya compensado.
VOLUMEN_MUSICA = 0.75
REPETICIONES = 10

# Alexa corta la respuesta COMPLETA en 240s, y ahí también cuenta la
# intro hablada y el cierre. Dejamos 45s de margen para eso: con códigos
# largos (el peor de la biblioteca son 19 tokens) 10 repeticiones dan
# 231s y se pasaría, así que en esos casos se bajan las repeticiones.
MAX_DURACION_S = 195
MAX_TAMANO_MB = 10
MIN_REPETICIONES = 3

SR = 24000  # mono 24 kHz: dentro de lo que acepta APLA y mantiene el peso bajo


def sh(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f'ffmpeg falló:\n{" ".join(args)}\n{r.stderr[-2000:]}')
    return r


def duracion(path):
    r = sh(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
            '-of', 'csv=p=0', path])
    return float(r.stdout.strip())


def a_wav(origen, destino):
    sh(['ffmpeg', '-y', '-v', 'error', '-i', origen,
        '-ac', '1', '-ar', str(SR), destino])


def silencio(ms, destino):
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'lavfi',
        '-i', f'anullsrc=r={SR}:cl=mono', '-t', f'{ms / 1000:.3f}', destino])


def concat(piezas, destino, tmp):
    lista = os.path.join(tmp, f'lista_{os.path.basename(destino)}.txt')
    with open(lista, 'w') as f:
        for p in piezas:
            f.write(f"file '{p}'\n")
    sh(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0',
        '-i', lista, '-c', 'copy', destino])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--codigo', required=True)
    ap.add_argument('--voz', default='female', choices=['female', 'male', 'male 2'])
    ap.add_argument('--musica', default='crystal_bowls')
    ap.add_argument('--repeticiones', type=int, default=REPETICIONES)
    ap.add_argument('--volumen-musica', type=float, default=VOLUMEN_MUSICA,
                    help='1.0 = música al mismo nivel que la voz')
    ap.add_argument('--salida', required=True)
    args = ap.parse_args()

    dir_voz = os.path.join(DIR_VOCES, args.voz)
    if not os.path.isdir(dir_voz):
        sys.exit(f'No existe la carpeta de voz: {dir_voz}')
    musica = os.path.join(DIR_MUSICA, f'{args.musica}.mp3')
    if not os.path.isfile(musica):
        sys.exit(f'No existe la música: {musica}')

    # Los códigos traen "_" como separador visual (ej. 520_741_889); en la
    # app cada "_" suena como el clip espacio.mp3.
    tokens = [c for c in args.codigo if c.isdigit() or c == '_']
    if not any(c.isdigit() for c in tokens):
        sys.exit(f'El código no tiene dígitos: {args.codigo}')

    tmp = tempfile.mkdtemp(prefix='alexa_audio_')
    try:
        # Clips de voz a wav
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
        silencio(PAUSA_ANTES_NUEVAMENTE_MS, sil_nue)

        # Una repetición: cada token con su pausa, igual que en la app
        piezas = []
        for t in tokens:
            if t == '_':
                piezas += [sil_esp, clips['espacio'], sil_esp]
            else:
                piezas += [clips[t], sil_gap]
        rep = os.path.join(tmp, 'rep.wav')
        concat(piezas, rep, tmp)

        # Enlace entre repeticiones: pausa -> "nuevamente" -> pausa
        enlace = os.path.join(tmp, 'enlace.wav')
        concat([sil_nue, clips['nuevamente'], sil_nue], enlace, tmp)

        # Cuántas repeticiones caben en el presupuesto de duración.
        # n repeticiones = n*rep + (n-1)*enlace
        d_rep, d_enlace = duracion(rep), duracion(enlace)
        cabe = int((MAX_DURACION_S + d_enlace) // (d_rep + d_enlace))
        reps = max(MIN_REPETICIONES, min(args.repeticiones, cabe))
        if reps < args.repeticiones:
            print(
                f'aviso: {args.codigo} es largo ({d_rep:.0f}s por repetición); '
                f'{args.repeticiones} repeticiones no caben en el límite de '
                f'Alexa, se usan {reps}.',
                file=sys.stderr,
            )

        # Secuencia completa: rep (enlace rep) x (n-1) — sin "nuevamente" al final
        completa = os.path.join(tmp, 'voz.wav')
        concat([rep] + [enlace, rep] * (reps - 1), completa, tmp)
        dur = duracion(completa)

        # Mezcla: música en bucle recortada al largo de la voz, al 40%,
        # con fundido de entrada y salida para que no entre ni corte seco.
        fade = 2.0
        sh(['ffmpeg', '-y', '-v', 'error',
            '-stream_loop', '-1', '-i', musica,
            '-i', completa,
            '-filter_complex',
            f'[0:a]atrim=0:{dur:.3f},volume={args.volumen_musica},'
            f'afade=t=in:st=0:d={fade},afade=t=out:st={max(0, dur - fade):.3f}:d={fade}[mus];'
            f'[mus][1:a]amix=inputs=2:duration=first:dropout_transition=0:normalize=0,'
            f'alimiter=limit=0.95[out]',
            '-map', '[out]', '-ac', '1', '-ar', str(SR), '-b:a', '64k',
            args.salida])

        mb = os.path.getsize(args.salida) / 1024 / 1024
        if mb > MAX_TAMANO_MB:
            sys.exit(f'El archivo pesa {mb:.1f} MB y Alexa corta en 10 MB.')

        # Formato estable: publicar_alexa_audio.py lo parsea. Las
        # repeticiones reales pueden ser menos que las pedidas (códigos
        # largos, o voces con clips más lentos), y hay que registrar las
        # reales, no las solicitadas.
        print(f'{args.salida}  |  {duracion(args.salida):.1f}s  |  {mb:.2f} MB  |  {reps} reps')
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    main()
