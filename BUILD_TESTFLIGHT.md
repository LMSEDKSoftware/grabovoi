# Guía para Generar Build para TestFlight

## Pasos para Generar el Archivo .ipa

### Opción 1: Usando Xcode (RECOMENDADO)

1. **Abrir el proyecto en Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configurar el esquema:**
   - Selecciona el esquema "Runner"
   - Selecciona "Any iOS Device" o un dispositivo específico

3. **Configurar la versión y build:**
   - Ve a Runner > General > Identity
   - Verifica que "Version" y "Build" estén correctos
   - Estos valores vienen de `pubspec.yaml`

4. **Configurar Signing & Capabilities:**
   - Ve a Runner > Signing & Capabilities
   - Selecciona tu equipo de desarrollo
   - Verifica que el Bundle Identifier sea correcto
   - Asegúrate de que "Automatically manage signing" esté activado

5. **Generar el Archive:**
   - En el menú: Product > Archive
   - Espera a que termine la compilación
   - Se abrirá el Organizer

6. **Distribuir la App:**
   - En el Organizer, selecciona tu archive
   - Click en "Distribute App"
   - Selecciona "App Store Connect"
   - Sigue el asistente
   - Selecciona "Upload" (no "Export")
   - Esto subirá directamente a App Store Connect

### Opción 2: Usando Flutter Build + Xcode

1. **Generar el build de Flutter:**
   ```bash
   flutter build ipa --release
   ```

2. **El archivo .ipa estará en:**
   ```
   build/ios/ipa/*.ipa
   ```

3. **Subir a App Store Connect:**
   - Abre Transporter (desde Mac App Store) o usa Xcode Organizer
   - Arrastra el archivo .ipa
   - Sigue las instrucciones

### Opción 3: Usando fastlane (si está configurado)

```bash
fastlane ios beta
```

## Verificar Antes de Subir

- [ ] Versión y build number correctos en `pubspec.yaml`
- [ ] Bundle Identifier correcto
- [ ] Certificados de distribución válidos
- [ ] Provisioning profiles actualizados
- [ ] Info.plist con todas las descripciones de permisos
- [ ] Iconos de la app configurados
- [ ] Build compila sin errores

## Después de Subir a TestFlight

1. Ve a [App Store Connect](https://appstoreconnect.apple.com)
2. Selecciona tu app
3. Ve a TestFlight
4. Espera a que el procesamiento termine (10-30 minutos)
5. Agrega información de prueba si es necesario
6. Invita a testers o usa TestFlight Internal Testing

## Notas Importantes

- El build debe ser en modo Release
- Asegúrate de que todos los cambios estén commiteados
- Verifica que no haya errores de compilación
- El procesamiento en App Store Connect puede tardar
