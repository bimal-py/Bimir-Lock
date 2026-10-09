import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/common/widgets/text_field/text_field.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// Result of [FolderFormSheet] — the chosen name + colour.
typedef FolderFormResult = ({String name, NoteColor color});

/// Create or rename a folder: a name field plus a row of colour swatches.
class FolderFormSheet extends StatefulWidget {
  const FolderFormSheet({super.key, this.folder});

  /// When set, the sheet is in rename mode and pre-fills name + colour.
  final NoteFolderEntity? folder;

  static Future<FolderFormResult?> show(
    BuildContext context, {
    NoteFolderEntity? folder,
  }) {
    return showModalBottomSheet<FolderFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FolderFormSheet(folder: folder),
    );
  }

  @override
  State<FolderFormSheet> createState() => _FolderFormSheetState();
}

class _FolderFormSheetState extends State<FolderFormSheet> {
  late final TextEditingController _name;
  late NoteColor _color;
  bool _error = false;

  bool get _isRename => widget.folder != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.folder?.name ?? '');
    _color = widget.folder?.color ?? NoteColor.none;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.of(context).pop((name: name, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        4.h,
        20.w,
        20.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.folderPlus, color: _color.accent(context)),
              10.horizontalSpace,
              Text(
                _isRename
                    ? NotesStrings.renameFolder
                    : NotesStrings.createFolder,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          18.verticalSpace,
          AppTextField(
            label: NotesStrings.folderName,
            hint: NotesStrings.folderNameHint,
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            errorText: _error ? NotesStrings.folderNameRequired : null,
            onChanged: (_) {
              if (_error) setState(() => _error = false);
            },
            onSubmitted: (_) => _submit(),
          ),
          18.verticalSpace,
          Text(
            'Colour',
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          12.verticalSpace,
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              for (final color in NoteColor.values)
                _Swatch(
                  color: color,
                  selected: color == _color,
                  onTap: () => setState(() => _color = color),
                ),
            ],
          ),
          20.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Text(_isRename ? 'Rename' : NotesStrings.createFolder),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final NoteColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color.accent(context);
    return Semantics(
      label: color.label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: color.muted(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Icon(LucideIcons.folder, size: 18.r, color: accent),
        ),
      ),
    );
  }
}
