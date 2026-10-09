import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/presentation/bloc/bloc.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/widgets.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// Archived notes — kept out of the main grid but still searchable and
/// restorable. Tap a card to open it (Restore + Delete live in its menu); a
/// long-press restores it straight back to the active list.
class ArchivedNotesScreen extends StatelessWidget {
  const ArchivedNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(NotesStrings.archiveTitle),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) {
            final notes = state.archivedNotes;
            if (notes.isEmpty) return const _EmptyArchive();
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: GridView.count(
                padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
                crossAxisCount: 2,
                crossAxisSpacing: 14.w,
                mainAxisSpacing: 14.h,
                childAspectRatio: 0.82,
                children: [
                  for (final note in notes)
                    NoteCard(
                      icon: LucideIcons.archive,
                      title: note.displayTitle,
                      dateLabel: NotesFormat.relativeLabel(
                        note.updatedAt ?? note.createdAt,
                      ),
                      subtitle: (note.title?.trim().isNotEmpty ?? false)
                          ? note.preview
                          : null,
                      accentColor: note.color.accent(context),
                      accentMutedColor: note.color.muted(context),
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(NotesRoutes.noteDetail, arguments: note),
                      onLongPress: () async {
                        await context.read<NotesCubit>().toggleArchive(
                          note.id!,
                        );
                        if (context.mounted) {
                          context.showInfoToast(NotesStrings.noteRestored);
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  const _EmptyArchive();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.archive,
              size: 48.r,
              color: colors.onSurfaceVariant,
            ),
            16.verticalSpace,
            Text(
              NotesStrings.emptyArchiveTitle,
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            6.verticalSpace,
            Text(
              NotesStrings.emptyArchiveMessage,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
