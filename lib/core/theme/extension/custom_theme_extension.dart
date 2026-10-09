import 'package:flutter/material.dart';
import 'package:bimir_lock/core/theme/colors/brand_palette.dart';

@immutable
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  const CustomThemeExtension({
    required this.brandAccent,
    required this.brandAccentMuted,
    required this.fire,
    required this.fireMuted,
    required this.success,
    required this.warning,
    required this.info,
  });

  /// The secondary brand colour (blue), harmonised to the seed.
  final Color brandAccent;
  final Color brandAccentMuted;

  /// The warm "fire" accent (orange) + a soft tint, used by the reminders
  /// feature so the three brand colours (green · blue · fire) read distinctly.
  final Color fire;
  final Color fireMuted;

  final Color success;
  final Color warning;
  final Color info;

  factory CustomThemeExtension.fromPalette(
    BrandPalette palette, {
    required Brightness brightness,
  }) {
    final scheme = brightness == Brightness.dark ? palette.dark : palette.light;
    final accent = palette.harmonizedAccent ?? scheme.tertiary;
    final isDark = brightness == Brightness.dark;
    final fire = isDark ? const Color(0xFFFF7043) : const Color(0xFFF4511E);
    return CustomThemeExtension(
      brandAccent: accent,
      brandAccentMuted: accent.withValues(alpha: 0.16),
      fire: fire,
      fireMuted: fire.withValues(alpha: 0.16),
      success: isDark ? const Color(0xFF4ED27A) : const Color(0xFF1B873B),
      warning: isDark ? const Color(0xFFFFC74A) : const Color(0xFFE5A100),
      info: isDark ? const Color(0xFF7AA7FF) : const Color(0xFF1769FF),
    );
  }

  @override
  CustomThemeExtension copyWith({
    Color? brandAccent,
    Color? brandAccentMuted,
    Color? fire,
    Color? fireMuted,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return CustomThemeExtension(
      brandAccent: brandAccent ?? this.brandAccent,
      brandAccentMuted: brandAccentMuted ?? this.brandAccentMuted,
      fire: fire ?? this.fire,
      fireMuted: fireMuted ?? this.fireMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  CustomThemeExtension lerp(
    ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) return this;
    return CustomThemeExtension(
      brandAccent: Color.lerp(brandAccent, other.brandAccent, t)!,
      brandAccentMuted: Color.lerp(brandAccentMuted, other.brandAccentMuted, t)!,
      fire: Color.lerp(fire, other.fire, t)!,
      fireMuted: Color.lerp(fireMuted, other.fireMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
