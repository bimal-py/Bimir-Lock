import 'package:flutter/material.dart';
import 'package:bimir_lock/core/utils/extensions/context_extension.dart';

/// Flat, hand-crafted decorative language: solid colour fills, hairline
/// borders and restrained shadows — no gradients. Surfaces read as clean,
/// deliberate blocks rather than washes.
class AppDecor {
  AppDecor._();

  static bool _isDark(BuildContext context) =>
      context.colorScheme.brightness == Brightness.dark;

  /// A translucent pale fill of [color] — for icon medallions, chips, pills.
  static Color fill(Color color, {double alpha = 0.12}) =>
      color.withValues(alpha: alpha);

  /// A hairline border colour derived from [color].
  static Color border(Color color, {double alpha = 0.22}) =>
      color.withValues(alpha: alpha);

  /// An opaque pale tint of [color] painted over the surface — for soft
  /// coloured cards that still cast a clean shadow.
  static Color softSurface(
    BuildContext context,
    Color color, {
    double alpha = 0.12,
  }) => Color.alphaBlend(
    color.withValues(alpha: alpha),
    context.colorScheme.surface,
  );

  /// Restrained neutral elevation shadow for raised cards.
  static List<BoxShadow> softShadow(BuildContext context) {
    return [
      BoxShadow(
        color: context.colorScheme.shadow.withValues(
          alpha: _isDark(context) ? 0.38 : 0.07,
        ),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ];
  }

  /// Readable foreground (white or near-black ink) for a solid [background].
  /// Threshold tuned so mid-bright ambers fall to dark ink.
  static Color ink(Color background) =>
      background.computeLuminance() > 0.40
      ? const Color(0xFF1B1B1B)
      : Colors.white;
}
