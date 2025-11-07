# Mantener clases esenciales de Flutter y plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.play.**

# Evitar eliminar serializers generados
-keep class **.model.** { *; }
-keep class **.dto.** { *; }

# Supabase y PostgREST
-keep class io.supabase.** { *; }
-keep class io.postgrest.** { *; }

# Mantener anotaciones
-keepattributes *Annotation*
