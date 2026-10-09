import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// Palette a note can be tagged with. [seed] is null for [NoteColor.none],
/// which falls back to the app's brand accent so untagged notes still match the
/// theme. The seeds are chosen to read on both light and dark surfaces — at full
/// strength as an accent and at low alpha as a tint.
enum NoteColor {
  none(null, 'Default'),
  coral(Color(0xFFE5544B), 'Coral'),
  amber(Color(0xFFE8902A), 'Amber'),
  gold(Color(0xFFC9A227), 'Gold'),
  sage(Color(0xFF3FA972), 'Sage'),
  ocean(Color(0xFF3B82C4), 'Ocean'),
  lavender(Color(0xFF8B5CF6), 'Lavender'),
  rose(Color(0xFFD6699A), 'Rose');

  const NoteColor(this.seed, this.label);

  final Color? seed;
  final String label;

  static NoteColor fromName(String? name) => NoteColor.values.firstWhere(
    (c) => c.name == name,
    orElse: () => NoteColor.none,
  );

  /// The accent to paint with — the seed, or the theme's brand accent for [none].
  Color accent(BuildContext context) => seed ?? context.customTheme.brandAccent;

  /// A soft tint of [accent] for icon badges / card washes.
  Color muted(BuildContext context) => seed == null
      ? context.customTheme.brandAccentMuted
      : seed!.withValues(alpha: 0.16);
}
