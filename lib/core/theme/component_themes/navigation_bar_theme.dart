import 'package:flutter/material.dart';

class NavigationBarThemeBuilder {
  NavigationBarThemeBuilder._();

  static NavigationBarThemeData build({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final selectedLabel = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );
    final unselectedLabel = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: colorScheme.surfaceTint,
      indicatorColor: colorScheme.primaryContainer,
      elevation: 2,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.onPrimaryContainer, size: 22);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return selectedLabel;
        return unselectedLabel;
      }),
    );
  }
}
