/// Whether folders or notes lead the grid. Persisted with the notes settings.
enum NoteGrouping {
  foldersFirst,
  filesFirst;

  String get label => switch (this) {
    NoteGrouping.foldersFirst => 'Folders first',
    NoteGrouping.filesFirst => 'Notes first',
  };

  bool get foldersLead => this == NoteGrouping.foldersFirst;

  static NoteGrouping fromName(String? name) => NoteGrouping.values.firstWhere(
    (g) => g.name == name,
    orElse: () => NoteGrouping.foldersFirst,
  );
}
