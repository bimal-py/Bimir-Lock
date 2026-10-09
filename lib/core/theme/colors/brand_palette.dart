import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Reusable Material 3 brand palette generator.
///
/// Drop this file into any Flutter project — it has no app-specific imports.
/// Built directly on `material_color_utilities` (the package that powers
/// `ColorScheme.fromSeed`) so callers can reach individual tones, harmonize
/// secondary brand colors to the seed, and pick a [Variant] (default
/// `tonalSpot`).
///
/// Usage:
///
/// ```dart
/// final brand = BrandPalette(
///   seed: const Color(0xFF1B3A6B),
///   accent: const Color(0xFFC8A96B), // optional, harmonized to seed
/// );
///
/// MaterialApp(
///   theme: ThemeData.from(colorScheme: brand.light),
///   darkTheme: ThemeData.from(colorScheme: brand.dark),
/// );
///
/// // Pull a specific tone:
/// final navyTone20 = brand.primaryTone(20, brightness: Brightness.light);
///
/// // Harmonize an arbitrary accent to your seed:
/// final harmonized = brand.harmonized(const Color(0xFFC8A96B));
/// ```
class BrandPalette {
  BrandPalette({
    required this.seed,
    this.accent,
    this.contrastLevel = 0.0,
    this.variant = DynamicSchemeVariant.tonalSpot,
  });

  /// The brand's primary color. Drives every role in the generated scheme.
  final Color seed;

  /// Optional secondary brand color (e.g. a warm gold accent). When read
  /// through [harmonizedAccent], it is shifted up to 15° in hue toward [seed]
  /// so the two read as belonging to the same family.
  final Color? accent;

  /// Material 3 contrast knob. `0.0` = standard, `0.5` = medium, `1.0` = high.
  /// Negative values lower contrast.
  final double contrastLevel;

  /// Dynamic-scheme variant (TonalSpot is the default Material 3 look).
  final DynamicSchemeVariant variant;

  late final Hct _seedHct = Hct.fromInt(_argb(seed));
  late final DynamicScheme _light = _buildScheme(isDark: false);
  late final DynamicScheme _dark = _buildScheme(isDark: true);

  /// Material 3 [ColorScheme] for `Brightness.light`.
  ColorScheme get light => _toColorScheme(_light, Brightness.light);

  /// Material 3 [ColorScheme] for `Brightness.dark`.
  ColorScheme get dark => _toColorScheme(_dark, Brightness.dark);

  /// Underlying [DynamicScheme] for `Brightness.light` — exposes
  /// `primaryPalette`, `secondaryPalette`, etc. for raw tonal access.
  DynamicScheme get lightScheme => _light;

  /// Underlying [DynamicScheme] for `Brightness.dark`.
  DynamicScheme get darkScheme => _dark;

  /// [accent] shifted up to 15° in hue toward [seed]. Returns null when no
  /// [accent] was provided.
  Color? get harmonizedAccent {
    final a = accent;
    if (a == null) return null;
    return harmonized(a);
  }

  /// Harmonize any color toward [seed] — useful for status colors, tags, etc.
  Color harmonized(Color color) =>
      Color(Blend.harmonize(_argb(color), _argb(seed)));

  /// Pull a specific tone (0–100) from the primary palette.
  /// Useful for halos, glows, or off-grid surface tints.
  Color primaryTone(int tone, {required Brightness brightness}) {
    final scheme = brightness == Brightness.dark ? _dark : _light;
    return Color(scheme.primaryPalette.get(tone));
  }

  /// Pull a specific tone from the neutral palette (used for surfaces).
  Color neutralTone(int tone, {required Brightness brightness}) {
    final scheme = brightness == Brightness.dark ? _dark : _light;
    return Color(scheme.neutralPalette.get(tone));
  }

  DynamicScheme _buildScheme({required bool isDark}) {
    return switch (variant) {
      DynamicSchemeVariant.tonalSpot => SchemeTonalSpot(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.content => SchemeContent(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.vibrant => SchemeVibrant(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.expressive => SchemeExpressive(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.fidelity => SchemeFidelity(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.neutral => SchemeNeutral(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
      DynamicSchemeVariant.monochrome => SchemeMonochrome(
        sourceColorHct: _seedHct,
        isDark: isDark,
        contrastLevel: contrastLevel,
      ),
    };
  }

  static ColorScheme _toColorScheme(DynamicScheme s, Brightness b) {
    Color c(DynamicColor dc) => Color(dc.getArgb(s));
    return ColorScheme(
      brightness: b,
      primary: c(MaterialDynamicColors.primary),
      onPrimary: c(MaterialDynamicColors.onPrimary),
      primaryContainer: c(MaterialDynamicColors.primaryContainer),
      onPrimaryContainer: c(MaterialDynamicColors.onPrimaryContainer),
      secondary: c(MaterialDynamicColors.secondary),
      onSecondary: c(MaterialDynamicColors.onSecondary),
      secondaryContainer: c(MaterialDynamicColors.secondaryContainer),
      onSecondaryContainer: c(MaterialDynamicColors.onSecondaryContainer),
      tertiary: c(MaterialDynamicColors.tertiary),
      onTertiary: c(MaterialDynamicColors.onTertiary),
      tertiaryContainer: c(MaterialDynamicColors.tertiaryContainer),
      onTertiaryContainer: c(MaterialDynamicColors.onTertiaryContainer),
      error: c(MaterialDynamicColors.error),
      onError: c(MaterialDynamicColors.onError),
      errorContainer: c(MaterialDynamicColors.errorContainer),
      onErrorContainer: c(MaterialDynamicColors.onErrorContainer),
      surface: c(MaterialDynamicColors.surface),
      onSurface: c(MaterialDynamicColors.onSurface),
      surfaceContainerLowest: c(MaterialDynamicColors.surfaceContainerLowest),
      surfaceContainerLow: c(MaterialDynamicColors.surfaceContainerLow),
      surfaceContainer: c(MaterialDynamicColors.surfaceContainer),
      surfaceContainerHigh: c(MaterialDynamicColors.surfaceContainerHigh),
      surfaceContainerHighest: c(MaterialDynamicColors.surfaceContainerHighest),
      surfaceDim: c(MaterialDynamicColors.surfaceDim),
      surfaceBright: c(MaterialDynamicColors.surfaceBright),
      onSurfaceVariant: c(MaterialDynamicColors.onSurfaceVariant),
      outline: c(MaterialDynamicColors.outline),
      outlineVariant: c(MaterialDynamicColors.outlineVariant),
      shadow: c(MaterialDynamicColors.shadow),
      scrim: c(MaterialDynamicColors.scrim),
      inverseSurface: c(MaterialDynamicColors.inverseSurface),
      onInverseSurface: c(MaterialDynamicColors.inverseOnSurface),
      inversePrimary: c(MaterialDynamicColors.inversePrimary),
      surfaceTint: c(MaterialDynamicColors.primary),
    );
  }

  static int _argb(Color color) {
    // `Color.toARGB32()` is the modern API (Flutter ≥ 3.27).
    // The fallback to `.value` keeps this helper portable to older SDKs.
    try {
      return color.toARGB32();
    } catch (_) {
      // ignore: deprecated_member_use
      return color.value;
    }
  }
}

/// Material 3 dynamic-scheme variants, mapped to subclasses inside
/// `material_color_utilities`. `tonalSpot` matches `ColorScheme.fromSeed`.
enum DynamicSchemeVariant {
  tonalSpot,
  content,
  vibrant,
  expressive,
  fidelity,
  neutral,
  monochrome,
}
