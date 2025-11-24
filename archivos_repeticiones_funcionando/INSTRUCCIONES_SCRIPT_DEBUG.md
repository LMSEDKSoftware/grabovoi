# 🚀 Script de Debug Automático

## Script Creado: `test_debug_chrome.sh`

Este script lanza Chrome en modo debug con DevTools abierto y monitorea los logs automáticamente.

## Características

- ✅ Limpia procesos anteriores de Chrome y Flutter
- ✅ Carga variables de entorno desde `.env`
- ✅ Inicia el servidor Flutter en background
- ✅ Lanza Chrome con DevTools abierto automáticamente
- ✅ Monitorea logs en tiempo real filtrando mensajes importantes
- ✅ DevTools remoto disponible en `http://localhost:9222`

## Uso

```bash
./test_debug_chrome.sh
```

## Qué Monitorea

El script filtra y muestra en tiempo real:
- `DEBUG` - Mensajes de debug
- `ERROR` - Errores
- `❌` - Errores críticos
- `✅` - Operaciones exitosas
- `🔍` - Logs de diagnóstico
- `💾` - Operaciones de guardado
- `user_actions` - Operaciones relacionadas con user_actions
- `auth.uid` - Verificaciones de autenticación
- `42501` - Errores de RLS
- `401` - Errores de autenticación

## Logs Disponibles

- **Logs de Flutter**: `/tmp/flutter_web.log`
- **Consola de Chrome**: Abre DevTools (F12) en la ventana de Chrome
- **DevTools Remoto**: http://localhost:9222

## Detener el Script

Presiona `Ctrl+C` en la terminal donde está corriendo el script.

## Ver Logs Manualmente

```bash
# Ver todos los logs
tail -f /tmp/flutter_web.log

# Ver solo errores y debug
tail -f /tmp/flutter_web.log | grep -E "(DEBUG|ERROR|❌|✅|🔍|💾|user_actions|auth\.uid|42501|401)"
```

## Qué Buscar en los Logs

### Logs de Debug Esperados:
```
🔍 [DEBUG user_actions] Verificando autenticación:
   userId desde AuthService: [UUID]
   auth.uid() desde Supabase: [UUID]
   ¿Coinciden?: true/false
   ¿Usuario autenticado?: true/false
```

### Si Todo Está Bien:
```
✅ [DEBUG user_actions] Autenticación verificada, insertando acción...
✅ [DEBUG user_actions] Acción insertada correctamente
```

### Si Hay Problemas:
```
❌ [DEBUG user_actions] ERROR: No hay usuario autenticado en Supabase
❌ [DEBUG user_actions] ERROR: userId no coincide
```

