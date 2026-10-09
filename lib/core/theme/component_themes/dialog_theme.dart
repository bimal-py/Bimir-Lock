import 'package:flutter/material.dart';
import 'package:flutter_scale_kit/flutter_scale_kit.dart';

/// One shared look for every dialog in the app — the [DialogUtils] confirmation
/// / input dialogs and the custom-content pickers (colour, time wheel, weight,
/// goal, unit) all read this, so they share the same rounded shape, surface and
/// text styles.
class DialogThemeBuilder {
  DialogThemeBuilder._();

  static DialogThemeData build({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      iconColor: colorScheme.primary,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
