# 🔧 Solución: Error en Callback de Activación

## Problema

El link de activación `https://manigrab.app/auth/callback` da error al hacer clic.

## Posibles Causas

### 1. La aplicación Flutter Web no está desplegada en manigrab.app

**Solución:** Desplegar la aplicación Flutter Web en `https://manigrab.app`

### 2. El servidor web no está configurado para SPA routing

**Solución:** Configurar el servidor web (Apache/Nginx) para que todas las rutas sirvan `index.html` (SPA routing)

#### Para Apache (.htaccess):
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

#### Para Nginx:
```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

### 3. El link generado no tiene los parámetros correctos

El link debería tener esta forma:
```
https://manigrab.app/auth/callback?token=xxx&type=signup
```

O:
```
https://manigrab.app/auth/callback?access_token=xxx&type=signup
```

### 4. La URL no está en la lista de Redirect URLs de Supabase

**Solución:** Agregar en Supabase Dashboard → Authentication → URL Configuration:
- `https://manigrab.app/auth/callback`

## Verificación

1. **Revisa el link en el email:**
   - Debe tener parámetros `token` o `access_token`
   - Debe apuntar a `https://manigrab.app/auth/callback?...`

2. **Revisa los logs de Supabase:**
   - Verifica que el link se generó correctamente
   - Busca: "✅ Link de confirmación generado:"

3. **Revisa la configuración del servidor web:**
   - Debe servir `index.html` para todas las rutas
   - La ruta `/auth/callback` debe ser manejada por Flutter

## Solución Temporal

Si la app no está desplegada en producción, puedes:
1. Usar el link de Supabase directamente (sin pasar por tu dominio)
2. O configurar un redirect en el servidor web que redirija a la app Flutter


