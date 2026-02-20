# Guía de Compilación Limpia

## Lanzamiento en Web (Chrome)

En web, Supabase requiere `SUPABASE_URL` y `SUPABASE_ANON_KEY` vía `--dart-define` porque `.env` no se carga como asset. **Siempre** lanza la app web con:

```bash
./scripts/launch_chrome.sh
```

Ese script carga `.env` y pasa las variables por `--dart-define`. Si ejecutas `flutter run -d chrome` directamente sin el script, las peticiones a Supabase fallarán.

### Auditoría en modo DEBUG (Chrome)

Para verificar que la app compile, analice sin errores y funcione en Chrome:

```bash
./scripts/auditoria_debug_chrome.sh
```

- Sin argumentos: ejecuta `flutter analyze`, `flutter build web --debug`, `flutter test`, lanza la app en Chrome y verifica que el servidor responda.
- Con `--no-launch`: solo análisis y build, sin lanzar Chrome.

Los logs se guardan en `logs/auditoria_debug_YYYYMMDD_HHMMSS.log`.

---

## Por qué ocurren los errores "Operation not permitted"
A menudo, al ejecutar comandos como `flutter clean` o `flutter build`, se generan archivos temporales (especialmente el `lockfile` en la caché de Flutter) con permisos de `root` si se usó `sudo` previamente o si hubo un conflicto de permisos. Esto impide que ejecuciones posteriores funcionen correctamente.

## Solución Definitiva

Para asegurar una compilación limpia sin errores de permisos, sigue estos pasos:

### 1. Corregir permisos de Flutter (UNA VEZ)
Ejecuta este comando en tu terminal para asignar la propiedad de la carpeta de Flutter a tu usuario actual:

```bash
sudo chown -R $(whoami) ~/development/flutter/bin/cache/
```

*(Si tu flutter está instalado en otra ruta, ajusta el comando)*

### 2. Usar el Script de Compilación Robusto
He creado un script (`scripts/BUILD_APK_CLEAN.sh`) que:
1.  Verifica la existencia del archivo `.env`.
2.  Carga las variables de entorno de forma segura.
3.  Verifica permisos de escritura en la caché de Flutter.
4.  Ejecuta la compilación con todos los parámetros necesarios.

Para usarlo:

```bash
./scripts/BUILD_APK_CLEAN.sh
```

### 3. Solución de Problemas Comunes

- **Error `.env` no encontrado**: Asegúrate de estar en la raíz del proyecto (`grabovoi_build`) antes de ejecutar el script.
- **Error `lockfile`**: Si persiste, asegúrate de no tener procesos Dart/Flutter "zombies" corriendo:
  ```bash
  pkill -f dart
  pkill -f flutter
  rm -f ~/development/flutter/bin/cache/lockfile
  ```
