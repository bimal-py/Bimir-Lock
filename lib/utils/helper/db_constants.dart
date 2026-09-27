class DbConstant {
  static const String dbName = "BimirLockPasswords";
  //for password table
  static const String passwordTableName = "PasswordTable";
  static const String id = "id";
  static const String title = "title";
  static const String userName = "userName";
  static const String email = "email";
  static const String password = "password";

  // Plaintext shadow column used ONLY by the vault migration, for the few
  // microseconds between writing a row's ciphertext and verifying that
  // ciphertext back off disk. Never part of the model, never written by any
  // normal write path (every write explicitly NULLs it).
  static const String passwordLegacy = "password_legacy";

  //for quote table
  static const String quoteTableName = "QuotesTable";
  static const String quote = "quote";
  static const String author = "author";

  //for quote category table
  static const String quoteCategoryTableName = "QuotesCategoryTable";
  static const String quoteCategory = "quoteCategory";

  //for the vault bookkeeping table (key check value, vacuum marker)
  static const String vaultMetaTableName = "VaultMeta";
  static const String metaKey = "key";
  static const String metaValue = "value";
}
