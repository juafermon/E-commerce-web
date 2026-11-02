import 'package:flutter/material.dart';

/// Paleta de colores y tokens de diseño para Relaxbell
/// Sistema visual de lujo y bienestar:
/// - Fondo General: Marfil #F7F4EF
/// - Superficies: Blanco #FFFFFF
/// - Texto y botones: Carbón #211F1C
/// - Acentos sutiles: Champagne #B49A78
/// - Acentos de acción: Cobre Oscuro #A46F4E
/// - Detalles decorativos: Arena #D7C7B7
/// - Texto secundario: Gris cálido #77716A
class AppColors {
  // ─── Paleta Central Oficial ───
  static const Color marfil = Color(0xFFF7F4EF);       // Fondo General
  static const Color blanco = Color(0xFFFFFFFF);       // Superficies
  static const Color carbon = Color(0xFF211F1C);       // Texto y botones principales
  static const Color champagne = Color(0xFFB49A78);    // Acentos sutiles
  static const Color cobreOscuro = Color(0xFFA46F4E);  // Acentos de acción / CTAs
  static const Color arena = Color(0xFFD7C7B7);        // Detalles decorativos & bordes
  static const Color grisCalido = Color(0xFF77716A);   // Texto secundario

  // ─── Compatibilidad semántica y alias de uso ───
  static const Color background = marfil;
  static const Color surface = blanco;
  static const Color primaryText = carbon;
  static const Color secondaryText = grisCalido;
  static const Color border = arena;
  static const Color subtleAccent = champagne;
  static const Color actionAccent = cobreOscuro;

  // ─── Estados & Badges refinados ───
  static const Color discountBadge = cobreOscuro;
  static const Color discountBadgeBg = Color(0xFFF6EDE6);
  static const Color success = Color(0xFF2D6A4F);
  static const Color successBg = Color(0xFFE8F3ED);
  static const Color warning = Color(0xFFC07A24);
  static const Color warningBg = Color(0xFFFDF3E6);
  static const Color error = Color(0xFFBA3C3C);
  static const Color errorBg = Color(0xFFFBECEC);

  // ─── Compatibilidad con código previo ───
  static const Color primary = cobreOscuro;
  static const Color primaryLight = Color(0xFFF4ECE4);
  static const Color primaryDark = carbon;
  static const Color neutral900 = carbon;
  static const Color neutral800 = Color(0xFF35322E);
  static const Color neutral700 = Color(0xFF4C4742);
  static const Color neutral600 = grisCalido;
  static const Color neutral500 = Color(0xFF8F8982);
  static const Color neutral400 = Color(0xFFAAA49D);
  static const Color neutral300 = arena;
  static const Color neutral200 = Color(0xFFEBE5DC);
  static const Color neutral100 = Color(0xFFF4F0EA);
  static const Color neutral50 = marfil;
  static const Color white = blanco;
}

/// Escala de espaciado estandarizada
/// --space-1: 4px;
/// --space-2: 8px;
/// --space-3: 12px;
/// --space-4: 16px;
/// --space-6: 24px;
/// --space-8: 32px;
/// --space-12: 48px;
/// --space-16: 64px;
class AppSpacing {
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
}

/// Acabados y radios estandarizados
/// --radius-sm: 4px;
/// --radius-md: 8px;
/// --transition: 200ms ease;
class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double pill = 999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

/// Transiciones estandarizadas
class AppTransitions {
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.ease;
}
