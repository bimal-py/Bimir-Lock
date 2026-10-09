import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/common/widgets/text_field/text_field.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/domain/domain.dart';
import 'package:bimir_lock/modules/notes/feature/add_note/presentation/widgets/widgets.dart';
import 'package:bimir_lock/modules/notes/presentation/bloc/bloc.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/note_quill.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// Create / edit a note. A borderless title with a Quill rich-text body
/// (bold/italic/lists/checklists/colours/links/etc.) — the same Delta-JSON
/// editor diaryvault ships. Tagged with a [NoteColor] and pin, auto-saved to the
/// [NotesCubit] when the user leaves (back gesture or the ✓ action). Empty notes
/// are discarded.
class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key, this.note});

  final NoteEntity? note;

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late final TextEditingController _title;
  late final QuillController _quill;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _editorScroll = ScrollController();

  late NoteColor _color;
  late bool _pinned;
  bool _saved = false;

  // A seed note (only a folderId, no id) means "create here", not "edit".
  bool get _isEditing => widget.note?.id != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _title = TextEditingController(text: note?.title ?? '');
    _quill = NoteQuill.controller(note?.body);
    _pinned = note?.pinned ?? false;
    _color =
        note?.color ?? context.read<NotesCubit>().state.settings.defaultColor;
  }

  @override
  void dispose() {
    _title.dispose();
    _quill.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  NoteEntity _buildEntity() {
    return NoteEntity(
      id: widget.note?.id,
      title: _title.text.trim(),
      body: NoteQuill.bodyOf(_quill.document),
      plainText: NoteQuill.plainTextOf(_quill.document),
      colorName: _color.name,
      isPinned: _pinned,
      // Preserve the archive flag so editing an archived note doesn't silently
      // restore it to the main grid.
      isArchived: widget.note?.isArchived,
      // Preserve the folder a note lives in (or the seed's target folder) so
      // editing never silently moves it back to the root.
      folderId: widget.note?.folderId,
      createdAt: widget.note?.createdAt,
    );
  }

  Future<void> _persist() async {
    if (_saved) return;
    _saved = true;
    final cubit = context.read<NotesCubit>();
    final saved = await cubit.upsert(_buildEntity());
    if (saved != null) {
      CustomSnackbar.show(
        type: ToastType.success,
        message: NotesStrings.noteSaved,
      );
    }
  }

  Future<void> _pickColor() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await NoteColorPickerSheet.show(context, _color);
    if (picked != null) setState(() => _color = picked);
  }

  Future<void> _delete() async {
    final id = widget.note?.id;
    if (id == null) return;
    await showConfirmGate(
      context,
      title: 'Delete note?',
      message: 'This note will be permanently deleted.',
      confirmText: 'Delete',
      dialogType: DialogType.danger,
      onProceed: () async {
        _saved = true; // prevent the pop handler from re-saving
        final cubit = context.read<NotesCubit>();
        await cubit.delete(id);
        if (mounted) {
          context.showInfoToast(NotesStrings.noteDeleted);
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final accent = _color.accent(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _persist();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit note' : 'New note'),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Note colour',
              icon: Icon(LucideIcons.palette, color: accent),
              onPressed: _pickColor,
            ),
            IconButton(
              tooltip: _pinned ? 'Unpin' : 'Pin',
              icon: Icon(
                _pinned ? LucideIcons.pinOff : LucideIcons.pin,
                color: _pinned ? accent : null,
              ),
              onPressed: () => setState(() => _pinned = !_pinned),
            ),
            if (_isEditing)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(LucideIcons.trash2),
                onPressed: _delete,
              ),
            IconButton(
              tooltip: 'Save',
              icon: Icon(LucideIcons.check, color: accent),
              onPressed: () => Navigator.of(context).pop(),
            ),
            8.horizontalSpace,
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                child: AppTextField(
                  label: NotesStrings.titleLabel,
                  hint: NotesStrings.titleHint,
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: !_isEditing,
                  textInputAction: TextInputAction.next,
                ),
              ),
              // Formatting bar, then an open writing surface — the note page.
              QuillSimpleToolbar(
                controller: _quill,
                config: const QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  // Curated to the everyday formatting actions — easier to use
                  // than the full toolbar.
                  showFontFamily: false,
                  showFontSize: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showSmallButton: false,
                  showInlineCode: false,
                  showCodeBlock: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showIndent: false,
                  showDirection: false,
                  showSearchButton: false,
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                  child: QuillEditor(
                    controller: _quill,
                    focusNode: _editorFocus,
                    scrollController: _editorScroll,
                    config: QuillEditorConfig(
                      placeholder: NotesStrings.bodyHint,
                      padding: EdgeInsets.only(bottom: 24.h),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
