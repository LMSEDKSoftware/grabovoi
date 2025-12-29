# 📱 Instalar APK en Dispositivo Android

## Ubicación del APK

El APK se encuentra en:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Métodos de Instalación

### Método 1: Usando ADB (Recomendado)

1. **Conecta tu dispositivo Android** por USB
2. **Habilita "Depuración USB"** en tu dispositivo:
   - Ve a Configuración → Opciones de desarrollador → Depuración USB
   - Si no ves "Opciones de desarrollador", ve a Configuración → Acerca del teléfono y toca "Número de compilación" 7 veces

3. **Verifica que el dispositivo esté conectado:**
   ```bash
   adb devices
   ```
   Deberías ver tu dispositivo listado.

4. **Instala el APK:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Método 2: Transferencia Manual

1. **Transfiere el APK** a tu dispositivo Android:
   - Por USB (copia el archivo a la carpeta de descargas)
   - Por email (envíate el APK a ti mismo)
   - Por Google Drive/Dropbox
   - Por Bluetooth

2. **Abre el archivo** en tu dispositivo Android

3. **Permite la instalación** de fuentes desconocidas si se solicita:
   - Ve a Configuración → Seguridad → Fuentes desconocidas (o similar según tu versión de Android)

4. **Instala el APK** tocando en el archivo

## Verificar Deep Link

Una vez instalada la app, puedes probar el deep link manualmente:

```bash
# Desde tu computadora (con el dispositivo conectado)
adb shell am start -a android.intent.action.VIEW -d "com.manifestacion.grabovoi://login-callback?token=test&type=signup"
```

O usa el script de prueba:
```bash
./scripts/test_deep_link.sh test_token signup
```

## Probar Registro y Confirmación

1. **Abre la app** en tu dispositivo
2. **Regístrate** con un email nuevo
3. **Revisa tu email** (deberías recibir un correo de confirmación)
4. **Haz clic en el link** del email
5. **La app debería abrirse automáticamente** y confirmar tu cuenta

## Troubleshooting

### Error: "Dispositivo no autorizado"
- Acepta el diálogo de "Permitir depuración USB" en tu dispositivo

### Error: "APK no se instala"
- Desinstala la versión anterior de la app si existe
- Verifica que tengas suficiente espacio en el dispositivo
- Asegúrate de permitir "Fuentes desconocidas"

### El deep link no funciona
- Verifica que el link en el email tenga el formato: `com.manifestacion.grabovoi://login-callback?...`
- Revisa los logs de la app: `adb logcat | grep -i "grabovoi\|supabase\|auth"`


