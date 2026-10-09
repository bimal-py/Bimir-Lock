import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';

/// Bottom action bar shown while notes are being multi-selected. Surfaces the
/// batch actions: pin, archive, share, move and delete.
class NoteSelectionBar extends StatelessWidget {
  const NoteSelectionBar({
    super.key,
    this.onPin,
    this.onArchive,
    this.onShare,
    this.onMove,
    this.onDelete,
  });

  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onShare;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Material(
      color: colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          child: Row(
            children: [
              _SelectionAction(
                icon: LucideIcons.pin,
                label: 'Pin Note',
                onTap: onPin,
              ),
              _SelectionAction(
                icon: LucideIcons.archive,
                label: 'Archive',
                onTap: onArchive,
              ),
              _SelectionAction(
                icon: LucideIcons.share2,
                label: 'Share Note',
                onTap: onShare,
              ),
              _SelectionAction(
                icon: LucideIcons.folder,
                label: 'Move to folder',
                onTap: onMove,
              ),
              _SelectionAction(
                icon: LucideIcons.trash2,
                label: 'Delete',
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  const _SelectionAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22.r, color: colors.onSurfaceVariant),
              6.verticalSpace,
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
