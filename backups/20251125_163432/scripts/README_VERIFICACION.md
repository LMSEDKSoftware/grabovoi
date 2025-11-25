# Scripts de Verificación de Recompensas

Estos scripts te permiten verificar directamente qué está pasando con los datos de recompensas en la base de datos.

## Opción 1: Script SQL (Recomendado - Más Completo)

**Archivo**: `scripts/verificar_recompensas_sql.sql`

1. Abre el Dashboard de Supabase
2. Ve a "SQL Editor"
3. Copia y pega el contenido del archivo SQL
4. Ejecuta las queries

Este script te mostrará:
- ✅ Datos del usuario
- ✅ Datos en `user_rewards`
- ✅ Historial de recompensas
- ✅ Progreso del usuario
- ✅ Comparación de datos

## Opción 2: Script Dart (Requiere configuración)

**Archivo**: `scripts/verificar_recompensas.dart`

```bash
dart run scripts/verificar_recompensas.dart 2005.ivan@gmail.com
```

**Nota**: Requiere que el usuario esté autenticado o acceso a service role key.

## Opción 3: Script Bash (Simple)

**Archivo**: `scripts/verificar_recompensas_simple.sh`

```bash
./scripts/verificar_recompensas_simple.sh 2005.ivan@gmail.com
```

**Nota**: Requiere `jq` instalado y variables de entorno configuradas.

## Qué Verificar

1. **Cristales de energía**: Debe incrementarse en 5 después de cada pilotaje cuántico
2. **Luz cuántica**: Debe calcularse basado en `dias_consecutivos` (5% por día)
3. **Updated_at**: Debe actualizarse cada vez que se guardan recompensas
4. **Historial**: Debe tener registros de cada recompensa otorgada

## Problemas Comunes

### Los cristales no se actualizan
- Verifica que `saveUserRewards()` se esté llamando
- Verifica que no haya errores en los logs de Supabase
- Verifica que el `user_id` sea correcto

### Los datos se leen de SharedPreferences
- Esto significa que hay un error al leer de Supabase
- Revisa los logs con `[DIAGNÓSTICO]` en la consola del navegador
- Verifica que el usuario tenga un registro en `user_rewards`

### Los datos están en 0
- El usuario podría no tener un registro inicial
- El método `getUserRewards()` crea uno automáticamente, pero podría fallar
- Verifica que el registro se haya creado en Supabase

