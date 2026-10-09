import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bimir_lock/common/common.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/data/mapper/note_mapper.dart';
import 'package:bimir_lock/modules/notes/domain/domain.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

part 'notes_state.dart';

/// App-wide notes store. Loads notes + preferences on start, stays in sync with
/// Hive via [WatchNotesUseCase], and is the single writer for every note
/// mutation — so the Home hub, the Notes tab and the editor all read one source
/// of truth.
class NotesCubit extends Cubit<NotesState> {
  NotesCubit() : super(const NotesState());

  final GetNotesUseCase _getNotes = getIt<GetNotesUseCase>();
  final SaveNotesUseCase _saveNotes = getIt<SaveNotesUseCase>();
  final WatchNotesUseCase _watchNotes = getIt<WatchNotesUseCase>();
  final GetFoldersUseCase _getFolders = getIt<GetFoldersUseCase>();
  final SaveFoldersUseCase _saveFolders = getIt<SaveFoldersUseCase>();
  final WatchFoldersUseCase _watchFolders = getIt<WatchFoldersUseCase>();
  final GetNotesSettingsUseCase _getSettings = getIt<GetNotesSettingsUseCase>();
  final SaveNotesSettingsUseCase _saveSettings =
      getIt<SaveNotesSettingsUseCase>();

  StreamSubscription<List<NoteEntity>>? _subscription;
  StreamSubscription<List<NoteFolderEntity>>? _folderSubscription;

  // Disambiguates ids minted within the same microsecond.
  int _idSeed = 0;

