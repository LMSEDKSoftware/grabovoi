# Guía para Migrar Imágenes a Supabase Storage (Solución CORS)

## Problema Actual

Las imágenes están alojadas en `https://manigrab.app/imagenes_app/` y tienen problemas de CORS cuando se cargan desde Flutter Web (`http://localhost:49181`). El servidor `manigrab.app` no envía los headers CORS necesarios.

## Solución: Usar Supabase Storage

**✅ Los buckets públicos de Supabase Storage tienen CORS configurado automáticamente**, lo que significa que las imágenes se cargarán sin problemas en Flutter Web.

## Pasos para Migrar las Imágenes

### 1. Crear el Bucket en Supabase (si no existe)

1. Ve al Dashboard de Supabase: https://app.supabase.com
2. Selecciona tu proyecto
3. Ve a **Storage** en el menú lateral
4. Crea un nuevo bucket llamado `wallpapers` (o usa el bucket `images` existente)
5. **IMPORTANTE**: Marca el bucket como **Público** (Public) para que las imágenes sean accesibles sin autenticación

### 2. Subir las Imágenes

Puedes subir las imágenes de dos formas:

#### Opción A: Desde el Dashboard de Supabase
1. Ve a **Storage** → **wallpapers** (o **images**)
2. Haz clic en **Upload file**
3. Sube las imágenes (ej: `app6.png`, `888_888_888.png`, etc.)

#### Opción B: Usando el código Flutter (recomendado para automatización)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

Future<String> uploadWallpaperToSupabase(String imageUrl, String fileName) async {
  try {
    // Descargar la imagen desde la URL externa
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Error descargando imagen: ${response.statusCode}');
    }
    
    // Subir a Supabase Storage
    final client = Supabase.instance.client;
    await client.storage
        .from('wallpapers') // o 'images'
        .upload(fileName, response.bodyBytes, fileOptions: FileOptions(
          upsert: true, // Sobrescribir si existe
          contentType: 'image/png', // o 'image/jpeg' según corresponda
        ));
    
    // Obtener URL pública (con CORS configurado)
    final publicUrl = client.storage
        .from('wallpapers')
        .getPublicUrl(fileName);
    
    print('✅ Imagen subida: $publicUrl');
    return publicUrl;
  } catch (e) {
    print('❌ Error subiendo imagen: $e');
    rethrow;
  }
}
```

### 3. Actualizar la Base de Datos

Una vez que tengas las URLs de Supabase Storage, actualiza la columna `wallpaper_url` en la tabla `codigos_premium`:

```sql
-- Ejemplo: Actualizar un código premium con la nueva URL de Supabase Storage
UPDATE public.codigos_premium
SET wallpaper_url = 'https://[tu-proyecto].supabase.co/storage/v1/object/public/wallpapers/app6.png'
WHERE id = 'premium_1';

-- O si prefieres usar rutas relativas (el código las resolverá automáticamente):
UPDATE public.codigos_premium
SET wallpaper_url = 'wallpapers/app6.png'
WHERE id = 'premium_1';
```

### 4. Formato de URLs

Puedes usar dos formatos en `wallpaper_url`:

#### Formato 1: URL Completa de Supabase Storage
```
https://[proyecto-id].supabase.co/storage/v1/object/public/wallpapers/app6.png
```
✅ **Ventaja**: Funciona inmediatamente, no requiere resolución
✅ **CORS**: Configurado automáticamente por Supabase

#### Formato 2: Ruta Relativa (Recomendado)
```
wallpapers/app6.png
```
✅ **Ventaja**: Más flexible, fácil de cambiar el bucket
✅ **CORS**: El código resuelve automáticamente a URL pública con CORS

### 5. Verificar que Funciona

1. Actualiza `wallpaper_url` en la base de datos con una URL de Supabase Storage
2. Recarga la aplicación Flutter Web
3. Navega a la pantalla de wallpaper premium
4. La imagen debería cargarse sin errores de CORS

## Estructura Recomendada del Bucket

```
wallpapers/
  ├── app6.png
  ├── 888_888_888.png
  ├── 777_777_777.png
  └── ...
```

O si prefieres organizar por código:

```
wallpapers/
  ├── premium_1/
  │   └── wallpaper.png
  ├── premium_2/
  │   └── wallpaper.png
  └── ...
```

## Ventajas de Usar Supabase Storage

1. ✅ **CORS configurado automáticamente** - No más errores de CORS en Flutter Web
2. ✅ **CDN global** - Imágenes se cargan rápido desde cualquier ubicación
3. ✅ **Optimización automática** - Supabase puede convertir imágenes a WebP automáticamente
4. ✅ **Escalable** - Soporta archivos hasta 500GB
5. ✅ **Integración nativa** - Ya estás usando Supabase en el proyecto

## Script SQL para Migración Masiva

Si tienes muchas imágenes para migrar, puedes crear un script que mapee las URLs antiguas a las nuevas:

```sql
-- Ejemplo: Actualizar múltiples códigos premium
UPDATE public.codigos_premium
SET wallpaper_url = CASE
  WHEN wallpaper_url = 'https://manigrab.app/imagenes_app/app6.png' 
    THEN 'wallpapers/app6.png'
  WHEN wallpaper_url = 'https://manigrab.app/imagenes_app/app7.png' 
    THEN 'wallpapers/app7.png'
  -- Agregar más casos según sea necesario
  ELSE wallpaper_url
END
WHERE wallpaper_url LIKE 'https://manigrab.app/%';
```

## Notas Importantes

- ⚠️ **Buckets deben ser públicos** para que las imágenes sean accesibles sin autenticación
- ⚠️ **Permisos RLS**: Si usas Row Level Security, asegúrate de que las políticas permitan lectura pública del bucket
- ⚠️ **Tamaño de archivos**: Verifica que las imágenes no excedan los límites de Supabase Storage
- ✅ **El código actual ya soporta ambos formatos** (URL completa o ruta relativa)
