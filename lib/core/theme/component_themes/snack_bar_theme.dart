import 'package:flutter/material.dart';

class SnackBarThemeBuilder {
  SnackBarThemeBuilder._();

  static SnackBarThemeData build({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required BorderRadius radius,
  }) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
    );
  }
}
