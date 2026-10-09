/// Notes listing layout. Persisted with the notes settings.
enum NoteViewMode {
  grid,
  list;

  bool get isGrid => this == NoteViewMode.grid;

  NoteViewMode get toggled =>
      this == NoteViewMode.grid ? NoteViewMode.list : NoteViewMode.grid;

  static NoteViewMode fromName(String? name) => NoteViewMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => NoteViewMode.grid,
  );
}
