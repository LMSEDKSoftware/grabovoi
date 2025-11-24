# 📚 Guía de Git - Manifestación Numérica Grabovoi

## 🎯 Estado Actual

✅ **Repositorio Git inicializado**
✅ **Commit inicial realizado:** v1.0.0 con APK funcional
✅ **Tag creado:** `v1.0.0` (versión estable)
✅ **Branch actual:** `desarrollo` (para experimentar)

---

## 🌳 Estructura de Branches

```
master (estable)
  └─ v1.0.0 [tag]
  
desarrollo (experimentación)
  └─ [aquí haces tus cambios]
```

---

## 🚀 Flujo de Trabajo Recomendado

### 1️⃣ Trabajar en Desarrollo (actual)

Ahora estás en el branch `desarrollo`. Puedes hacer todos los cambios que quieras sin miedo:

```bash
# Ver en qué branch estás
git branch

# Hacer cambios a tus archivos...
# Editar código, probar, experimentar, etc.

# Ver qué archivos cambiaron
git status

# Agregar cambios
git add .

# Hacer commit con un mensaje descriptivo
git commit -m "feat: Nuevo diseño de home screen"
```

### 2️⃣ Guardar Versiones Incrementales

Cada vez que tengas algo funcionando, haz un commit:

```bash
# Después de hacer cambios
git add .
git commit -m "fix: Corregido color del botón principal"

# O commit de una característica completa
git commit -m "feat: Agregado modo nocturno automático"
```

### 3️⃣ Ver Historial de Cambios

```bash
# Ver todos los commits
git log --oneline

# Ver cambios detallados
git log --graph --all --oneline --decorate
```

### 4️⃣ Volver a Versión Estable (si algo sale mal)

Si experimentaste y algo salió mal, puedes volver a la versión estable:

```bash
# Opción A: Descartar TODOS los cambios no guardados
git checkout .

# Opción B: Volver al último commit del branch actual
git reset --hard HEAD

# Opción C: Volver completamente a v1.0.0
git checkout master
# Y si quieres empezar de nuevo en desarrollo:
git branch -D desarrollo
git checkout -b desarrollo
```

### 5️⃣ Cuando Termines una Nueva Versión

Cuando tengas una nueva versión lista y compilada:

```bash
# 1. Asegúrate de estar en desarrollo con todos los cambios guardados
git add .
git commit -m "feat: Nueva versión v1.1.0 lista"

# 2. Cambia a master
git checkout master

# 3. Fusiona los cambios de desarrollo
git merge desarrollo

# 4. Crea un nuevo tag
git tag -a v1.1.0 -m "Versión 1.1.0 - Nuevo diseño y características"

# 5. Vuelve a desarrollo para seguir experimentando
git checkout desarrollo
```

---

## 📋 Comandos Útiles del Día a Día

### Ver Estado
```bash
# ¿En qué branch estoy? ¿Qué cambios tengo?
git status

# ¿Qué branches existen?
git branch -a

# ¿Qué tags (versiones) existen?
git tag -l
```

### Cambiar de Branch
```bash
# Ir a master (versión estable)
git checkout master

# Ir a desarrollo
git checkout desarrollo

# Crear un nuevo branch para una característica específica
git checkout -b feature/nueva-pantalla
```

### Ver Diferencias
```bash
# Ver qué cambió en los archivos
git diff

# Ver diferencias de un archivo específico
git diff lib/main.dart

# Ver diferencias entre branches
git diff master..desarrollo
```

### Restaurar Archivos
```bash
# Descartar cambios de UN archivo específico
git checkout -- lib/config/theme.dart

# Descartar TODOS los cambios no guardados
git checkout .
```

---

## 🏷️ Convenciones para Mensajes de Commit

Usa estos prefijos para mantener el historial organizado:

- `feat:` Nueva característica
  - Ejemplo: `git commit -m "feat: Agregado modo oscuro automático"`

- `fix:` Corrección de error
  - Ejemplo: `git commit -m "fix: Corregido crash al abrir códigos"`

