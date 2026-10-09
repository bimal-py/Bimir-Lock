import 'package:flutter/material.dart';
import 'package:bimir_lock/core/core.dart';

/// One selectable row in [ExportSelectionSheet].
typedef ExportEntry = ({String id, String title, String? subtitle});

/// A generic "choose what to export" sheet: a checkbox list (everything selected
/// by default), a Select-all/none toggle, and a confirm button. Returns the set
/// of chosen ids, or null on cancel.
class ExportSelectionSheet extends StatefulWidget {
  const ExportSelectionSheet({
    super.key,
    required this.title,
    required this.entries,
    this.confirmLabel = 'Export',
  });

  final String title;
  final List<ExportEntry> entries;
  final String confirmLabel;

  static Future<Set<String>?> show(
    BuildContext context, {
    required String title,
    required List<ExportEntry> entries,
    String confirmLabel = 'Export',
  }) => showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ExportSelectionSheet(
      title: title,
      entries: entries,
      confirmLabel: confirmLabel,
    ),
  );

  @override
  State<ExportSelectionSheet> createState() => _ExportSelectionSheetState();
}

class _ExportSelectionSheetState extends State<ExportSelectionSheet> {
  late final Set<String> _selected = {for (final e in widget.entries) e.id};

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final allSelected = _selected.length == widget.entries.length;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 12.w, 4.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      if (allSelected) {
                        _selected.clear();
                      } else {
                        _selected
                          ..clear()
                          ..addAll(widget.entries.map((e) => e.id));
                      }
                    }),
                    child: Text(allSelected ? 'Deselect all' : 'Select all'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.entries.length,
                itemBuilder: (_, i) {
                  final e = widget.entries[i];
                  return CheckboxListTile(
                    value: _selected.contains(e.id),
                    onChanged: (on) => setState(() {
                      (on ?? false)
                          ? _selected.add(e.id)
                          : _selected.remove(e.id);
                    }),
                    title: Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: e.subtitle == null ? null : Text(e.subtitle!),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  child: Text('${widget.confirmLabel} (${_selected.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
