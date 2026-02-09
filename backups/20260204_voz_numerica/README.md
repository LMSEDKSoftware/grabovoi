# Respaldo pre-implementación: Voz numérica (2026-02-04)

Respaldo completo de todos los archivos que se modifican en la implementación de la funcionalidad "Voz numérica en pilotajes".

## Regla de trabajo

**A partir de esta implementación: respaldar siempre cada archivo antes de cualquier modificación** (usar `./scripts/backup_file.sh <ruta>` o copia en esta carpeta).

## Contenido del respaldo

- `lib/models/rewards_model.dart`, `rewards_model.g.dart`
- `lib/services/rewards_service.dart`, `audio_manager_service.dart`
- `lib/screens/codes/repetition_session_screen.dart`, `code_detail_screen.dart`
- `lib/screens/pilotaje/quantum_pilotage_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/main.dart`
- `pubspec.yaml`

## Restaurar

Para revertir un archivo:
```bash
cp backups/20260204_voz_numerica/lib/models/rewards_model.dart lib/models/
# (y así con cada ruta)
```