- `style:` Cambios visuales (colores, fuentes, etc.)
  - Ejemplo: `git commit -m "style: Actualizado tema a colores más vibrantes"`

- `refactor:` Reorganización de código
  - Ejemplo: `git commit -m "refactor: Reorganizada estructura de providers"`

- `docs:` Documentación
  - Ejemplo: `git commit -m "docs: Actualizado README con nuevas instrucciones"`

- `perf:` Mejoras de performance
  - Ejemplo: `git commit -m "perf: Optimizada carga de imágenes"`

---

## 🆘 Comandos de Emergencia

### "¡Cometí un error en el último commit!"
```bash
# Deshacer el último commit pero mantener los cambios
git reset --soft HEAD~1

# Deshacer el último commit y perder los cambios
git reset --hard HEAD~1
```

### "¡Quiero volver a v1.0.0 exactamente como estaba!"
```bash
git checkout v1.0.0
# Para quedarte ahí y hacer cambios:
git checkout -b desde-v1.0.0
```

### "¡Quiero ver cómo estaba un archivo en v1.0.0!"
```bash
git show v1.0.0:lib/main.dart
```

### "¡Borré algo importante y no hice commit!"
```bash
# Si ya hiciste 'git add' antes:
git stash list  # Ver cambios guardados temporalmente
git stash apply # Recuperar últimos cambios
```

---

## 📊 Ver Log Bonito

```bash
# Log compacto con gráfico
git log --graph --oneline --all --decorate

# Log detallado de últimos 5 commits
git log -5 --pretty=format:"%h - %an, %ar : %s"

# Ver cambios de un archivo específico
git log --follow lib/main.dart
```

---

## 💡 Tips Pro

1. **Commits frecuentes:** Haz commits pequeños y frecuentes. Es mejor tener 10 commits pequeños que 1 grande.

2. **Branch por característica:** Para cambios grandes, crea un branch específico:
   ```bash
   git checkout -b feature/nuevo-sistema-notificaciones
   ```

3. **Guarda tu trabajo temporal:** Si necesitas cambiar de branch pero no quieres hacer commit:
   ```bash
   git stash        # Guardar cambios temporalmente
   git stash pop    # Recuperarlos después
   ```

4. **Compara antes de fusionar:**
   ```bash
   git diff master..desarrollo
   ```

---

## 🎮 Ejemplo de Sesión de Trabajo

```bash
# 1. Empiezas el día
cd /Users/ifernandez/Desktop/grabovoi_build
git status  # Ver dónde estás

# 2. Haces cambios en varios archivos...
# ... editando código ...

# 3. Ves qué cambiaste
git status
git diff

# 4. Guardas los cambios
git add .
git commit -m "feat: Agregado sistema de favoritos mejorado"

# 5. Sigues trabajando y guardando
# ... más cambios ...
git add .
git commit -m "style: Nuevos colores para cards"

# 6. Al final del día, ves tu progreso
git log --oneline

# 7. Compilas APK para probar
flutter build apk --release

# 8. Si todo funciona, puedes crear un tag
git tag -a v1.0.1 -m "Mejoras visuales"
```

---

## ✅ Checklist Antes de Fusionar a Master

Antes de hacer `git merge` a master, verifica:

- [ ] ✅ APK compila correctamente
- [ ] ✅ App funciona sin crashes
- [ ] ✅ Todas las pantallas se ven bien
- [ ] ✅ Commits tienen mensajes descriptivos
- [ ] ✅ README y VERSION.md actualizados

---

## 📞 Ayuda Rápida

```bash
git status          # ¿Dónde estoy? ¿Qué cambió?
git branch          # ¿Qué branches tengo?
git log --oneline   # ¿Qué commits tengo?
git diff            # ¿Qué modificé?
git checkout .      # ¡Deshacer todo!
git checkout master # Volver a versión estable
```

---

**🎉 ¡Ahora puedes experimentar sin miedo! Tu versión v1.0.0 está segura en el tag y en el branch master.**

