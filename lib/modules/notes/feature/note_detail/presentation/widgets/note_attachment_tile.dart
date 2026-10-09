import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/feature/note_detail/presentation/widgets/attachment_file_icon.dart';

/// A single file attachment row: type icon, file name, and a remove button.
class NoteAttachmentTile extends StatelessWidget {
  const NoteAttachmentTile({super.key, required this.fileName, this.onRemove});

  final String fileName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          AttachmentFileIcon(fileName: fileName),
          12.horizontalSpace,
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          12.horizontalSpace,
          InkResponse(
            onTap: onRemove,
            radius: 20.r,
            child: Icon(LucideIcons.x, size: 20.r, color: colors.error),
          ),
        ],
      ),
    );
  }
}
