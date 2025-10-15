import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores místicos oscuros
  static const Color primaryColor = Color(0xFF8B5CF6); // Púrpura místico
  static const Color secondaryColor = Color(0xFF06B6D4); // Cian brillante
  static const Color accentColor = Color(0xFFF59E0B); // Dorado
  static const Color backgroundColor = Color(0xFF0F0F23); // Azul muy oscuro
  static const Color surfaceColor = Color(0xFF1A1A2E); // Azul oscuro
  static const Color cardColor = Color(0xFF16213E); // Azul grisáceo
  static const Color textColor = Color(0xFFE2E8F0); // Blanco suave
  static const Color textSecondaryColor = Color(0xFF94A3B8); // Gris claro
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);

  // Colores para categorías místicas
  static const Map<String, Color> categoryColors = {
    'salud': Color(0xFF10B981), // Verde esmeralda
    'abundancia': Color(0xFFF59E0B), // Dorado
    'relaciones': Color(0xFFEC4899), // Rosa vibrante
    'crecimiento_personal': Color(0xFF8B5CF6), // Púrpura
    'proteccion': Color(0xFFEF4444), // Rojo intenso
    'armonia': Color(0xFF06B6D4), // Cian
  };

  static ThemeData lightTheme(Color? accentColor) {
    final primary = accentColor ?? primaryColor;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Forzar tema oscuro místico
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _buildMysticalTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: GoogleFonts.spaceMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        color: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.spaceMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  static ThemeData darkTheme(Color? accentColor) {
    return lightTheme(accentColor); // Usar el mismo tema místico
  }

  static TextTheme _buildMysticalTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.spaceMono(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: GoogleFonts.spaceMono(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: GoogleFonts.spaceMono(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.spaceMono(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.spaceMono(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.spaceMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.spaceMono(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.spaceMono(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      labelLarge: GoogleFonts.spaceMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }
}