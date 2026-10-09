import 'package:flutter/material.dart';

/// Canonical visual preset (CLAUDE-flutter.md rule 11b).
/// preset name: 'WARM_EARTHY'
class AppPreset {
  const AppPreset._();
  static const String name = 'WARM_EARTHY';
  static const String style = 'CLAYMORPHISM';
}

/// WARM_EARTHY palette with the brief accents applied.
class AppColors {
  const AppColors._();
  static const Color canvas = Color(0xFFFFF3D9);
  static const Color surfaceRaised = Color(0xFFFFFBF0);
  static const Color surfaceSunken = Color(0xFFF7E8C8);
  static const Color edge = Color(0xFFE3D2AE);
  static const Color primary = Color(0xFFF4C84E);
  static const Color secondary = Color(0xFFEF8248);
  static const Color success = Color(0xFF63B96A);
  static const Color successDeep = Color(0xFF2F7A3B);
  static const Color info = Color(0xFF51A4D5);
  static const Color ink = Color(0xFF302A3A);
  static const Color inkSoft = Color(0xFF7A6B6F);
  static const Color inkMuted = Color(0xFFA3969B);

  /// Loader-only tones. Deliberately the inverse of the cream menu so the
  /// pHash distance between frame 1 and frame 2 can never collapse (rule 14).
  static const Color loaderTop = Color(0xFF302A3A);
  static const Color loaderMid = Color(0xFF44364A);
  static const Color loaderBottom = Color(0xFF2A2330);

  /// Inert route stroke on a path tile.
  static const Color routeInert = Color(0xFFC8A86A);
}

/// Claymorphism elevation: a soft outer drop plus a hard top highlight.
List<BoxShadow> clayShadow({
  double blur = 24,
  double dy = 12,
  double opacity = 0.16,
}) {
  return <BoxShadow>[
    BoxShadow(
      color: AppColors.ink.withValues(alpha: opacity),
      blurRadius: blur,
      offset: Offset(0, dy),
    ),
    const BoxShadow(
      color: Color(0xE6FFFFFF),
      blurRadius: 0,
      offset: Offset(0, -2),
    ),
  ];
}

ThemeData buildAppTheme() {
  final ColorScheme seeded =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.ink,
        secondary: AppColors.secondary,
        onSecondary: AppColors.surfaceRaised,
        tertiary: AppColors.success,
        onTertiary: AppColors.surfaceRaised,
        surface: AppColors.surfaceRaised,
        onSurface: AppColors.ink,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: seeded,
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: InkRipple.splashFactory,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: 6.0,
        color: AppColors.primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.inkSoft,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: AppColors.inkSoft,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: AppColors.inkSoft,
      ),
    ),
  );
}

/// Tabular figures keep the move counter from jittering as it ticks down.
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];
