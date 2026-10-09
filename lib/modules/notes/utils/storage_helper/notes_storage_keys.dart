class NotesStorageKeys {
  NotesStorageKeys._();

  static const String boxName = 'notes_box';

  // Hive box entries.
  static const String notesKey = '${boxName}_list';
  static const String foldersKey = '${boxName}_folders';
  static const String settingsKey = '${boxName}_settings';
}
