/// Named routes for the Notes screens. Reminder Note navigates these with
/// go_router (`Routes.addNote` etc.); Bimir Lock uses a plain [Navigator], so
/// each screen is a named route served by `notesGeneratedRoute`.
class NotesRoutes {
  NotesRoutes._();

  /// The notes browser at the root level.
  static const String home = '/notes';

  /// Create / edit a note. Argument: an optional `NoteEntity`.
  static const String addNote = '/notes/add-note';

  /// Read view of a note. Argument: the `NoteEntity`.
  static const String noteDetail = '/notes/note-detail';

  /// A folder's contents. Argument: the folder id (`String`).
  static const String folder = '/notes/folder';

  /// Notes preferences + backup.
  static const String notesSettings = '/notes/notes-settings';

  /// Archived notes.
  static const String notesArchive = '/notes/notes-archive';
}
