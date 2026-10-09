import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/add_note_card.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/note_card.dart';

/// Lightweight, UI-only shape for a note preview. Not a domain model — just
/// enough to render placeholder cards until the data layer is wired.
typedef NotePreview = ({
  IconData icon,
  String title,
  String dateLabel,
  String? subtitle,
  bool hasAttachment,
  bool isFolder,
});

/// Two-column grid: a leading "Add" tile followed by the note cards. Scrolls
/// on its own so the header + search above it stay pinned.
class NotesGrid extends StatelessWidget {
  const NotesGrid({
    super.key,
    required this.notes,
    required this.selectionMode,
    required this.selected,
    this.onAddTap,
    this.onNoteTap,
    this.onNoteLongPress,
  });

  final List<NotePreview> notes;
  final bool selectionMode;
  final Set<int> selected;
  final VoidCallback? onAddTap;
  final ValueChanged<int>? onNoteTap;
  final ValueChanged<int>? onNoteLongPress;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
      crossAxisCount: 2,
      crossAxisSpacing: 14.w,
      mainAxisSpacing: 14.h,
      childAspectRatio: 0.82,
      children: [
        AddNoteCard(onTap: onAddTap),
        for (final (index, note) in notes.indexed)
          NoteCard(
            icon: note.icon,
            title: note.title,
            dateLabel: note.dateLabel,
            subtitle: note.subtitle,
            hasAttachment: note.hasAttachment,
            isFolder: note.isFolder,
            selectionMode: selectionMode,
            selected: selected.contains(index),
            onTap: () => onNoteTap?.call(index),
            onLongPress: () => onNoteLongPress?.call(index),
          ),
      ],
    );
  }
}
