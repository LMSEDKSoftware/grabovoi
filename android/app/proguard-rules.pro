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

# FileProvider para compartir archivos - REGLAS CRÍTICAS
# Mantener FileProvider sin ofuscar ni optimizar
-keep,allowobfuscation class androidx.core.content.FileProvider { *; }
-keep class androidx.core.content.** { *; }
-keepclassmembers class androidx.core.content.FileProvider { *; }
-keepclassmembers class androidx.core.content.FileProvider$* { *; }

# Mantener TODAS las clases relacionadas con parsing XML
-keep class android.content.res.** { *; }
-keep class android.content.res.XmlResourceParser { *; }
-keep class android.content.res.XmlBlock { *; }
-keep class android.content.res.XmlBlock$Parser { *; }
-keep class android.content.res.XmlBlock$** { *; }

# Mantener interfaces y clases internas de FileProvider
-keep interface androidx.core.content.** { *; }
-keep class * implements androidx.core.content.** { *; }

# Mantener métodos y campos de FileProvider
-keepclassmembers class androidx.core.content.FileProvider {
    <fields>;
    <methods>;
}

# Mantener todas las clases internas y anónimas
-keep class androidx.core.content.FileProvider$* { *; }
-keepclassmembers class androidx.core.content.FileProvider$* { *; }

# No ofuscar nombres de métodos y clases de FileProvider
-keepnames class androidx.core.content.FileProvider
-keepnames class androidx.core.content.**
-keepnames class android.content.res.**

# Mantener atributos necesarios para reflexión
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable

# share_plus plugin
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**
-dontwarn io.flutter.plugins.share.**
