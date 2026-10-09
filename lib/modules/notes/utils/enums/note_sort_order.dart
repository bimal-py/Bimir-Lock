/// How the notes list is ordered. Persisted with the user's notes settings.
enum NoteSortOrder {
  /// By last-edited time, newest first.
  newest,

  /// By last-edited time, oldest first.
  oldest,

  /// By creation time, newest first.
  created,
  alphabetical,
  alphabeticalReverse;

  String get label => switch (this) {
    NoteSortOrder.newest => 'Last edited (newest)',
    NoteSortOrder.oldest => 'Last edited (oldest)',
    NoteSortOrder.created => 'Date created (newest)',
    NoteSortOrder.alphabetical => 'Title (A–Z)',
    NoteSortOrder.alphabeticalReverse => 'Title (Z–A)',
  };

  static NoteSortOrder fromName(String? name) => NoteSortOrder.values
      .firstWhere((s) => s.name == name, orElse: () => NoteSortOrder.newest);
}
