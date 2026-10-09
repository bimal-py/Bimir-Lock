import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/presentation/bloc/bloc.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// A chosen move destination — `folderId` null means the root level. The record
/// wrapper lets a `null` pop mean "cancelled" while `(folderId: null)` means
/// "root".
typedef MoveDestination = ({String? folderId});

/// Pick a destination folder for the items being moved. Renders the folder tree
/// (indented) with a "Notes" root entry, hiding any [excludedFolderIds] (a
/// folder can't be moved into itself or its own descendants).
class MoveToFolderSheet extends StatelessWidget {
  const MoveToFolderSheet({
    super.key,
    this.excludedFolderIds = const {},
    this.currentFolderId,
  });

  final Set<String> excludedFolderIds;
  final String? currentFolderId;

  static Future<MoveDestination?> show(
    BuildContext context, {
    Set<String> excludedFolderIds = const {},
    String? currentFolderId,
  }) {
    // The cubit is provided per notes route (not above the MaterialApp as in
    // Reminder Note), so hand it to the sheet's own route.
    final cubit = context.read<NotesCubit>();
    return showModalBottomSheet<MoveDestination>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<NotesCubit>.value(
        value: cubit,
        child: MoveToFolderSheet(
          excludedFolderIds: excludedFolderIds,
          currentFolderId: currentFolderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<NotesCubit>().state;

    // Flatten the tree depth-first so each folder shows under its parent.
    final rows = <({NoteFolderEntity folder, int depth})>[];
    void walk(String? parentId, int depth) {
      for (final f in state.foldersIn(parentId)) {
        if (f.id != null && excludedFolderIds.contains(f.id)) continue;
        rows.add((folder: f, depth: depth));
        walk(f.id, depth + 1);
      }
    }

    walk(null, 0);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
              child: Text(
                NotesStrings.moveToFolder,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: 12.h),
                children: [
                  _DestinationTile(
                    icon: LucideIcons.house,
                    label: NotesStrings.root,
                    depth: 0,
                    isCurrent: currentFolderId == null,
                    onTap: () => Navigator.of(context).pop((folderId: null)),
                  ),
                  for (final row in rows)
                    _DestinationTile(
                      icon: LucideIcons.folder,
                      label: row.folder.displayName,
                      depth: row.depth + 1,
                      color: row.folder.color.accent(context),
                      isCurrent: currentFolderId == row.folder.id,
                      onTap: () =>
                          Navigator.of(context).pop((folderId: row.folder.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.icon,
    required this.label,
    required this.depth,
    required this.isCurrent,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final int depth;
  final bool isCurrent;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ListTile(
      enabled: !isCurrent,
      contentPadding: EdgeInsets.only(left: 20.w + (depth * 18.w), right: 20.w),
      leading: Icon(icon, color: color ?? colors.onSurfaceVariant),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: isCurrent
          ? Text(
              'Here',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          : null,
      onTap: isCurrent ? null : onTap,
    );
  }
}
