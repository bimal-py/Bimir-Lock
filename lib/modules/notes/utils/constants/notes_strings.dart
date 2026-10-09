class NotesStrings {
  NotesStrings._();

  static const String untitled = 'Untitled note';
  static const String myNotes = 'My notes';
  static const String titleLabel = 'Title';
  static const String titleHint = 'Give your note a name';
  static const String bodyLabel = 'Note';
  static const String bodyHint = 'Start writing…';
  static const String searchHint = 'Search notes';

  static const String emptyTitle = 'No notes yet';
  static const String emptyMessage = 'Tap the + tile to write your first note.';
  static const String emptySearchTitle = 'No matching notes';
  static const String emptySearchMessage = 'Try a different search term.';

  // Archive
  static const String archiveTitle = 'Archive';
  static const String emptyArchiveTitle = 'Nothing archived';
  static const String emptyArchiveMessage =
      'Archived notes are tucked away here, out of your main list.';
  static const String noteArchived = 'Note archived';
  static const String noteRestored = 'Note restored';
  static const String notesArchived = 'Notes archived';
  static const String noteDuplicated = 'Note duplicated';

  static const String checklist = 'Checklist';
  static const String addChecklistItem = 'Add item';

  // Shown after a write succeeds (CustomSnackbar, type: success).
  static const String noteSaved = 'Note saved';
  static const String noteDeleted = 'Note deleted';
  static const String notesDeleted = 'Notes deleted';
  static const String comingSoon = 'Coming soon';

  // Folders
  static const String untitledFolder = 'Untitled folder';
  static const String folders = 'Folders';
  static const String newFolder = 'New folder';
  static const String createFolder = 'Create folder';
  static const String renameFolder = 'Rename folder';
  static const String deleteFolder = 'Delete folder';
  static const String folderName = 'Folder name';
  static const String folderNameHint = 'e.g. Work, Recipes, Ideas';
  static const String folderNameRequired = 'Give the folder a name.';
  static const String moveToFolder = 'Move to folder';
  static const String moveHere = 'Move here';
  static const String root = 'Notes';
  static const String noteMoved = 'Moved';
  static const String foldersNotPinned =
      'Folders can’t be pinned — applied to notes only.';
  static const String foldersNotArchived =
      'Folders can’t be archived — applied to notes only.';
  static const String foldersNotShared =
      'Folders can’t be shared — notes only.';
  static const String folderCreated = 'Folder created';
  static const String folderRenamed = 'Folder renamed';
  static const String folderDeleted = 'Folder deleted';
  static const String emptyFolderTitle = 'This folder is empty';
  static const String emptyFolderMessage =
      'Add a note or a sub-folder to get started.';
  static const String deleteFolderConfirm =
      'Notes and sub-folders inside move back out to where this folder lived — '
      'nothing is deleted.';
  static String folderItemCount(int folders, int notes) {
    final parts = <String>[
      if (folders > 0) '$folders ${folders == 1 ? 'folder' : 'folders'}',
      '$notes ${notes == 1 ? 'note' : 'notes'}',
    ];
    return parts.join(' · ');
  }
}
