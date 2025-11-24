# 🔧 Solución al Error 401 al Insertar Códigos

## ✅ Lo que ya está arreglado automáticamente:

1. **Detección de errores:** La app ahora detecta cuando falta la clave de servicio
2. **Fallback automático:** Intenta múltiples métodos antes de fallar
3. **Mensajes claros:** Los errores ahora son más fáciles de entender

## 🎯 ¿Qué debes hacer?

### Opción 1: Solo probar (RECOMENDADO)
**No necesitas hacer nada ahora.** Solo:
1. Prueba la app normalmente
2. Si encuentras un código nuevo con la IA, selecciónalo
3. Debería guardarse sin problemas

**Si aún aparece el error 401**, entonces necesitas la Service Role Key (Opción 2).

---

### Opción 2: Si sigue dando error 401

Necesitas agregar la **Service Role Key** de Supabase al generar el APK.

#### Paso 1: Obtener la Service Role Key
1. Ve a https://app.supabase.com
2. Selecciona tu proyecto (whtiazgcxdnemrrgjjqf)
3. Ve a **Settings** → **API**
4. Busca la sección **"Project API keys"**
5. Copia la clave **"service_role"** (⚠️ Es secreta, no la compartas)

#### Paso 2: Generar APK con la clave

**Opción A: Usar el script automático (FÁCIL)**
```bash
# 1. Edita BUILD_APK.sh
# 2. Reemplaza "TU_SERVICE_ROLE_KEY_AQUI" con tu clave real
# 3. Ejecuta:
./BUILD_APK.sh
```

**Opción B: Comando manual**
```bash
flutter build apk --release \
  --dart-define=OPENAI_API_KEY="tu_openai_key" \
  --dart-define=SUPABASE_URL="https://whtiazgcxdnemrrgjjqf.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="tu_anon_key" \
  --dart-define=SB_SERVICE_ROLE_KEY="tu_service_role_key_aqui"
```

---

## 📝 Resumen

- **Si funciona ahora:** ✅ No hagas nada, todo está bien
- **Si aún da error 401:** Necesitas agregar `SB_SERVICE_ROLE_KEY` al compilar el APK

La app ahora es **más inteligente** y intenta varias formas de guardar códigos antes de fallar.

