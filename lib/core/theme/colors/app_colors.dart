import 'package:flutter/material.dart';

/// Bimir Lock's brand colours. The seed is the crimson end of the logo; the
/// whole Material 3 light and dark scheme is generated from it.
///
/// `seed` drives the entire Material 3 [ColorScheme] (via [BrandPalette] in
/// `theme_config.dart`). `accent` is harmonized to the seed and surfaced
/// through [CustomThemeExtension] for places where Material's `ColorScheme`
/// roles aren't enough.
class AppColors {
  AppColors._();

  /// Primary brand colour: seeds the Material 3 tonal palette.
  static const Color seed = Color(0xFFB0325A);

  /// Accent (same crimson), surfaced as `brandAccent` for untagged notes.
  static const Color accent = Color(0xFFB0325A);

  /// Warm "fire" accent (deep orange) — used for the reminders feature so the
  /// three brand colours (blue · green · fire) read distinctly. Surfaced
  /// through `CustomThemeExtension.fire`.
  static const Color fire = Color(0xFFF4511E);
}

class AppFonts {
  AppFonts._();

  /// Google Sans Flex, bundled under the SIL Open Font License.
  static const String sans = 'GoogleSans';

  /// Revealed passwords only.
  static const String mono = 'JetBrainsMono';
}
