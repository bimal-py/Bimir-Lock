import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsThemePicker extends StatelessWidget {
  const SettingsThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final CoreController cc = Get.find<CoreController>();
    return Obx(
      () {
        final ThemeMode current = cc.themeMode.value;
        return Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              for (final mode in ThemeMode.values)
                Expanded(
                  child: _ThemeOption(
                    mode: mode,
                    selected: current == mode,
                    onTap: () => cc.toggleThemeMode(mode),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final (label, icon) = switch (mode) {
      ThemeMode.system => ('System', LucideIcons.monitor),
      ThemeMode.light => ('Light', LucideIcons.sun),
      ThemeMode.dark => ('Dark', LucideIcons.moon),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18.r,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