  Future<void> load() async {
    emit(
      state.copyWith(loadingState: AppLoadingState.loading, clearError: true),
    );
    try {
      final settings = await _getSettings.execute(const NoParams());
      final notes = await _getNotes.execute(const NoParams());
      final folders = await _getFolders.execute(const NoParams());
      emit(
        state.copyWith(
          loadingState: AppLoadingState.success,
          notes: notes,
          folders: folders,
          settings: settings,
          clearError: true,
        ),
      );
      _subscription ??= _watchNotes
          .execute(const NoParams())
          .listen(
            (notes) => emit(
              state.copyWith(
                loadingState: AppLoadingState.success,
                notes: notes,
              ),
            ),
          );
      _folderSubscription ??= _watchFolders
          .execute(const NoParams())
          .listen((folders) => emit(state.copyWith(folders: folders)));
    } catch (error) {
      emit(
        state.copyWith(
          loadingState: AppLoadingState.failure,
          error: AppErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  /// Creates or replaces [note], stamping timestamps and returning the saved
  /// entity (with a freshly-minted id on create). Empty notes are dropped.
  Future<NoteEntity?> upsert(NoteEntity note) async {
    if (note.isEmpty) {
      // Nothing worth keeping — discard an existing empty note if it was saved.
      if (note.id != null) await delete(note.id!);
      return null;
    }
    final now = DateTime.now();
    final exists = note.id != null && state.notes.any((n) => n.id == note.id);
    final saved = note.copyWith(
      id: note.id ?? '${now.microsecondsSinceEpoch}_${_idSeed++}',
      createdAt: note.createdAt ?? now,
      updatedAt: now,
    );
    final next = exists
        ? state.notes.map((n) => n.id == saved.id ? saved : n).toList()
        : [...state.notes, saved];
    final ok = await _persist(next);
    return ok ? saved : null;
  }

  Future<void> delete(String id) =>
      _persist(state.notes.where((n) => n.id != id).toList());

  Future<void> deleteMany(Set<String> ids) =>
      _persist(state.notes.where((n) => !ids.contains(n.id)).toList());

  Future<void> togglePin(String id) {
    final next = state.notes
        .map((n) => n.id == id ? n.copyWith(isPinned: !n.pinned) : n)
        .toList();
    return _persist(next);
  }

  Future<void> setPinned(Set<String> ids, bool pinned) {
    final next = state.notes
        .map((n) => ids.contains(n.id) ? n.copyWith(isPinned: pinned) : n)
        .toList();
    return _persist(next);
  }

  /// Archives or restores [ids]. Archived notes leave the main grid (and the
  /// Home preview) but stay searchable from the Archive screen. Archiving also
  /// un-pins so a restored note never silently jumps back to a pinned slot.
  Future<void> setArchived(Set<String> ids, bool archived) {
    final next = state.notes
        .map(
          (n) => ids.contains(n.id)
              ? n.copyWith(
                  isArchived: archived,
                  isPinned: archived ? false : n.isPinned,
                )
              : n,
        )
        .toList();
    return _persist(next);
  }

  Future<void> toggleArchive(String id) {
    final note = state.byId(id);
    if (note == null) return Future.value();
    return setArchived({id}, !note.archived);
  }

  /// Clones [id] into a brand-new note (fresh id + timestamps, never pinned or
  /// archived) and returns it, so the caller can open the copy for editing. We
  /// build a fresh [NoteEntity] rather than `copyWith` because copyWith can't
  /// null-out the id — [upsert] needs a null id to mint a new one.
  Future<NoteEntity?> duplicate(String id) {
    final source = state.byId(id);
    if (source == null) return Future.value(null);
    final title = source.title?.trim();
    return upsert(
      NoteEntity(
        title: (title == null || title.isEmpty) ? null : '$title (copy)',
        body: source.body,
        plainText: source.plainText,
        colorName: source.colorName,
      ),
    );
  }

  Future<void> setColor(String id, NoteColor color) {
    final next = state.notes
        .map((n) => n.id == id ? n.copyWith(colorName: color.name) : n)
        .toList();
    return _persist(next);
  }

  Future<void> setSortOrder(NoteSortOrder order) =>
      _persistSettings(state.settings.copyWith(sortOrder: order));

  Future<void> setPinnedFirst(bool value) =>
      _persistSettings(state.settings.copyWith(pinnedFirst: value));

  Future<void> setDefaultColor(NoteColor color) =>
      _persistSettings(state.settings.copyWith(defaultColorName: color.name));

  Future<void> setGrouping(NoteGrouping grouping) =>
      _persistSettings(state.settings.copyWith(grouping: grouping));

  Future<void> setViewMode(NoteViewMode mode) =>
      _persistSettings(state.settings.copyWith(viewMode: mode));

  Future<void> toggleViewMode() => setViewMode(state.settings.view.toggled);

  // ── Folders ─────────────────────────────────────────────────────────────────

  /// Creates a folder under [parentId] (`null` = root) and returns it.
  Future<NoteFolderEntity?> createFolder(
    String name, {
    String? parentId,
    NoteColor? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final now = DateTime.now();
    final folder = NoteFolderEntity(
      id: '${now.microsecondsSinceEpoch}_${_idSeed++}',
      name: trimmed,
      parentId: parentId,
      colorName: color?.name,
      createdAt: now,
      updatedAt: now,
    );
    final ok = await _persistFolders([...state.folders, folder]);
    return ok ? folder : null;
  }

  Future<void> renameFolder(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    final now = DateTime.now();
    final next = state.folders
        .map((f) => f.id == id ? f.copyWith(name: trimmed, updatedAt: now) : f)
        .toList();
    return _persistFolders(next);
  }

  Future<void> setFolderColor(String id, NoteColor color) {
    final next = state.folders
        .map((f) => f.id == id ? f.copyWith(colorName: color.name) : f)
        .toList();
    return _persistFolders(next);
  }

  /// Re-parents [id] under [newParentId]. Refuses to move a folder into itself
  /// or one of its own descendants (which would orphan a whole subtree).
  Future<void> moveFolder(String id, String? newParentId) {
    if (id == newParentId) return Future.value();
    if (newParentId != null &&
        state.descendantFolderIds(id).contains(newParentId)) {
      return Future.value();
    }
    final now = DateTime.now();
    final next = state.folders
        .map(
          (f) => f.id == id
              ? f.copyWith(
                  parentId: newParentId,
                  clearParent: newParentId == null,
                  updatedAt: now,
                )
              : f,
        )
        .toList();
    return _persistFolders(next);
  }

  /// Deletes a folder, moving its notes and sub-folders **out** to where the
  /// folder lived (its parent) — nothing inside is lost.
  Future<void> deleteFolder(String id) async {
    final folder = state.folderById(id);
    if (folder == null) return;
    final parent = folder.parentId;
    // Re-home child folders and notes to the deleted folder's parent.
    final folders = state.folders
        .where((f) => f.id != id)
        .map(
          (f) => f.parentId == id
              ? f.copyWith(parentId: parent, clearParent: parent == null)
              : f,
        )
        .toList();
    final notes = state.notes
        .map(
          (n) => n.folderId == id
              ? n.copyWith(folderId: parent, clearFolder: parent == null)
              : n,
        )
        .toList();
    // Remove the folder FIRST, then re-home its notes. If the second write
    // fails, the folder stays deleted (intent honoured) and its notes surface
    // at the root as orphans (notesIn(null) handles dangling folderIds) — a
    // consistent half-state, vs. the reverse order which could resurrect the
    // folder after its notes had already moved out.
    final foldersOk = await _persistFolders(folders);
    if (foldersOk) await _persist(notes);
  }

  /// Moves [ids] into [folderId] (`null` = root).
  Future<void> moveNotes(Set<String> ids, String? folderId) {
    final now = DateTime.now();
    final next = state.notes
        .map(
          (n) => ids.contains(n.id)
              ? n.copyWith(
                  folderId: folderId,
                  clearFolder: folderId == null,
                  updatedAt: now,
                )
              : n,
        )
        .toList();
    return _persist(next);
  }

  /// Builds a portable JSON backup of [ids].
  Map<String, dynamic> buildExport(Set<String> ids) {
    final selected = state.notes.where((n) => ids.contains(n.id)).toList();
    return {
      'type': 'remindernote.notes',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'items': NoteMapper.toJsonListFromEntityList(selected),
    };
  }

  /// Imports notes from a backup, giving each a fresh id. Returns how many were
  /// added.
  Future<int> importFrom(Map<String, dynamic> data) async {
    if (data['type'] != 'remindernote.notes') {
      throw const FormatException('Not a notes backup');
    }
    final version = data['version'];
    if (version is int && version > 1) {
      throw const FormatException('Unsupported backup version');
    }
    final items = (data['items'] as List?) ?? const [];
    final now = DateTime.now();
    // Guard each row so one corrupt entry drops rather than aborting the import.
    final withFreshIds = <NoteEntity>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        final n = NoteMapper.fromJsonToEntity(raw);
        withFreshIds.add(
          n.copyWith(
            id: '${now.microsecondsSinceEpoch}_${_idSeed++}',
            clearFolder: true, // imported notes land at the root level
          ),
        );
      } catch (_) {
        // Skip a malformed note row.
      }
    }
    if (withFreshIds.isEmpty) return 0;
    final ok = await _persist([...state.notes, ...withFreshIds]);
    return ok ? withFreshIds.length : 0;
  }

  /// Optimistically emits [notes] then persists; rolls back on failure so memory
  /// never silently diverges from disk. Returns whether the save succeeded.
  Future<bool> _persist(List<NoteEntity> notes) async {
    final previous = state.notes;
    emit(state.copyWith(notes: notes));
    try {
      await _saveNotes.execute(notes);
      return true;
    } catch (error) {
      emit(state.copyWith(notes: previous));
      CustomSnackbar.show(
        type: ToastType.error,
        message: AppErrorHandler.getErrorMessage(error),
      );
      return false;
    }
  }

  /// Optimistically emits [folders] then persists; rolls back on failure.
  Future<bool> _persistFolders(List<NoteFolderEntity> folders) async {
    final previous = state.folders;
    emit(state.copyWith(folders: folders));
    try {
      await _saveFolders.execute(folders);
      return true;
    } catch (error) {
      emit(state.copyWith(folders: previous));
      CustomSnackbar.show(
        type: ToastType.error,
        message: AppErrorHandler.getErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> _persistSettings(NotesSettingsEntity settings) async {
    final previous = state.settings;
    emit(state.copyWith(settings: settings));
    try {
      await _saveSettings.execute(settings);
    } catch (error) {
      emit(state.copyWith(settings: previous));
      CustomSnackbar.show(
        type: ToastType.error,
        message: AppErrorHandler.getErrorMessage(error),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _folderSubscription?.cancel();
    return super.close();
  }
}
