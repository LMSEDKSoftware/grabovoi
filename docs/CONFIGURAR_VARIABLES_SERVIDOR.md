# 🔧 Cómo Configurar Variables de Entorno en el Servidor

## 📍 ¿Dónde se Configuran?

**IMPORTANTE:** Estas variables se configuran **EN TU SERVIDOR DE HOSTING** (manigrab.app), **NO en Supabase**.

El archivo `reset-password.php` necesita acceso a estas variables para funcionar.

---

## 🎯 Variables Requeridas

```bash
SUPABASE_URL=https://whtiazgcxdnemrrgjjqf.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (tu service role key completo)
APP_URL=https://manigrab.app
```

**¿Dónde obtener el SERVICE_ROLE_KEY?**
1. Ve a Supabase Dashboard: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Settings → API
4. Copia el valor de **"service_role" key** (⚠️ es secreto, no lo compartas)

---

## 📋 Método 1: Archivo `.env` (Recomendado para la mayoría de servidores)

### Paso 1: Crear archivo `.env`

En tu servidor, en el mismo directorio donde está `reset-password.php`, crea un archivo llamado `.env`:

```
📁 public_html/
   📁 api/
      📄 email_endpoint.php
      📄 reset-password.php  ← Aquí debe estar
      📄 .env  ← CREAR ESTE ARCHIVO AQUÍ
```

### Paso 2: Contenido del archivo `.env`

```env
# Variables de entorno para reset-password.php
SUPABASE_URL=https://whtiazgcxdnemrrgjjqf.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.aqui_va_tu_service_role_key_completo
APP_URL=https://manigrab.app
```

**⚠️ IMPORTANTE:**
- Reemplaza `aqui_va_tu_service_role_key_completo` con tu Service Role Key real
- No dejes espacios alrededor del signo `=`
- No uses comillas a menos que el valor las necesite

### Paso 3: Configurar permisos del archivo

El archivo `.env` debe tener permisos restringidos (solo lectura para el servidor web):

```bash
chmod 600 .env
```

O en cPanel:
- Selecciona el archivo `.env`
- Cambiar permisos a `600` (read/write para propietario, nada para otros)

---

## 📋 Método 2: Variables de Entorno del Sistema (VPS/Dedicated)

Si tienes acceso SSH a un servidor VPS o dedicado:

### Opción A: Configurar en Apache (.htaccess)

Crea o edita `.htaccess` en el mismo directorio:

```apache
<IfModule mod_env.c>
    SetEnv SUPABASE_URL "https://whtiazgcxdnemrrgjjqf.supabase.co"
    SetEnv SUPABASE_SERVICE_ROLE_KEY "tu_service_role_key_aqui"
    SetEnv APP_URL "https://manigrab.app"
</IfModule>
```

### Opción B: Configurar en PHP-FPM

Edita el archivo de configuración PHP-FPM (generalmente `/etc/php/8.x/fpm/pool.d/www.conf`):

```ini
env[SUPABASE_URL] = https://whtiazgcxdnemrrgjjqf.supabase.co
env[SUPABASE_SERVICE_ROLE_KEY] = tu_service_role_key_aqui
env[APP_URL] = https://manigrab.app
```

Luego reinicia PHP-FPM:
```bash
sudo systemctl restart php8.x-fpm
```

---

## 📋 Método 3: cPanel - Variables de Entorno

Si usas cPanel (hosting compartido):

### Paso 1: Acceder a Variables de Entorno

1. Login en cPanel
2. Buscar sección **"Variables de Entorno"** o **"Environment Variables"**
   - A veces está en "PHP" → "Variables de Entorno"
   - O en "Advanced" → "Environment Variables"

### Paso 2: Agregar Variables

Agregar cada variable una por una:

| Variable | Valor |
|----------|-------|
| `SUPABASE_URL` | `https://whtiazgcxdnemrrgjjqf.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | `tu_service_role_key_completo` |
| `APP_URL` | `https://manigrab.app` |

### Paso 3: Guardar

Guardar los cambios. Puede tomar unos minutos en aplicarse.

---

## 📋 Método 4: Directamente en el Código (Solo para pruebas)

⚠️ **NO RECOMENDADO para producción**, pero si necesitas una solución rápida temporal:

Edita `reset-password.php` y busca estas líneas (alrededor de la línea 17):

