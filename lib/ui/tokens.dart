import 'package:bimir_lock/core/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Bimir Lock design tokens, on top of the Material 3 scheme the app shares
/// with the Reminder Note app (seeded with the logo's crimson). Screens use
/// these names; every colour comes from the generated [ColorScheme], so light
/// and dark stay in step and nothing is hand-picked per screen.
///
/// Direction: like Google Password Manager. Plain surfaces, rounded grouped
/// lists, one brand colour, status colours only where they mean something.

class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Screen gutters.
  static const double gutter = 16;

  /// Content never gets wider than this, so tablets and landscape read like a
  /// focused column instead of stretched phone UI.
  static const double maxContent = 640;

  /// Forms, PIN pad and the launch screen.
  static const double maxNarrow = 460;
}

class Radii {
  /// Buttons and inputs (same as the shared theme).
  static const double control = 12;

  /// Cards and grouped lists.
  static const double card = 16;

  /// Sheets and dialogs.
  static const double panel = 28;
}

class Motion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;

  /// True when the user asked the OS for less motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

class BimirFonts {
  /// Revealed passwords only: every character is distinct (l/1/I, O/0).
  static const String mono = AppFonts.mono;
}

/// Named colours for Bimir's screens, read from the current [ColorScheme].
@immutable
class BimirPalette {
  const BimirPalette._({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.foreground,
    required this.muted,
    required this.primary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.onPrimary,
    required this.onPrimarySoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.digit,
    required this.fill,
    required this.onFill,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color foreground;
  final Color muted;
  final Color primary;
  final Color primaryStrong;
  final Color primarySoft;
  final Color onPrimary;
  final Color onPrimarySoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;

  /// Digits inside a revealed password; symbols use [primary].
  final Color digit;

  /// Solid buttons.
  final Color fill;
  final Color onFill;

  static BimirPalette of(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final bool dark = s.brightness == Brightness.dark;
    return BimirPalette._(
      background: s.surface,
      surface: s.surfaceContainerLow,
      surfaceMuted: s.surfaceContainerHigh,
      border: s.outlineVariant,
      borderStrong: s.outline,
      foreground: s.onSurface,
      muted: s.onSurfaceVariant,
      primary: s.primary,
      primaryStrong: s.primary,
      primarySoft: s.primaryContainer,
      onPrimary: s.onPrimary,
      onPrimarySoft: s.onPrimaryContainer,
      // "Secure" reads in the brand colour.
      success: s.primary,
      successSoft: s.primaryContainer,
      warning: dark ? const Color(0xFFFFB95C) : const Color(0xFF8F4E00),
      // Tints of the page, not fixed swatches, so they sit right on whatever
      // dark surface they are on.
      warningSoft: dark
          ? Color.alphaBlend(const Color(0xFFFFB95C).withValues(alpha: 0.14), s.surface)
          : const Color(0xFFFFEBD3),
      danger: s.error,
      // A tint, not a slab of red, on dark surfaces.
      dangerSoft: dark ? Color.alphaBlend(s.error.withValues(alpha: 0.16), s.surface) : s.errorContainer,
      digit: dark ? const Color(0xFF9CC2FF) : const Color(0xFF2357B5),
      fill: s.primary,
      onFill: s.onPrimary,
    );
  }

  /// Revealed passwords.
  static TextStyle secret(BuildContext context, {double size = 17}) {
    return TextStyle(
      fontFamily: BimirFonts.mono,
      fontSize: size,
      height: 1.4,
      letterSpacing: 0.2,
      color: of(context).foreground,
    );
  }

  /// Counts and small figures that should line up.
  static TextStyle figure(
    BuildContext context, {
    double size = 13,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: size,
      height: 1.3,
      fontWeight: weight,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      color: color ?? of(context).muted,
    );
  }
}
