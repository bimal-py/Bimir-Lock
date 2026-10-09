class NotesError {
  NotesError._();

  // Thrown from the data layer — surfaced by AppErrorHandler.
  static const String loadFailed = 'Could not load your notes.';
  static const String saveFailed = 'Could not save your note. Try again.';

  // Shown in the UI.
  /// Heading for the failed-to-load state on the notes screen.
  static const String loadFailedTitle = 'Unable to load notes';

  /// Body fallback when the load fails without a specific cache message.
  static const String loadFailedMessage =
      'Something went wrong loading your notes. Please try again.';
}