```php
$SUPABASE_URL = getenv('SUPABASE_URL') ?: 'https://whtiazgcxdnemrrgjjqf.supabase.co';
$SERVICE_ROLE_KEY = getenv('SUPABASE_SERVICE_ROLE_KEY');
$APP_URL = getenv('APP_URL') ?: 'https://manigrab.app';
```

Reemplázalas con:

```php
// ⚠️ TEMPORAL - Configurar variables de entorno después
$SUPABASE_URL = 'https://whtiazgcxdnemrrgjjqf.supabase.co';
$SERVICE_ROLE_KEY = 'tu_service_role_key_aqui';
$APP_URL = 'https://manigrab.app';
```

**⚠️ Recuerda revertir esto después de configurar las variables correctamente.**

---

## ✅ Verificar que Funciona

### Test 1: Verificar que PHP puede leer las variables

Crea un archivo temporal `test-env.php` en el mismo directorio:

```php
<?php
echo "SUPABASE_URL: " . (getenv('SUPABASE_URL') ?: 'NO CONFIGURADO') . "\n";
echo "SUPABASE_SERVICE_ROLE_KEY: " . (getenv('SUPABASE_SERVICE_ROLE_KEY') ? 'CONFIGURADO (' . strlen(getenv('SUPABASE_SERVICE_ROLE_KEY')) . ' caracteres)' : 'NO CONFIGURADO') . "\n";
echo "APP_URL: " . (getenv('APP_URL') ?: 'NO CONFIGURADO') . "\n";
```

Accede desde el navegador:
```
https://manigrab.app/reset-password.php/test-env.php
```

Si ves los valores correctos, las variables están configuradas. **⚠️ Elimina este archivo después del test.**

### Test 2: Verificar reset-password.php

Accede a:
```
https://manigrab.app/reset-password.php?email=tu-email@test.com
```

Si NO muestra error de "SUPABASE_SERVICE_ROLE_KEY no está configurado", entonces funciona.

---

## 🔒 Seguridad

1. ✅ **Nunca** subas el archivo `.env` a Git
2. ✅ **Nunca** compartas tu Service Role Key públicamente
3. ✅ Configura permisos `600` en el archivo `.env`
4. ✅ Si usas `.htaccess`, verifica que esté en el `.htaccess` de la carpeta (no en `.htpasswd`)

---

## 🐛 Troubleshooting

### Error: "SUPABASE_SERVICE_ROLE_KEY no está configurado"

**Causas posibles:**
1. El archivo `.env` no está en el mismo directorio que `reset-password.php`
2. El archivo `.env` tiene permisos incorrectos
3. El formato del archivo `.env` es incorrecto (espacios, comillas, etc.)
4. PHP no tiene permisos para leer el archivo

**Soluciones:**
- Verifica la ubicación del archivo `.env`
- Verifica permisos: `chmod 600 .env`
- Verifica formato: no espacios alrededor del `=`
- Prueba el método alternativo (cPanel o directamente en código temporalmente)

### Error: Variables no se leen desde .env

**Causas:**
- El archivo `.env` no existe en el mismo directorio
- PHP no puede leer archivos `.env` (algunos servidores lo deshabilitan)

**Solución:**
- Usa el método de cPanel o variables del sistema
- O edita temporalmente el código PHP directamente

---

## 📝 Resumen Rápido

**Para la mayoría de casos (hosting compartido):**

1. ✅ Crear archivo `.env` en el mismo directorio que `reset-password.php`
2. ✅ Agregar las 3 variables con sus valores
3. ✅ Configurar permisos `600`
4. ✅ Probar con `test-env.php`
5. ✅ Eliminar `test-env.php`

**¿Tienes acceso SSH?**
- Usa método 2 (Apache/PHP-FPM)

**¿Solo tienes cPanel?**
- Usa método 3 (cPanel Environment Variables)

---

## 🆘 ¿Necesitas Ayuda?

Si después de seguir estos pasos todavía tienes problemas:

1. Verifica que el archivo `reset-password.php` existe en: `https://manigrab.app/reset-password.php`
2. Verifica los logs de error del servidor (generalmente en cPanel → Error Log)
3. Prueba el método temporal (editar código directamente) para confirmar que el resto funciona
4. Contacta a tu proveedor de hosting para verificar cómo configuran variables de entorno en su plataforma
