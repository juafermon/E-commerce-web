import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Configuración de Tema Global para Relaxbell
/// Integra:
/// - Tipografía de Títulos / Display: Playfair Display
/// - Tipografía de Lectura / UI: Plus Jakarta Sans
/// - Paleta de Colores: Marfil, Blanco, Carbón, Champagne, Cobre Oscuro, Arena, Gris Cálido
/// - Escala de Espaciado y Acabados de Bordes
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    // TextTheme personalizado que fusiona Playfair Display para títulos/display y Plus Jakarta Sans para el cuerpo
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 38,
        fontWeight: FontWeight.bold,
        color: AppColors.carbon,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: AppColors.carbon,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.carbon,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.carbon,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppColors.carbon,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.carbon,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.carbon,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.carbon,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.grisCalido,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: AppColors.carbon,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: AppColors.carbon,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        color: AppColors.grisCalido,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.marfil,
      canvasColor: AppColors.marfil,
      cardColor: AppColors.blanco,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.carbon,
        onPrimary: AppColors.blanco,
        secondary: AppColors.cobreOscuro,
        onSecondary: AppColors.blanco,
        tertiary: AppColors.champagne,
        onTertiary: AppColors.carbon,
        error: AppColors.error,
        onError: AppColors.blanco,
        surface: AppColors.blanco,
        onSurface: AppColors.carbon,
        outline: AppColors.arena,
      ),

      textTheme: textTheme,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.blanco,
        foregroundColor: AppColors.carbon,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.carbon),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.arena.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        color: AppColors.blanco,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(
            color: AppColors.arena.withValues(alpha: 0.7),
            width: 1.0,
          ),
        ),
      ),

      // ─── Botones Elevados (Carbón con texto Blanco) ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.carbon,
          foregroundColor: AppColors.blanco,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ─── Botones Outlined ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.carbon,
          side: const BorderSide(color: AppColors.arena, width: 1.2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Botones de Texto (Cobre Oscuro) ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cobreOscuro,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space3,
            vertical: AppSpacing.space2,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderSm,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Floating Action Button (Cobre Oscuro) ───
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.cobreOscuro,
        foregroundColor: AppColors.blanco,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),

      // ─── Campos de Texto / Inputs ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.grisCalido.withValues(alpha: 0.8),
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.grisCalido,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.arena, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.arena, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.cobreOscuro, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.0),
        ),
      ),

      // ─── Divisores ───
      dividerTheme: DividerThemeData(
        color: AppColors.arena.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),

      // ─── Diálogos ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.blanco,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.carbon,
        ),
      ),
    );
  }
}
