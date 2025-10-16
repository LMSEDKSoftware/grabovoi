# 🚀 Instrucciones para Deployar Supabase Edge Functions

## 📋 Prerequisitos
1. **Supabase CLI instalado:**
   ```bash
   npm install -g supabase
   ```

2. **Autenticado en Supabase:**
   ```bash
   supabase login
   ```

## 🛠️ Pasos para Deployar

### 1. ✅ Inicializar proyecto Supabase (COMPLETADO)
```bash
supabase init
```

### 2. 🔑 Obtener Token de Acceso
1. Ve a: https://supabase.com/dashboard/account/tokens
2. Crea un nuevo token de acceso
3. Copia el token

### 3. 🔗 Linkear con tu proyecto
```bash
# Opción A: Con token en línea de comandos
supabase link --project-ref whtiazgcxdnemrrgjjqf --token TU_TOKEN_AQUI

# Opción B: Con variable de entorno
export SUPABASE_ACCESS_TOKEN=TU_TOKEN_AQUI
supabase link --project-ref whtiazgcxdnemrrgjjqf
```

### 4. ✅ Deployar las funciones (COMPLETADO)
```bash
# Deployar función para obtener códigos
supabase functions deploy get-codigos

# Deployar función para obtener categorías
supabase functions deploy get-categorias
```

### 5. ✅ Verificar deployment (COMPLETADO)
```bash
# Ver funciones deployadas
supabase functions list
```

**Resultado:**
- ✅ `get-codigos`: ACTIVE (359 códigos disponibles)
- ✅ `get-categorias`: ACTIVE (10 categorías disponibles)

## 🌐 URLs de las APIs

Una vez deployadas, las APIs estarán disponibles en:

- **Códigos:** `https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-codigos`
- **Categorías:** `https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-categorias`

## 🧪 Probar las APIs

### Obtener todos los códigos:
```bash
curl -X GET "https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-codigos" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU"
```

### Obtener categorías:
```bash
curl -X GET "https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/get-categorias" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodGlhemdjeGRuZW1ycmdqanFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MjM2MzgsImV4cCI6MjA3NjA5OTYzOH0.1CFkusMrMKcvSU_-5RyGYPoKDM_yizuQMVGo7W3mXHU"
```

## ✅ Verificación

Una vez deployadas, la app Flutter podrá conectarse a estas APIs en lugar de hacer conexión directa a la base de datos.

## 📱 Builds Exitosos ✅

Los archivos compilados están listos en:
- **APK**: `build/app/outputs/flutter-apk/app-release.apk` (111.3MB) ✅
- **Web**: `build/web/` (carpeta completa) ✅

### 🎯 Características del Build Final
- ✅ **API REST**: Conectado a Supabase Edge Functions
- ✅ **359 códigos Grabovoi**: Base de datos completa
- ✅ **10 categorías**: Salud, Abundancia, Amor, etc.
- ✅ **Búsqueda inteligente**: Sistema de 3 niveles con IA
- ✅ **Favoritos y popularidad**: Funcionalidad completa
- ✅ **Esfera dorada**: Visualización 3D mejorada
- ✅ **Audio streaming**: Sistema de audio optimizado
- ✅ **Responsive**: Funciona en móvil y web

## 🔧 Troubleshooting

### ✅ PROBLEMA RESUELTO: "Failed host lookup"

**Error original:**
```
ClientException with SocketException: Failed host lookup: 'whtiazgcxdnemrrgjjqf.supabase.co'
```

**Solución implementada:**
1. ✅ **Permisos Android agregados** en `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

2. ✅ **Uri.https implementado** en lugar de `Uri.parse()`:
   ```dart
   final uri = Uri.https(
     'whtiazgcxdnemrrgjjqf.supabase.co',
     '/functions/v1/get-codigos',
     queryParams.isNotEmpty ? queryParams : null,
   );
   ```

3. ✅ **Headers HTTP mejorados**:
   ```dart
   'User-Agent': 'FlutterApp/1.0',
   'Accept': 'application/json',
   'Cache-Control': 'no-cache',
   'Connection': 'keep-alive',
   ```

4. ✅ **Manejo de errores específico** para DNS:
   ```dart
   if (e.toString().contains('Failed host lookup') || e.toString().contains('SocketException')) {
     throw Exception('Error de conectividad: No se puede resolver el servidor. Verifica tu conexión a internet y configuración DNS.');
   }
   ```

### 📱 Prueba de Conectividad

Si persisten problemas, ejecutar:
```bash
dart test_connectivity.dart
```

### 🔍 Otros problemas posibles:
1. Verificar que las credenciales sean correctas
2. Revisar logs: `supabase functions logs get-codigos`
3. Verificar que la tabla `codigos_grabovoi` exista y tenga datos
4. Probar en diferentes redes (WiFi vs datos móviles)
5. Verificar configuración DNS del dispositivo (usar 8.8.8.8)
