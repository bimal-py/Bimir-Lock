import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// App-bar title for a folder view: the folder name on top with a muted
/// file-count line beneath it (e.g. "Academic Notes" / "5 Files").
class FolderAppBarTitle extends StatelessWidget {
  const FolderAppBarTitle({
    super.key,
    required this.name,
    required this.fileCount,
  });

  final String name;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          '$fileCount ${fileCount == 1 ? 'File' : 'Files'}',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
