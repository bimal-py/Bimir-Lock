import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/presentation/bloc/bloc.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// Bottom sheet to choose the notes sort order, folder/notes grouping, the
/// pinned-first toggle and the grid/list layout. Writes straight to the
/// [NotesCubit] (settings are persisted), so changes apply live.
class NoteSortSheet extends StatelessWidget {
  const NoteSortSheet({super.key});

  static Future<void> show(BuildContext context) {
    // The cubit is provided per notes route (not above the MaterialApp as in
    // Reminder Note), so hand it to the sheet's own route.
    final cubit = context.read<NotesCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<NotesCubit>.value(
        value: cubit,
        child: const NoteSortSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return SafeArea(
      top: false,
      child: BlocBuilder<NotesCubit, NotesState>(
        buildWhen: (a, b) => a.settings != b.settings,
        builder: (context, state) {
          final cubit = context.read<NotesCubit>();
          final settings = state.settings;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 16.h),
              children: [
                Text(
                  'Sort & view',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                16.verticalSpace,
                _Label('Sort by'),
                for (final order in NoteSortOrder.values)
                  _CheckTile(
                    label: order.label,
                    selected: settings.order == order,
                    onTap: () => cubit.setSortOrder(order),
                  ),
                Divider(height: 24.h, color: colors.outlineVariant),
                _Label('Group'),
                for (final group in NoteGrouping.values)
                  _CheckTile(
                    label: group.label,
                    selected: settings.group == group,
                    onTap: () => cubit.setGrouping(group),
                  ),
                Divider(height: 24.h, color: colors.outlineVariant),
                SwitchListTile(
                  value: settings.keepPinnedFirst,
                  onChanged: cubit.setPinnedFirst,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pinned notes first'),
                  secondary: const Icon(LucideIcons.pin),
                ),
                SwitchListTile(
                  value: settings.view.isGrid,
                  onChanged: (v) => cubit.setViewMode(
                    v ? NoteViewMode.grid : NoteViewMode.list,
                  ),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Grid layout'),
                  subtitle: Text(settings.view.isGrid ? 'Grid' : 'List'),
                  secondary: Icon(
                    settings.view.isGrid
                        ? LucideIcons.layoutGrid
                        : LucideIcons.list,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label),
      trailing: selected
          ? Icon(LucideIcons.check, color: colors.primary, size: 20.r)
          : null,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
