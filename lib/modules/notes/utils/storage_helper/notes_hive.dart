import 'package:hive_flutter/hive_flutter.dart';
import 'package:bimir_lock/modules/notes/utils/storage_helper/notes_storage_keys.dart';

extension HiveNotesBoxExtension on HiveInterface {
  Future<Box<dynamic>> openNotesBox() =>
      Hive.openBox<dynamic>(NotesStorageKeys.boxName);

  Box<dynamic> get notesBox => Hive.box<dynamic>(NotesStorageKeys.boxName);

  Future<int> clearNotesBox() => notesBox.clear();
}
