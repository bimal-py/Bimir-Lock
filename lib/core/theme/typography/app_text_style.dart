import 'package:flutter/material.dart';
import 'package:flutter_scale_kit/flutter_scale_kit.dart';

/// Applies responsive font sizes / weights / line heights **on top of** an
/// existing Material 3 [TextTheme]. Crucially, this preserves the colors
/// Flutter bakes into the M3 default text theme — overriding `color: null`
/// would strip those and produce unreadable defaults.
///
/// Sizes are clamped through `flutter_scale_kit` so they stay legible on very
/// small or very large devices.
class AppTextStyle {
  AppTextStyle._();

  /// Returns a new [TextTheme] derived from [base] with this app's sizing
  /// applied. Colors and font families from [base] are preserved.
  static TextTheme applyTo(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 36.spClamp(28, 40),
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 30.spClamp(24, 34),
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 24.spClamp(20, 28),
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 22.spClamp(20, 26),
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20.spClamp(18, 22),
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18.spClamp(16, 20),
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18.spClamp(16, 20),
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16.spClamp(14, 18),
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14.spClamp(12, 16),
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16.spClamp(14, 18),
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14.spClamp(12, 16),
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.spClamp(11, 14),
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14.spClamp(12, 16),
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12.spClamp(11, 14),
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11.spClamp(10, 13),
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}
