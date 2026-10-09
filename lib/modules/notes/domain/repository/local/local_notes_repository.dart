import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';

/// Local persistence for notes (Hive). A Supabase-backed
/// `RemoteNotesRepository` will sit alongside this when remote sync lands.
abstract class LocalNotesRepository {
  /// Every stored note. Ordering is the caller's concern.
  Future<List<NoteEntity>> getNotes();

  /// Replaces the whole note list (the cubit is the single writer).
  Future<void> saveNotes(List<NoteEntity> notes);

  /// Emits the current notes, then again after every change to the box.
  Stream<List<NoteEntity>> watchNotes();

  /// Every stored folder. Ordering is the caller's concern.
  Future<List<NoteFolderEntity>> getFolders();

  /// Replaces the whole folder list (the cubit is the single writer).
  Future<void> saveFolders(List<NoteFolderEntity> folders);

  /// Emits the current folders, then again after every change to the box.
  Stream<List<NoteFolderEntity>> watchFolders();

  /// The stored notes preferences, or defaults if never set.
  Future<NotesSettingsEntity> getSettings();

  Future<void> saveSettings(NotesSettingsEntity settings);
}
