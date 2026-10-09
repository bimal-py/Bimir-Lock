part of 'notes_cubit.dart';

class NotesState extends Equatable {
  const NotesState({
    this.loadingState = AppLoadingState.initial,
    this.notes = const [],
    this.folders = const [],
    this.settings = const NotesSettingsEntity(),
    this.error,
  });

  final AppLoadingState loadingState;
  final List<NoteEntity> notes;
  final List<NoteFolderEntity> folders;
  final NotesSettingsEntity settings;
  final String? error;

  NoteEntity? byId(String? id) {
    if (id == null) return null;
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  NoteFolderEntity? folderById(String? id) {
    if (id == null) return null;
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  // ── Folder-scoped queries ──────────────────────────────────────────────────

  static DateTime _folderStamp(NoteFolderEntity f) =>
      f.updatedAt ?? f.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  int _compareNotes(NoteEntity a, NoteEntity b) {
    if (settings.keepPinnedFirst && a.pinned != b.pinned) {
      return a.pinned ? -1 : 1;
    }
    final at = a.displayTitle.toLowerCase();
    final bt = b.displayTitle.toLowerCase();
    return switch (settings.order) {
      NoteSortOrder.newest => _stamp(b).compareTo(_stamp(a)),
      NoteSortOrder.oldest => _stamp(a).compareTo(_stamp(b)),
      NoteSortOrder.created => (b.createdAt ?? _stamp(b)).compareTo(
        a.createdAt ?? _stamp(a),
      ),
      NoteSortOrder.alphabetical => at.compareTo(bt),
      NoteSortOrder.alphabeticalReverse => bt.compareTo(at),
    };
  }

  int _compareFolders(NoteFolderEntity a, NoteFolderEntity b) {
    final an = a.displayName.toLowerCase();
    final bn = b.displayName.toLowerCase();
    return switch (settings.order) {
      NoteSortOrder.newest => _folderStamp(b).compareTo(_folderStamp(a)),
      NoteSortOrder.oldest => _folderStamp(a).compareTo(_folderStamp(b)),
      NoteSortOrder.created => (b.createdAt ?? _folderStamp(b)).compareTo(
        a.createdAt ?? _folderStamp(a),
      ),
      NoteSortOrder.alphabetical => an.compareTo(bn),
      NoteSortOrder.alphabeticalReverse => bn.compareTo(an),
    };
  }

  /// Direct child folders of [parentId] (`null` = root), in the chosen order.
  List<NoteFolderEntity> foldersIn(String? parentId) {
    final list = folders.where((f) => f.parentId == parentId).toList()
      ..sort(_compareFolders);
    return list;
  }

  /// Non-archived notes living directly in [folderId] (`null` = root), ordered.
  /// Orphaned notes (folder no longer exists) surface at the root so they're
  /// never silently lost.
  List<NoteEntity> notesIn(String? folderId) {
    final list = notes.where((n) {
      if (n.archived) return false;
      if (folderId == null) {
        return n.folderId == null || folderById(n.folderId) == null;
      }
      return n.folderId == folderId;
    }).toList()..sort(_compareNotes);
    return list;
  }

  int childFolderCount(String? id) =>
      folders.where((f) => f.parentId == id).length;

  int childNoteCount(String? id) => notes
      .where(
        (n) =>
            !n.archived &&
            (id == null
                ? (n.folderId == null || folderById(n.folderId) == null)
                : n.folderId == id),
      )
      .length;

  bool isFolderEmpty(String? id) =>
      childFolderCount(id) == 0 && childNoteCount(id) == 0;

  /// Root → [folderId] ancestor chain, for breadcrumbs and titles.
  List<NoteFolderEntity> ancestorsOf(String? folderId) {
    final chain = <NoteFolderEntity>[];
    var current = folderById(folderId);
    var guard = 0;
    while (current != null && guard++ < 64) {
      chain.insert(0, current);
      current = folderById(current.parentId);
    }
    return chain;
  }

  /// Every folder nested under [folderId] (transitively) — used to keep a folder
  /// from being moved inside itself and to reparent on delete.
  Set<String> descendantFolderIds(String? folderId) {
    final result = <String>{};
    void recurse(String? id) {
      for (final f in folders) {
        if (f.parentId == id && f.id != null && result.add(f.id!)) {
          recurse(f.id);
        }
      }
    }

    recurse(folderId);
    return result;
  }

  /// Active (non-archived) notes across all folders, ordered per the user's
  /// [NotesSettingsEntity] (pinned first when enabled, then the chosen order).
  List<NoteEntity> get sortedNotes {
    final list = notes.where((n) => !n.archived).toList()..sort(_compareNotes);
    return list;
  }

  /// Archived notes, most-recently-touched first.
  List<NoteEntity> get archivedNotes {
    final list = notes.where((n) => n.archived).toList()
      ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
    return list;
  }

  int get archivedCount => notes.where((n) => n.archived).length;

  /// Most-recently-touched active notes first — used for the Home hub preview.
  List<NoteEntity> get recent {
    final list = notes.where((n) => !n.archived).toList()
      ..sort((a, b) => _stamp(b).compareTo(_stamp(a)));
    return list;
  }

  static DateTime _stamp(NoteEntity n) =>
      n.updatedAt ?? n.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  NotesState copyWith({
    AppLoadingState? loadingState,
    List<NoteEntity>? notes,
    List<NoteFolderEntity>? folders,
    NotesSettingsEntity? settings,
    String? error,
    bool clearError = false,
  }) => NotesState(
    loadingState: loadingState ?? this.loadingState,
    notes: notes ?? this.notes,
    folders: folders ?? this.folders,
    settings: settings ?? this.settings,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [loadingState, notes, folders, settings, error];
}
