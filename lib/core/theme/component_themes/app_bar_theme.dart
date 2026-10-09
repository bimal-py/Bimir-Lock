import 'package:flutter/material.dart';

class AppBarThemeBuilder {
  AppBarThemeBuilder._();

  static AppBarTheme build({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
    );
  }
}
