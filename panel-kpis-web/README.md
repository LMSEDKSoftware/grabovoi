# Panel de KPIs ManiGrab (versión web estática)

Panel de control con todos los KPIs en una sola página, agrupados por secciones. **No requiere Node, Angular ni ningún framework**: solo HTML estático. Puedes subirlo a tu VPS con Ubuntu 20.04 y servirlo con nginx o Apache.

## Contenido

- **index.html** — Una única página con todas las secciones:
  1. Resumen ejecutivo (DAU/MAU, suscripciones, MRR, tasa cancelación, alertas)
  2. Engagement (tiempo en app, sesiones, repeticiones, top códigos y favoritos)
  3. Suscripciones e ingresos (MRR, ARR, distribución, embudo conversión)
  4. Calidad de contenido e IA (éxito búsqueda IA, latencia, costo, sugerencias, reportes)
  5. Desafíos (iniciados, completados, tasa finalización)
  6. Recompensas (cristales, luz cuántica, canjes)
  7. Diario y evaluación

Con **config.js** y la Edge Function **dashboard-stats** desplegada en Supabase, el panel muestra **datos en vivo**. Si falta la config o falla la conexión, se muestra modo demo (ceros) y un mensaje en el pie de página.

## Datos reales desde Supabase

1. **Despliega la Edge Function** `dashboard-stats` en tu proyecto Supabase (está en `supabase/functions/dashboard-stats/`). Desde la raíz del repo:
   ```bash
   npx supabase functions deploy dashboard-stats
   ```
   Asegúrate de tener configuradas las variables de entorno del proyecto (Supabase usa `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` en el entorno de la función).

2. **Crea `config.js`** en esta carpeta (`panel-kpis-web/`):
   ```bash
   cp config.example.js config.js
   ```
   Edita `config.js` y rellena con tu proyecto:
   - `window.SUPABASE_URL`: URL del proyecto (ej. `https://xxxx.supabase.co`)
   - `window.SUPABASE_ANON_KEY`: clave anónima (pública) del proyecto, desde el dashboard de Supabase → Settings → API.

3. **Sube la carpeta** al servidor incluyendo `config.js`. No subas `config.js` a un repo público (añádelo a `.gitignore` si usas git).

Al abrir el panel, si la conexión a la función `dashboard-stats` es correcta, verás en el pie de página: *"Datos en vivo desde Supabase. Última actualización: …"*. Si algo falla, se mostrará modo demo y un mensaje de error orientativo.

## Colores del proyecto

- Fondo: `#0B132B`
- Tarjetas: `#1C2541`
- Acento: `#FFD700` (dorado)
- Éxito: `#4CAF50`
- Alerta: `#FF6B6B`

## Cómo subir y usar en tu VPS (Ubuntu 20.04)

### Opción 1: Subir solo el archivo y servir con nginx

1. **En tu máquina local** (donde está el proyecto), sube la carpeta al VPS:

   ```bash
   scp -r panel-kpis-web usuario@tu-servidor-ip:/var/www/
   ```

   O solo el HTML si prefieres:

   ```bash
   scp panel-kpis-web/index.html usuario@tu-servidor-ip:/var/www/panel-kpis/
   ```

2. **En el VPS**, si usas nginx, crea un sitio (o ajusta el existente):

   ```bash
   sudo nano /etc/nginx/sites-available/panel-manigrab
   ```

   Contenido mínimo:

   ```nginx
   server {
       listen 80;
       server_name tu-dominio-o-ip;
       root /var/www/panel-kpis-web;
       index index.html;
       location / {
           try_files $uri $uri/ /index.html;
       }
   }
   ```

   Activa el sitio y recarga nginx:

   ```bash
   sudo ln -s /etc/nginx/sites-available/panel-manigrab /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

3. Abre en el navegador: `http://tu-servidor-ip` o `http://tu-dominio`.

### Opción 2: Apache

1. Sube la carpeta igual que antes a `/var/www/panel-kpis-web`.

2. Crea un virtual host:

   ```bash
   sudo nano /etc/apache2/sites-available/panel-manigrab.conf
   ```

   ```apache
   <VirtualHost *:80>
       ServerName tu-dominio-o-ip
       DocumentRoot /var/www/panel-kpis-web
       <Directory /var/www/panel-kpis-web>
           AllowOverride None
           Require all granted
           DirectoryIndex index.html
       </Directory>
   </VirtualHost>
   ```

   Activa y recarga:

   ```bash
   sudo a2ensite panel-manigrab.conf
   sudo systemctl reload apache2
   ```

### Opción 3: Probar en el VPS sin nginx/apache (rápido)

Solo para comprobar que se ve bien:

```bash
cd /var/www/panel-kpis-web
python3 -m http.server 8080
```

Luego abre `http://tu-servidor-ip:8080`. No uses esto en producción.

## Requisitos

- **Nada que instalar** en el servidor aparte del servidor web que ya uses (nginx o Apache). No hace falta Node, Angular ni npm.
- El HTML usa Tailwind y fuentes de Google por CDN; el servidor solo entrega el archivo estático.

## Nota sobre la app Flutter

Este panel es **independiente** del proyecto Flutter. No modifica ni depende de la app móvil. Puedes borrar la carpeta `panel-kpis-web` sin afectar la compilación de la app.
