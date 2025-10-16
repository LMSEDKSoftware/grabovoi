# Configuración de Supabase para Manifestación Numérica Grabovoi

## 🚀 Configuración Inicial

### 1. Crear el Esquema de Base de Datos

1. Ve al dashboard de Supabase: https://supabase.com/dashboard
2. Selecciona tu proyecto: `whtiazgcxdnemrrgjjqf`
3. Ve a **SQL Editor**
4. Ejecuta el script `supabase_schema.sql` que se encuentra en la raíz del proyecto

### 2. Configurar Storage para Audios

1. Ve a **Storage** en el dashboard de Supabase
2. Crea un bucket llamado `audios` (si no existe)
3. Configura las políticas de acceso:
   - **Public Access**: Permitir acceso público para lectura
   - **Authenticated Upload**: Permitir subida solo a usuarios autenticados

### 3. Subir Archivos de Audio

Sube los siguientes archivos al bucket `audios`:
- `432hz_harmony.mp3`
- `528hz_love.mp3`
- `binaural_manifestation.mp3`
- `crystal_bowls.mp3`
- `forest_meditation.mp3`

## 📊 Estructura de la Base de Datos

### Tablas Creadas:

1. **`codigos_grabovoi`** - Códigos numéricos de Grabovoi
   - `id` (UUID, PK)
   - `codigo` (TEXT, UNIQUE)
   - `nombre` (TEXT)
   - `descripcion` (TEXT)
   - `categoria` (TEXT)
   - `created_at`, `updated_at` (TIMESTAMP)

2. **`usuario_favoritos`** - Favoritos de usuarios
   - `id` (UUID, PK)
   - `user_id` (TEXT)
   - `codigo_id` (TEXT, FK)
   - `created_at` (TIMESTAMP)

3. **`codigo_popularidad`** - Popularidad de códigos
   - `id` (UUID, PK)
   - `codigo_id` (TEXT, FK)
   - `contador` (INTEGER)
   - `ultimo_uso` (TIMESTAMP)
   - `created_at`, `updated_at` (TIMESTAMP)

4. **`audio_files`** - Archivos de audio
   - `id` (UUID, PK)
   - `nombre` (TEXT)
   - `archivo` (TEXT)
   - `descripcion` (TEXT)
   - `categoria` (TEXT)
   - `duracion` (INTEGER)
   - `url` (TEXT)
   - `created_at` (TIMESTAMP)

5. **`usuario_progreso`** - Progreso de usuarios
   - `id` (UUID, PK)
   - `user_id` (TEXT, UNIQUE)
   - `dias_consecutivos` (INTEGER)
   - `total_pilotajes` (INTEGER)
   - `nivel_energetico` (INTEGER)
   - `ultimo_pilotaje` (TIMESTAMP)
   - `created_at`, `updated_at` (TIMESTAMP)

## 🔧 Configuración de la Aplicación

### Variables de Entorno:

```dart
// Ya configuradas en lib/services/supabase_config.dart
const String _supabaseUrl = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
const String _supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### Servicios Implementados:

1. **`SupabaseConfig`** - Configuración inicial del cliente
2. **`SupabaseService`** - Operaciones CRUD básicas
3. **`BibliotecaSupabaseService`** - Servicios específicos para la biblioteca
4. **`MigrationService`** - Migración de datos iniciales

## 📱 Funcionalidades Implementadas:

### ✅ Completadas:
- ✅ Configuración de Supabase
- ✅ Modelos de datos con serialización JSON
- ✅ Servicios CRUD completos
- ✅ Migración automática de códigos
- ✅ Sistema de favoritos
- ✅ Sistema de popularidad
- ✅ Gestión de audios
- ✅ Progreso de usuario
- ✅ Inicialización en main.dart

### 🔄 Próximos Pasos:
- [ ] Actualizar pantalla de biblioteca para usar Supabase
- [ ] Implementar autenticación de usuarios
- [ ] Configurar notificaciones push
- [ ] Implementar sincronización offline
- [ ] Agregar analytics y métricas

## 🚨 Notas Importantes:

1. **Primera Ejecución**: La aplicación migrará automáticamente los datos del JSON local a Supabase
2. **Storage**: Los audios deben subirse manualmente al bucket `audios`
3. **Políticas**: Las políticas de seguridad permiten acceso público para lectura
4. **Autenticación**: Actualmente usa un ID de usuario fijo (`user_demo`)

## 🔍 Verificación:

Para verificar que todo funciona correctamente:

1. Ejecuta la aplicación
2. Ve a la pantalla de Biblioteca
3. Verifica que se cargan los códigos desde Supabase
4. Prueba agregar/quitar favoritos
5. Verifica que se incrementa la popularidad

## 📞 Soporte:

Si encuentras algún problema:
1. Revisa los logs de la consola
2. Verifica la conexión a Supabase en el dashboard
3. Confirma que el esquema se creó correctamente
4. Verifica que los audios están en el bucket de storage
