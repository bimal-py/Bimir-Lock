import 'package:flutter/material.dart';
import 'package:bimir_lock/core/utils/extensions/context_extension.dart';

enum DialogType { info, success, warning, danger, question }

/// The icons the Callbreak Tracker app's dialogs use. Everything that is not
/// a warning or a destructive action takes the brand colour, so dialogs never
/// bring in a blue or a green of their own.
extension DialogTypeX on DialogType {
  IconData get icon => switch (this) {
    DialogType.info => Icons.info_outline_rounded,
    DialogType.success => Icons.check_circle_outline_rounded,
    DialogType.warning => Icons.warning_amber_rounded,
    DialogType.danger => Icons.delete_outline_rounded,
    DialogType.question => Icons.help_outline_rounded,
  };

  Color accentColor(BuildContext context) => switch (this) {
    DialogType.warning => context.customTheme.warning,
    DialogType.danger => context.colorScheme.error,
    _ => context.colorScheme.primary,
  };

  bool get destructive => this == DialogType.danger;
}
