# Scripts para Configurar Links Legales

Este directorio contiene scripts SQL para configurar los links legales que se muestran en la sección "Información Legal" del perfil de usuario.

## Archivos

1. **`app_config_schema.sql`** - Crea la tabla `app_config` con su estructura completa, políticas RLS y valores iniciales
2. **`insertar_links_legales.sql`** - Inserta o actualiza los links legales usando `ON CONFLICT DO UPDATE`
3. **`actualizar_links_legales.sql`** - Actualiza solo los valores de los links (asume que la tabla ya existe)

## Cómo usar

### Opción 1: Primera vez (crear tabla y datos)

1. Ejecuta primero `app_config_schema.sql` en el SQL Editor de Supabase
2. Luego ejecuta `insertar_links_legales.sql` y reemplaza las URLs de ejemplo con tus URLs reales

### Opción 2: Solo actualizar URLs (tabla ya existe)

1. Abre `actualizar_links_legales.sql` en el SQL Editor de Supabase
2. Reemplaza todas las URLs de ejemplo (`https://example.com/...`) con tus URLs reales
3. Ejecuta el script

### Opción 3: Usar INSERT con ON CONFLICT (recomendado)

1. Abre `insertar_links_legales.sql` en el SQL Editor de Supabase
2. Reemplaza las URLs de ejemplo con tus URLs reales
3. Ejecuta el script (puede ejecutarse múltiples veces, actualizará si ya existen)

## URLs que necesitas configurar

Los siguientes links se muestran en la app:

- **Política de Privacidad** (`legal_privacy_policy_url`)
- **Términos y Condiciones** (`legal_terms_url`)
- **Política de Cookies** (`legal_cookies_url`)
- **Política de Uso de Datos** (`legal_data_usage_url`) - Opcional
- **Créditos y Reconocimientos** (`legal_credits_url`) - Opcional

## Ejemplo de URLs reales

```sql
INSERT INTO public.app_config (key, value, description) VALUES
  ('legal_privacy_policy_url', 'https://tudominio.com/politica-privacidad', 'URL de la Política de Privacidad'),
  ('legal_terms_url', 'https://tudominio.com/terminos-condiciones', 'URL de los Términos y Condiciones'),
  ('legal_cookies_url', 'https://tudominio.com/politica-cookies', 'URL de la Política de Cookies')
ON CONFLICT (key) 
DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = NOW();
```

## Verificar que funcionó

Después de ejecutar el script, puedes verificar que los datos se insertaron correctamente:

```sql
SELECT key, value, description, updated_at
FROM public.app_config
WHERE key LIKE 'legal_%'
ORDER BY key;
```

## Notas importantes

- Los links se obtienen desde la base de datos mediante `LegalLinksService`
- Si no existen en la DB, la app usa valores por defecto (URLs de ejemplo)
- Solo usuarios admin pueden modificar estos valores (según las políticas RLS)
- Todos los usuarios pueden leer estos valores (lectura pública)

## Estructura de la tabla

```sql
CREATE TABLE public.app_config (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

