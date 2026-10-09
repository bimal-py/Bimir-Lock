import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// Shown in place of the grid when a folder has no files yet — a soft accent
/// icon badge, a short message and an "Add file" action.
class FolderEmptyState extends StatelessWidget {
  const FolderEmptyState({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final custom = context.customTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: custom.brandAccentMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.folderOpen,
              color: custom.brandAccent,
              size: 32.r,
            ),
          ),
          16.verticalSpace,
          Text(
            'This folder is empty',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          6.verticalSpace,
          Text(
            'Add a note to get started.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          20.verticalSpace,
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add Note'),
          ),
        ],
      ),
    );
  }
}
