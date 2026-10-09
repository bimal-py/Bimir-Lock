import 'package:hive_flutter/hive_flutter.dart';
import 'package:bimir_lock/core/core.dart';
import 'package:bimir_lock/modules/notes/data/mapper/mapper.dart';
import 'package:bimir_lock/modules/notes/domain/entity/entity.dart';
import 'package:bimir_lock/modules/notes/domain/repository/local/local_notes_repository.dart';
import 'package:bimir_lock/modules/notes/utils/utils.dart';

class LocalNotesRepositoryImpl implements LocalNotesRepository {
  Box<dynamic> get _box => Hive.notesBox;

  @override
  Future<List<NoteEntity>> getNotes() async {
    try {
      final raw = _box.get(NotesStorageKeys.notesKey) as String?;
      if (raw == null || raw.isEmpty) return const [];
      return NoteMapper.fromRawJsonListToEntityList(raw);
    } catch (_) {
      throw const CacheException(message: NotesError.loadFailed);
    }
  }

  @override
  Future<void> saveNotes(List<NoteEntity> notes) async {
    try {
      await _box.put(
        NotesStorageKeys.notesKey,
        NoteMapper.toRawJsonListFromEntityList(notes),
      );
    } catch (_) {
      throw const CacheException(message: NotesError.saveFailed);
    }
  }

  @override
  Stream<List<NoteEntity>> watchNotes() async* {
    yield await getNotes();
    yield* _box
        .watch(key: NotesStorageKeys.notesKey)
        .asyncMap((_) => getNotes());
  }

  @override
  Future<List<NoteFolderEntity>> getFolders() async {
    try {
      final raw = _box.get(NotesStorageKeys.foldersKey) as String?;
      if (raw == null || raw.isEmpty) return const [];
      return NoteFolderMapper.fromRawJsonListToEntityList(raw);
    } catch (_) {
      throw const CacheException(message: NotesError.loadFailed);
    }
  }

  @override
  Future<void> saveFolders(List<NoteFolderEntity> folders) async {
    try {
      await _box.put(
        NotesStorageKeys.foldersKey,
        NoteFolderMapper.toRawJsonListFromEntityList(folders),
      );
    } catch (_) {
      throw const CacheException(message: NotesError.saveFailed);
    }
  }

  @override
  Stream<List<NoteFolderEntity>> watchFolders() async* {
    yield await getFolders();
    yield* _box
        .watch(key: NotesStorageKeys.foldersKey)
        .asyncMap((_) => getFolders());
  }

  @override
  Future<NotesSettingsEntity> getSettings() async {
    try {
      final raw = _box.get(NotesStorageKeys.settingsKey) as String?;
      if (raw == null || raw.isEmpty) return const NotesSettingsEntity();
      return NotesSettingsMapper.fromRawJsonToEntity(raw);
    } catch (_) {
      throw const CacheException(message: NotesError.loadFailed);
    }
  }

  @override
  Future<void> saveSettings(NotesSettingsEntity settings) async {
    try {
      await _box.put(
        NotesStorageKeys.settingsKey,
        NotesSettingsMapper.toRawJsonFromEntity(settings),
      );
    } catch (_) {
      throw const CacheException(message: NotesError.saveFailed);
    }
  }
}
