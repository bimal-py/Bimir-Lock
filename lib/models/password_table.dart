List<PasswordTable> passwordfromJson(List<dynamic> passwordsJson) =>
    passwordsJson
        .map((passwordJson) => PasswordTable.fromJson(passwordJson))
        .toList();

class PasswordTable {
  int? id;
  String? title;
  String? userName;
  String? password;

  /// Optional, multi-line. Sealed like [password], and for the same reason
  /// absent from [toJson].
  String? note;

  /// True when the stored note will not open under the verified key. Like
  /// [locked], the bytes on disk are then left exactly as they are: a save
  /// does not write the note column at all.
  bool noteLocked;

  /// True when this row's stored value is a structurally valid envelope that
  /// will not open under the verified key. The password is NOT displayed, NOT
  /// copied and NOT written back: the bytes on disk are left exactly as they
  /// are. Never persisted - it is a per read classification, not model data.
  bool locked;

  PasswordTable({
    this.id,
    this.title,
    this.userName,
    this.password,
    this.note,
    this.locked = false,
    this.noteLocked = false,
  });

  PasswordTable.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        userName = json['userName'],
        password = json['password'],
        note = json['note'],
        locked = false,
        noteLocked = false;

  /// NOTE: `password` and `note` are deliberately absent.
  ///
  /// This is the enforcement mechanism for "nothing writes the password column
  /// without encrypting it", not a style choice. Encryption is asynchronous and
  /// needs the platform channel, so it cannot live in a pure synchronous model
  /// - and if it cannot live here, then no caller may be able to smuggle a
  /// plaintext password into a row map through toJson(). A future write path
  /// that forgets to encrypt therefore writes NO password (the row keeps its
  /// old value: recoverable, and loud in testing) instead of writing plaintext
  /// (silent, and permanent). DataBaseHelper is the only producer of a row map
  /// that carries a password, and it always encrypts.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (userName != null) data['userName'] = userName;
    return data;
  }
}
