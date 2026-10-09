import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/notes.dart';
import 'package:bimir_lock/modules/settings_ui/settings_ui.dart';

/// Notes preferences — list ordering, pinned-first behaviour, the default colour
/// applied to new notes, and backup export/import. Reads/writes the app-wide
/// [NotesCubit].
class NotesSettingsScreen extends StatelessWidget {
  const NotesSettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final cubit = context.read<NotesCubit>();
    final notes = cubit.state.notes;
    if (notes.isEmpty) {
      context.showInfoToast('No notes to export.');
      return;
    }
    final entries = <ExportEntry>[
      for (final n in notes)
        (
          id: n.id!,
          title: n.displayTitle,
          subtitle: n.preview.isEmpty ? null : n.preview,
        ),
    ];
    final selected = await ExportSelectionSheet.show(
      context,
      title: 'Export notes',
      entries: entries,
    );
    if (selected == null || selected.isEmpty || !context.mounted) return;
    final data = cubit.buildExport(selected);
    final path = await DataIoService.writeJsonToTemp('notes_backup.json', data);
    if (!context.mounted) return;
    await ShareService.shareFiles(
      context: context,
      filePaths: [path],
      subject: 'Notes backup',
      mimeTypes: const ['application/json'],
    );
  }

  Future<void> _import(BuildContext context) async {
    final cubit = context.read<NotesCubit>();
    final data = await DataIoService.pickJson();
    if (data == null || !context.mounted) return;
    try {
      final count = await cubit.importFrom(data);
      if (!context.mounted) return;
      context.showSuccessToast('Imported $count note(s).');
    } catch (_) {
      if (context.mounted) {
        context.showErrorToast('That file isn’t a notes backup.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes'), centerTitle: false),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          final cubit = context.read<NotesCubit>();
          final settings = state.settings;
          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            children: [
              const SettingsSectionHeader(label: 'Sort order'),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, order) in NoteSortOrder.values.indexed) ...[
                      if (i != 0)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: Text(order.label),
                        trailing: order == settings.order
                            ? Icon(
                                LucideIcons.check,
                                color: context.colorScheme.primary,
                                size: 20.r,
                              )
                            : null,
                        onTap: () => cubit.setSortOrder(order),
                      ),
                    ],
                  ],
                ),
              ),
              20.verticalSpace,
              const SettingsSectionHeader(label: 'Display'),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.keepPinnedFirst,
                      onChanged: cubit.setPinnedFirst,
                      title: const Text('Show pinned notes first'),
                      secondary: const Icon(LucideIcons.pin),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(LucideIcons.palette),
                      title: const Text('Default colour'),
                      subtitle: Text(settings.defaultColor.label),
                      trailing: CircleAvatar(
                        radius: 11.r,
                        backgroundColor: settings.defaultColor.accent(context),
                      ),
                      onTap: () async {
                        final picked = await NoteColorPickerSheet.show(
                          context,
                          settings.defaultColor,
                        );
                        if (picked != null) cubit.setDefaultColor(picked);
                      },
                    ),
                  ],
                ),
              ),
              20.verticalSpace,
              const SettingsSectionHeader(label: 'Backup'),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: LucideIcons.upload,
                      label: 'Export notes',
                      subtitle: 'Save a backup file you can re-import later',
                      onTap: () => _export(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingsTile(
                      icon: LucideIcons.download,
                      label: 'Import notes',
                      subtitle: 'Restore from a backup file',
                      onTap: () => _import(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
