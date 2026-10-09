import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/domain/domain.dart';
import 'package:bimir_lock/modules/notes/presentation/bloc/bloc.dart';
import 'package:bimir_lock/modules/notes/presentation/widgets/widgets.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

/// The notes browser used by both the Notes tab (`folderId == null`, the root)
/// and every folder screen (`folderId` set, pushed). Renders sub-folders + notes
/// in a responsive grid or list, with search, a sort/view sheet, multi-select
/// (notes + folders) and folder create/rename/move/delete.
class NotesBrowser extends StatefulWidget {
  const NotesBrowser({super.key, this.folderId});

  /// The folder whose contents are shown; `null` is the root level.
  final String? folderId;

  @override
  State<NotesBrowser> createState() => _NotesBrowserState();
}

class _NotesBrowserState extends State<NotesBrowser> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _selectedNotes = {};
  final Set<String> _selectedFolders = {};
  String _query = '';
  bool _searching = false;

  String? get _folderId => widget.folderId;
  bool get _isRoot => _folderId == null;
  bool get _selectionMode =>
      _selectedNotes.isNotEmpty || _selectedFolders.isNotEmpty;
  int get _selectionCount => _selectedNotes.length + _selectedFolders.length;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ── Selection ───────────────────────────────────────────────────────────────

  void _toggleNote(String id) => setState(() {
    _selectedNotes.contains(id)
        ? _selectedNotes.remove(id)
        : _selectedNotes.add(id);
  });

  void _toggleFolder(String id) => setState(() {
    _selectedFolders.contains(id)
        ? _selectedFolders.remove(id)
        : _selectedFolders.add(id);
  });

  void _clearSelection() => setState(() {
    _selectedNotes.clear();
    _selectedFolders.clear();
  });

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _search.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  // ── Filtering ───────────────────────────────────────────────────────────────

  bool _matchesNote(NoteEntity n) {
    if (_query.isEmpty) return true;
    final haystack = [n.title ?? '', n.plainText ?? ''].join(' ').toLowerCase();
    return haystack.contains(_query.toLowerCase());
  }

  bool _matchesFolder(NoteFolderEntity f) {
    if (_query.isEmpty) return true;
    return f.displayName.toLowerCase().contains(_query.toLowerCase());
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _createFolder() async {
    final cubit = context.read<NotesCubit>();
    final result = await FolderFormSheet.show(context);
    if (result == null) return;
    await cubit.createFolder(
      result.name,
      parentId: _folderId,
      color: result.color,
    );
  }

  Future<void> _renameFolder(NoteFolderEntity folder) async {
    final cubit = context.read<NotesCubit>();
    final result = await FolderFormSheet.show(context, folder: folder);
    if (result == null) return;
    await cubit.renameFolder(folder.id!, result.name);
    if (result.color != folder.color) {
      await cubit.setFolderColor(folder.id!, result.color);
    }
  }

  Future<void> _deleteFolder(NoteFolderEntity folder) async {
    final cubit = context.read<NotesCubit>();
    await showConfirmGate(
      context,
      title: '${NotesStrings.deleteFolder}?',
      message: NotesStrings.deleteFolderConfirm,
      confirmText: 'Delete',
      dialogType: DialogType.danger,
      onProceed: () async {
        await cubit.deleteFolder(folder.id!);
        if (mounted) context.showInfoToast(NotesStrings.folderDeleted);
      },
    );
  }

  void _newNote() {
    Navigator.of(context).pushNamed(
      NotesRoutes.addNote,
      arguments: _isRoot ? null : NoteEntity(folderId: _folderId),
    );
  }

  void _openFolder(NoteFolderEntity folder) {
    Navigator.of(context).pushNamed(NotesRoutes.folder, arguments: folder.id);
  }

  Future<void> _moveSelection() async {
    final cubit = context.read<NotesCubit>();
    // A folder can't move into itself or its own descendants.
    final excluded = <String>{};
    for (final id in _selectedFolders) {
      excluded.add(id);
      excluded.addAll(cubit.state.descendantFolderIds(id));
    }
    final dest = await MoveToFolderSheet.show(
      context,
      excludedFolderIds: excluded,
      currentFolderId: _folderId,
    );
    if (dest == null) return;
    if (_selectedNotes.isNotEmpty) {
      await cubit.moveNotes({..._selectedNotes}, dest.folderId);
    }
    for (final id in _selectedFolders) {
      await cubit.moveFolder(id, dest.folderId);
    }
    if (mounted) context.showInfoToast(NotesStrings.noteMoved);
    _clearSelection();
  }

  Future<void> _deleteSelection() async {
    final cubit = context.read<NotesCubit>();
    final count = _selectionCount;
    await showConfirmGate(
      context,
      title: 'Delete $count ${count == 1 ? 'item' : 'items'}?',
      message: _selectedFolders.isEmpty
          ? 'Delete the selected ${count == 1 ? 'note' : 'notes'}?'
          : 'Selected notes are deleted. Items inside a deleted folder move '
                'back out — nothing in them is lost.',
      confirmText: 'Delete',
      dialogType: DialogType.danger,
      onProceed: () async {
        if (_selectedNotes.isNotEmpty) {
          await cubit.deleteMany({..._selectedNotes});
        }
        for (final id in _selectedFolders) {
          await cubit.deleteFolder(id);
        }
        if (mounted) context.showInfoToast(NotesStrings.notesDeleted);
        _clearSelection();
      },
    );
  }

  void _shareSelectedNotes(NotesState state) {
    if (_selectedFolders.isNotEmpty) {
      context.showInfoToast(NotesStrings.foldersNotShared);
    }
    final selected = state.notes
        .where((n) => _selectedNotes.contains(n.id))
        .toList();
    final parts = <String>[
      for (final n in selected)
        if ((n.plainText ?? '').trim().isEmpty)
          n.displayTitle
        else
          '${n.displayTitle}\n${n.plainText!.trim()}',
    ];
    if (parts.isNotEmpty) {
      ShareService.shareText(context: context, text: parts.join('\n\n---\n\n'));
    }
    _clearSelection();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  int _columnsFor(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      builder: (context, state) {
        final folder = state.folderById(_folderId);
        final folders = state
            .foldersIn(_folderId)
            .where(_matchesFolder)
            .toList();
        final notes = state.notesIn(_folderId).where(_matchesNote).toList();

        return Scaffold(
          appBar: _appBar(context, state, folder),
          bottomNavigationBar: _selectionMode
              ? NoteSelectionBar(
                  onPin: _selectedNotes.isEmpty
                      ? null
                      : () {
                          final hadFolders = _selectedFolders.isNotEmpty;
                          context.read<NotesCubit>().setPinned({
                            ..._selectedNotes,
                          }, true);
                          if (hadFolders) {
                            context.showInfoToast(
                              NotesStrings.foldersNotPinned,
                            );
                          }
                          _clearSelection();
                        },
                  onArchive: _selectedNotes.isEmpty
                      ? null
                      : () {
                          final hadFolders = _selectedFolders.isNotEmpty;
                          context.read<NotesCubit>().setArchived({
                            ..._selectedNotes,
                          }, true);
                          context.showInfoToast(
                            hadFolders
                                ? NotesStrings.foldersNotArchived
                                : NotesStrings.notesArchived,
                          );
                          _clearSelection();
                        },
                  onShare: _selectedNotes.isEmpty
                      ? null
                      : () => _shareSelectedNotes(state),
                  onMove: _moveSelection,
                  onDelete: _deleteSelection,
                )
              : null,
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: _content(context, state, folders, notes),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(
    BuildContext context,
    NotesState state,
    NoteFolderEntity? folder,
  ) {
    final view = state.settings.view;
    return AppBar(
      centerTitle: false,
      titleSpacing: _searching ? 0 : null,
      leading: (_selectionMode || _searching)
          ? IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: _selectionMode ? _clearSelection : _closeSearch,
            )
          : null,
      title: _searching
          ? TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: NotesStrings.searchHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              _selectionMode
                  ? '$_selectionCount selected'
                  : (_isRoot ? 'Notes' : folder?.displayName ?? 'Folder'),
            ),
      actions: _selectionMode
          ? null
          : _searching
          ? [
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
              8.horizontalSpace,
            ]
          : [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(LucideIcons.search),
                onPressed: _openSearch,
              ),
              IconButton(
                tooltip: view.isGrid ? 'List view' : 'Grid view',
                icon: Icon(
                  view.isGrid ? LucideIcons.list : LucideIcons.layoutGrid,
                ),
                onPressed: () => context.read<NotesCubit>().toggleViewMode(),
              ),
              IconButton(
                tooltip: 'Sort & view',
                icon: const Icon(LucideIcons.arrowDownUp),
                onPressed: () => NoteSortSheet.show(context),
              ),
              IconButton(
                tooltip: NotesStrings.newFolder,
                icon: const Icon(LucideIcons.folderPlus),
                onPressed: _createFolder,
              ),
              if (_isRoot) ...[
                if (state.archivedCount > 0)
                  IconButton(
                    tooltip: NotesStrings.archiveTitle,
                    icon: const Icon(LucideIcons.archive),
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(NotesRoutes.notesArchive),
                  ),
                IconButton(
                  tooltip: 'Notes settings',
                  icon: const Icon(LucideIcons.settings),
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(NotesRoutes.notesSettings),
                ),
              ],
              8.horizontalSpace,
            ],
    );
  }

  Widget _content(
    BuildContext context,
    NotesState state,
    List<NoteFolderEntity> folders,
    List<NoteEntity> notes,
  ) {
    if (state.loadingState.isFailure && state.notes.isEmpty) {
      return _Empty(
        icon: LucideIcons.triangleAlert,
        title: NotesError.loadFailedTitle,
        message: state.error ?? NotesError.loadFailedMessage,
        onRetry: () => context.read<NotesCubit>().load(),
      );
    }
    if (folders.isEmpty && notes.isEmpty && _query.isNotEmpty) {
      return _Empty(
        icon: LucideIcons.searchX,
        title: NotesStrings.emptySearchTitle,
        message: NotesStrings.emptySearchMessage,
      );
    }
    if (folders.isEmpty && notes.isEmpty && !_isRoot) {
      return _Empty(
        icon: LucideIcons.folderOpen,
        title: NotesStrings.emptyFolderTitle,
        message: NotesStrings.emptyFolderMessage,
        actionLabel: 'Add note',
        onAction: _newNote,
      );
    }

    final grid = state.settings.view.isGrid;
    final list = grid
        ? _grid(context, state, folders, notes)
        : _list(context, state, folders, notes);
    // A one-time discoverability hint above the listing (root only, when not
    // searching/selecting).
    if (_isRoot && !_searching && !_selectionMode) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: const DismissibleHintCard(
              storageKey: 'note_long_press',
              icon: LucideIcons.hand,
              message:
                  'Tip: long-press a note or folder for quick actions '
                  '(move, pin, share, delete).',
            ),
          ),
          Expanded(child: list),
        ],
      );
    }
    return list;
  }

  /// Folder cards + note cards in one responsive grid; folders or notes lead per
  /// the grouping setting. The first cell is always the "Add note" tile.
  Widget _grid(
    BuildContext context,
    NotesState state,
    List<NoteFolderEntity> folders,
    List<NoteEntity> notes,
  ) {
    final foldersLead = state.settings.group.foldersLead;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final folderCards = [
          for (final f in folders) _folderCard(context, state, f),
        ];
        final noteCards = [for (final n in notes) _noteCard(context, n)];
        final content = foldersLead
            ? [...folderCards, ...noteCards]
            : [...noteCards, ...folderCards];
        return GridView.count(
          padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
          crossAxisCount: columns,
          crossAxisSpacing: 14.w,
          mainAxisSpacing: 14.h,
          childAspectRatio: 0.82,
          children: [
            AddNoteCard(onTap: _newNote),
            ...content,
          ],
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    NotesState state,
    List<NoteFolderEntity> folders,
    List<NoteEntity> notes,
  ) {
    final foldersLead = state.settings.group.foldersLead;
    final folderTiles = [
      for (final f in folders) _folderTile(context, state, f),
    ];
    final noteTiles = [for (final n in notes) _noteTile(context, n)];
    final content = foldersLead
        ? [...folderTiles, ...noteTiles]
        : [...noteTiles, ...folderTiles];
    return ListView(
      padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
      children: [
        ListTile(
          onTap: _newNote,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
          leading: CircleAvatar(
            backgroundColor: context.customTheme.brandAccentMuted,
            child: Icon(
              LucideIcons.plus,
              color: context.customTheme.brandAccent,
            ),
          ),
          title: const Text('New note'),
        ),
        ...content,
      ],
    );
  }

  // ── Cells ───────────────────────────────────────────────────────────────────

  Widget _folderCard(
    BuildContext context,
    NotesState state,
    NoteFolderEntity f,
  ) {
    final selected = _selectedFolders.contains(f.id);
    return NoteCard(
      icon: LucideIcons.folder,
      title: f.displayName,
      isFolder: true,
      dateLabel: NotesFormat.relativeLabel(f.updatedAt ?? f.createdAt),
      subtitle: NotesStrings.folderItemCount(
        state.childFolderCount(f.id),
        state.childNoteCount(f.id),
      ),
      accentColor: f.color.accent(context),
      accentMutedColor: f.color.muted(context),
      selectionMode: _selectionMode,
      selected: selected,
      onTap: () => _selectionMode ? _toggleFolder(f.id!) : _openFolder(f),
      onLongPress: () =>
          _selectionMode ? _toggleFolder(f.id!) : _folderActions(context, f),
    );
  }

  Widget _noteCard(BuildContext context, NoteEntity note) {
    return NoteCard(
      icon: LucideIcons.fileText,
      title: note.displayTitle,
      dateLabel: NotesFormat.relativeLabel(note.updatedAt ?? note.createdAt),
      subtitle: (note.title?.trim().isNotEmpty ?? false) ? note.preview : null,
      accentColor: note.color.accent(context),
      accentMutedColor: note.color.muted(context),
      pinned: note.pinned,
      selectionMode: _selectionMode,
      selected: _selectedNotes.contains(note.id),
      onTap: () => _selectionMode
          ? _toggleNote(note.id!)
          : Navigator.of(
              context,
            ).pushNamed(NotesRoutes.noteDetail, arguments: note),
      onLongPress: () => _toggleNote(note.id!),
    );
  }

  Widget _folderTile(
    BuildContext context,
    NotesState state,
    NoteFolderEntity f,
  ) {
    return _BrowserRow(
      accent: f.color.accent(context),
      iconBg: f.color.muted(context),
      icon: LucideIcons.folder,
      title: f.displayName,
      meta: NotesStrings.folderItemCount(
        state.childFolderCount(f.id),
        state.childNoteCount(f.id),
      ),
      isFolder: true,
      selectionMode: _selectionMode,
      selected: _selectedFolders.contains(f.id),
      onTap: () => _selectionMode ? _toggleFolder(f.id!) : _openFolder(f),
      onLongPress: () =>
          _selectionMode ? _toggleFolder(f.id!) : _folderActions(context, f),
    );
  }

  Widget _noteTile(BuildContext context, NoteEntity note) {
    final accent = note.color.accent(context);
    final hasTitle = note.title?.trim().isNotEmpty ?? false;
    final preview = note.preview;
    return _BrowserRow(
      accent: accent,
      iconBg: note.color.muted(context),
      icon: LucideIcons.fileText,
      title: note.displayTitle,
      subtitle: hasTitle && preview.isNotEmpty ? preview : null,
      metaIcon: LucideIcons.clock3,
      meta: NotesFormat.relativeLabel(note.updatedAt ?? note.createdAt),
      pinned: note.pinned,
      selectionMode: _selectionMode,
      selected: _selectedNotes.contains(note.id),
      onTap: () => _selectionMode
          ? _toggleNote(note.id!)
          : Navigator.of(
              context,
            ).pushNamed(NotesRoutes.noteDetail, arguments: note),
      onLongPress: () =>
          _selectionMode ? _toggleNote(note.id!) : _noteActions(context, note),
    );
  }

  /// Long-press actions on a single note (when not multi-selecting): pin, move,
  /// share, archive, delete. The same sheet a long-press hint points users to.
  void _noteActions(BuildContext context, NoteEntity note) {
    final cubit = context.read<NotesCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.pinned ? LucideIcons.pinOff : LucideIcons.pin),
              title: Text(note.pinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                cubit.togglePin(note.id!);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.folderInput),
              title: Text(NotesStrings.moveToFolder),
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() => _selectedNotes.add(note.id!));
                _moveSelection();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.share2),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _shareSingle(note);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                cubit.setArchived({note.id!}, true);
                context.showInfoToast(NotesStrings.noteArchived);
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                color: context.colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: context.colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deleteSingle(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareSingle(NoteEntity n) {
    final body = (n.plainText ?? '').trim();
    ShareService.shareText(
      context: context,
      text: body.isEmpty ? n.displayTitle : '${n.displayTitle}\n$body',
    );
  }

  Future<void> _deleteSingle(NoteEntity n) async {
    final cubit = context.read<NotesCubit>();
    await showConfirmGate(
      context,
      title: 'Delete note?',
      message: 'This note will be permanently deleted.',
      confirmText: 'Delete',
      dialogType: DialogType.danger,
      onProceed: () {
        cubit.delete(n.id!);
        if (mounted) context.showInfoToast(NotesStrings.noteDeleted);
      },
    );
  }

  /// Long-press actions on a folder (when not multi-selecting): rename, move,
  /// delete.
  void _folderActions(BuildContext context, NoteFolderEntity folder) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: Text(NotesStrings.renameFolder),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _renameFolder(folder);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.folderInput),
              title: Text(NotesStrings.moveToFolder),
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() => _selectedFolders.add(folder.id!));
                _moveSelection();
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                color: context.colorScheme.error,
              ),
              title: Text(
                NotesStrings.deleteFolder,
                style: TextStyle(color: context.colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deleteFolder(folder);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft card row for a note or folder in the list view — a rounded accent
/// icon tile, a bold title, an optional preview snippet, and a small meta line.
class _BrowserRow extends StatelessWidget {
  const _BrowserRow({
    required this.accent,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.meta,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.subtitle,
    this.metaIcon,
    this.pinned = false,
    this.isFolder = false,
  });

  final Color accent;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? metaIcon;
  final String meta;
  final bool pinned;
  final bool isFolder;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.10)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, color: accent, size: 22.r),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          if (pinned)
                            Padding(
                              padding: EdgeInsets.only(left: 6.w),
                              child: Icon(
                                LucideIcons.pin,
                                size: 14.r,
                                color: accent,
                              ),
                            ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        2.verticalSpace,
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      6.verticalSpace,
                      Row(
                        children: [
                          if (metaIcon != null) ...[
                            Icon(
                              metaIcon,
                              size: 13.r,
                              color: colors.onSurfaceVariant,
                            ),
                            4.horizontalSpace,
                          ],
                          Flexible(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                8.horizontalSpace,
                if (selectionMode)
                  Icon(
                    selected ? LucideIcons.circleCheck : LucideIcons.circle,
                    color: selected ? colors.primary : colors.outline,
                  )
                else if (isFolder)
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18.r,
                    color: colors.outline,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.r, color: colors.onSurfaceVariant),
          16.verticalSpace,
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          6.verticalSpace,
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            16.verticalSpace,
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text(AppErrorStrings.tryAgain),
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            16.verticalSpace,
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.plus),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
