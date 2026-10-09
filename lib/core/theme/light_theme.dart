import 'package:flutter/material.dart';
import 'package:flutter_scale_kit/flutter_scale_kit.dart';
import 'package:bimir_lock/core/theme/colors/app_colors.dart';
import 'package:bimir_lock/core/theme/colors/brand_palette.dart' as bp show BrandPalette, DynamicSchemeVariant;
import 'package:bimir_lock/core/theme/component_themes/component_themes.dart';
import 'package:bimir_lock/core/theme/extension/custom_theme_extension.dart';
import 'package:bimir_lock/core/theme/typography/app_text_style.dart';

// Bimir Lock: "fidelity" keeps the brand crimson close to the logo instead of
// the muted mauve the default variant makes of it. Every neutral is then set
// by hand (_bimirScheme): plain cool greys with no pink in them, so the
// crimson is the only colour on screen and reads as an accent, not a tint.
bp.BrandPalette _palette() => bp.BrandPalette(
  seed: AppColors.seed,
  accent: AppColors.accent,
  variant: bp.DynamicSchemeVariant.fidelity,
);

ColorScheme _bimirScheme(ColorScheme s) {
  if (s.brightness == Brightness.dark) {
    // Charcoal, not black: easier on the eyes in the dark, and cards, fields
    // and keys each sit a visible step above the page. Text is off-white,
    // not pure white, so it does not glare.
    return s.copyWith(
      // Crimson, not pink: lightening the logo's hue (338°) for a dark page
      // drifts to pink, so this one leans red (349°, crimson's own). White
      // text on it 4.8:1, 3.4:1 as text on the page.
      primary: const Color(0xFFCC3D58),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFF4A1A26),
      onPrimaryContainer: const Color(0xFFFFD9DF),
      // Tonal buttons (Edit) in a raised grey: a dark tint of the crimson
      // reads as brown.
      secondaryContainer: const Color(0xFF34353B),
      onSecondaryContainer: const Color(0xFFECECEF),
      // The generated dark error is a pale salmon that clashes with the
      // crimson and turns warning boxes mauve-brown; a clear red instead.
      error: const Color(0xFFE5484D),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFF4E1C1E),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: const Color(0xFF1E1F23),
      surfaceDim: const Color(0xFF1E1F23),
      surfaceBright: const Color(0xFF3E3F45),
      surfaceContainerLowest: const Color(0xFF18191C),
      surfaceContainerLow: const Color(0xFF26272C),
      surfaceContainer: const Color(0xFF2A2B30),
      surfaceContainerHigh: const Color(0xFF303137),
      surfaceContainerHighest: const Color(0xFF393A40),
      onSurface: const Color(0xFFE4E4E8),
      onSurfaceVariant: const Color(0xFFAEAFB7),
      outline: const Color(0xFF8A8B93),
      outlineVariant: const Color(0xFF3A3B41),
      inverseSurface: const Color(0xFFE4E4E8),
      onInverseSurface: const Color(0xFF1E1F23),
      inversePrimary: const Color(0xFF901743),
      surfaceTint: Colors.transparent,
    );
  }
  return s.copyWith(
    // primary stays the generated #901743: the crimson as it is.
    primaryContainer: const Color(0xFFFBE7ED),
    onPrimaryContainer: const Color(0xFF6B1131),
    secondaryContainer: const Color(0xFFF6E6EB),
    onSecondaryContainer: const Color(0xFF5E2C3B),
    // Cards are white on a light grey page, as in Google's own apps.
    surface: const Color(0xFFF6F6F8),
    surfaceDim: const Color(0xFFDCDCE1),
    surfaceBright: const Color(0xFFFFFFFF),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFFFFFFF),
    surfaceContainer: const Color(0xFFF1F1F4),
    surfaceContainerHigh: const Color(0xFFEBEBEF),
    surfaceContainerHighest: const Color(0xFFE3E3E8),
    onSurface: const Color(0xFF19191D),
    onSurfaceVariant: const Color(0xFF5D5D66),
    outline: const Color(0xFF8B8B94),
    outlineVariant: const Color(0xFFE0E0E6),
    inverseSurface: const Color(0xFF2A2A2F),
    onInverseSurface: const Color(0xFFF2F2F5),
    surfaceTint: Colors.transparent,
  );
}

ThemeData buildLightTheme(BuildContext context) {
  final palette = _palette();
  return _buildTheme(
    context: context,
    colorScheme: _bimirScheme(palette.light),
    extension: CustomThemeExtension.fromPalette(
      palette,
      brightness: Brightness.light,
    ),
  );
}

ThemeData buildDarkTheme(BuildContext context) {
  final palette = _palette();
  return _buildTheme(
    context: context,
    colorScheme: _bimirScheme(palette.dark),
    extension: CustomThemeExtension.fromPalette(
      palette,
      brightness: Brightness.dark,
    ),
  );
}

ThemeData _buildTheme({
  required BuildContext context,
  required ColorScheme colorScheme,
  required CustomThemeExtension extension,
}) {
  // Build a base ThemeData WITHOUT a custom textTheme. This lets Material 3
  // bake the proper colorScheme-aware colors into the typography.
  // We then layer our font sizes on top, preserving those colors.
  final base = ResponsiveThemeData.create(
    context: context,
    useMaterial3: true,
    colorScheme: colorScheme,
  );
  final textTheme = AppTextStyle.applyTo(
    base.textTheme,
  ).apply(fontFamily: AppFonts.sans);
  final radius = BorderRadius.circular(12.r);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.surface,
    iconTheme: IconThemeData(size: 20.r, color: colorScheme.onSurface),
    appBarTheme: AppBarThemeBuilder.build(
      colorScheme: colorScheme,
      textTheme: textTheme,
    ),
    elevatedButtonTheme: ButtonThemes.elevated(
      colorScheme: colorScheme,
      textTheme: textTheme,
      radius: radius,
    ),
    filledButtonTheme: ButtonThemes.filled(
      colorScheme: colorScheme,
      textTheme: textTheme,
      radius: radius,
    ),
    outlinedButtonTheme: ButtonThemes.outlined(
      colorScheme: colorScheme,
      textTheme: textTheme,
      radius: radius,
    ),
    textButtonTheme: ButtonThemes.text(textTheme: textTheme),
    inputDecorationTheme: InputDecorationThemeBuilder.build(
      colorScheme: colorScheme,
      textTheme: textTheme,
      radius: radius,
    ),
    cardTheme: CardThemeBuilder.build(colorScheme: colorScheme),
    dialogTheme: DialogThemeBuilder.build(
      colorScheme: colorScheme,
      textTheme: textTheme,
    ),
    dividerTheme: DividerThemeBuilder.build(colorScheme: colorScheme),
    navigationBarTheme: NavigationBarThemeBuilder.build(
      colorScheme: colorScheme,
      textTheme: textTheme,
    ),
    snackBarTheme: SnackBarThemeBuilder.build(
      colorScheme: colorScheme,
      textTheme: textTheme,
      radius: radius,
    ),
    extensions: [extension],
  );
}
