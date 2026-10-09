import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/domain/domain.dart';
import 'package:bimir_lock/modules/notes/presentation/bloc/bloc.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/note_quill.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// Read view for a single note: title + a read-only Quill render of the rich
/// body, tinted with the note's colour. Stays live by reading the [NotesCubit]
/// by id — an edit is reflected immediately by rebuilding the read-only document.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, this.note});

  final NoteEntity? note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late QuillController _quill;
  String? _renderedBody;
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _renderedBody = widget.note?.body;
    _quill = NoteQuill.controller(widget.note?.body, readOnly: true);
  }

  void _rebuild(NoteEntity note) {
    _quill.dispose();
    _quill = NoteQuill.controller(note.body, readOnly: true);
    _renderedBody = note.body;
  }

  @override
  void dispose() {
    _quill.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _shareText(NoteEntity n) {
    final buffer = StringBuffer();
    final title = n.title?.trim() ?? '';
    if (title.isNotEmpty) buffer.writeln(title);
    final body = n.plainText?.trim() ?? '';
    if (body.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(body);
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotesCubit, NotesState>(
      listenWhen: (_, c) {
        final n = c.byId(widget.note?.id);
        return n != null && n.body != _renderedBody;
      },
      listener: (context, state) {
        final n = state.byId(widget.note?.id);
        if (n != null) setState(() => _rebuild(n));
      },
      builder: (context, state) {
        final current = state.byId(widget.note?.id) ?? widget.note;
        if (current == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Note')),
            body: const Center(
              child: Text('This note is no longer available.'),
            ),
          );
        }
        final colors = context.colorScheme;
        final accent = current.color.accent(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Note'),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: current.pinned ? 'Unpin' : 'Pin',
                icon: Icon(
                  current.pinned ? LucideIcons.pinOff : LucideIcons.pin,
                  color: current.pinned ? accent : null,
                ),
                onPressed: () =>
                    context.read<NotesCubit>().togglePin(current.id!),
              ),
              IconButton(
                tooltip: 'Share',
                icon: const Icon(LucideIcons.share2),
                onPressed: () => ShareService.shareText(
                  context: context,
                  text: _shareText(current),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(LucideIcons.squarePen),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(NotesRoutes.addNote, arguments: current),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  final cubit = context.read<NotesCubit>();
                  switch (v) {
                    case 'duplicate':
                      final copy = await cubit.duplicate(current.id!);
                      if (!context.mounted) return;
                      if (copy != null) {
                        context.showInfoToast(NotesStrings.noteDuplicated);
                      }
                    case 'archive':
                      await cubit.toggleArchive(current.id!);
                      if (!context.mounted) return;
                      context.showInfoToast(
                        current.archived
                            ? NotesStrings.noteRestored
                            : NotesStrings.noteArchived,
                      );
                      Navigator.of(context).pop();
                    case 'delete':
                      await showConfirmGate(
                        context,
                        title: 'Delete note?',
                        message: 'This note will be permanently deleted.',
                        confirmText: 'Delete',
                        dialogType: DialogType.danger,
                        onProceed: () {
                          cubit.delete(current.id!);
                          if (context.mounted) {
                            context.showInfoToast(NotesStrings.noteDeleted);
                            Navigator.of(context).pop();
                          }
                        },
                      );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(current.archived ? 'Restore' : 'Archive'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              8.horizontalSpace,
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
              children: [
                Row(
                  children: [
                    Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    8.horizontalSpace,
                    Text(
                      'Edited ${NotesFormat.relativeLabel(current.updatedAt ?? current.createdAt)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                14.verticalSpace,
                SelectableText(
                  current.displayTitle,
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                16.verticalSpace,
                QuillEditor(
                  controller: _quill,
                  focusNode: _focus,
                  scrollController: _scroll,
                  config: const QuillEditorConfig(
                    scrollable: false,
                    showCursor: false,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
