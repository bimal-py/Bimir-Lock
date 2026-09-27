import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/models/quote_category_model.dart';
import 'package:bimir_lock/models/quote_model.dart';
import 'package:bimir_lock/utils/helper/db_constants.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_migration.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class DataBaseHelper {
  static Database? _db;
  static Future<Database>? _opening;

  // iOS only. Answers with the App Group container directory the future
  // AutoFill extension can also reach. It NEVER answers with a fallback path.
  static const MethodChannel _nativeChannel =
      MethodChannel('com.cklamib.bimirLock/native');

  /// Where the database file lives.
  ///
  /// The guard is a POSITIVE `Platform.isIOS` test, deliberately. A negative
  /// test (`!Platform.isAndroid`) or `defaultTargetPlatform` would also catch
  /// desktop and the test host, and routing an existing Android user to a path
  /// that does not exist makes sqflite create a fresh empty file and run
  /// _onCreate: the user opens the app to an empty vault while the real one
  /// sits untouched on disk. The Android branch stays a bare
  /// `getDatabasesPath()` so the path string remains byte identical to the one
  /// PasswordStore.kt resolves with getDatabasePath("BimirLockPasswords").
  Future<String> _databaseDirectory() async {
    if (Platform.isIOS) {
      final String? dir =
          await _nativeChannel.invokeMethod<String>('databaseDirectory');
      if (dir == null || dir.isEmpty) {
        throw StateError(
          'App Group container unavailable; refusing to open a fallback '
          'database.',
        );
      }
      return dir;
    }
    return getDatabasesPath();
  }

  Future<Database> initDb() async {
    final dbPath = await _databaseDirectory();
    final path = "$dbPath/${DbConstant.dbName}";
    var finalDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return finalDb;
  }

  Future<Database> get getDatabase async {
    final Database? open = _db;
    if (open != null) return open;
    final Future<Database>? pending = _opening;
    if (pending != null) return pending;
    final Future<Database> started = _open();
    _opening = started;
    try {
      return await started;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async {
    final Database db = await initDb();
    // Idempotent, content driven DDL. Runs on EVERY open, unconditionally,
    // never gated on a version number, because either side (Dart or the
    // Android autofill service) may have created this file.
    await _ensureVaultSchema(db);
    // Awaited, and it never throws: it only records health.
    await VaultMigration.instance.gate(db);
    _db = db;
    // Unawaited so it never blocks the first frame. Single flight.
    unawaited(VaultMigration.instance.run(db));
    return db;
  }

  /// CREATE TABLE IF NOT EXISTS everywhere, plus a PRAGMA table_info guard
  /// before the one ALTER TABLE. Safe to run any number of times, in any
  /// order, whichever side created the file. This is what deletes the whole
  /// "no such column: password_legacy" failure class.
  Future<void> _ensureVaultSchema(Database db) async {
    await db.execute('''
      create table if not exists ${DbConstant.passwordTableName} ( 
        ${DbConstant.id} integer primary key autoincrement, 
        ${DbConstant.title} text,
        ${DbConstant.userName} text,
        ${DbConstant.email} text,
        ${DbConstant.password} text,
        ${DbConstant.passwordLegacy} text)
      ''');
    await db.execute('''
      create table if not exists ${DbConstant.quoteTableName} ( 
        ${DbConstant.id} integer primary key autoincrement, 
        ${DbConstant.quote} text,
        ${DbConstant.author} text)
      ''');
    await db.execute('''
      create table if not exists ${DbConstant.quoteCategoryTableName} ( 
        ${DbConstant.id} integer primary key autoincrement, 
        ${DbConstant.quoteCategory} text)
      ''');
    await db.execute('''
      create table if not exists ${DbConstant.vaultMetaTableName} (
        ${DbConstant.metaKey} text primary key,
        ${DbConstant.metaValue} text)
      ''');

    final List<Map<String, Object?>> columns =
        await db.rawQuery('PRAGMA table_info(${DbConstant.passwordTableName})');
    final bool hasLegacyColumn = columns.any(
      (Map<String, Object?> column) =>
          column['name'] == DbConstant.passwordLegacy,
    );
    if (!hasLegacyColumn) {
      // No DEFAULT: that keeps it an O(1) metadata only change.
      try {
        await db.execute('alter table ${DbConstant.passwordTableName} '
            'add column ${DbConstant.passwordLegacy} text');
      } on DatabaseException catch (e) {
        // The Android autofill service runs the same check on its own
        // connection and can add the column between our PRAGMA and ALTER.
        // Losing that race is success; anything else is a real failure.
        if (!e.toString().contains('duplicate column')) rethrow;
      }
    }
  }

  // The schema version is pinned at 1 and never bumped, and NOTHING anywhere
  // consults it to decide whether a column exists. There is deliberately no
  // onUpgrade, no onDowngrade and no onOpen: a throw inside any of them aborts
  // openDatabase entirely (sqflite closes the database and rethrows), leaving
  // the user with an empty vault and no explanation. onDatabaseDowngradeDelete
  // would be worse still: it DELETES the file.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      create table ${DbConstant.passwordTableName} ( 
        ${DbConstant.id} integer primary key autoincrement, 
        ${DbConstant.title} text,
        ${DbConstant.userName} text,
        ${DbConstant.email} text,
        ${DbConstant.password} text,
        ${DbConstant.passwordLegacy} text)
      ''');

    await db.execute('''
      create table ${DbConstant.quoteTableName} ( 
        ${DbConstant.id} integer primary key autoincrement, 
        ${DbConstant.quote} text,
        ${DbConstant.author} text)
      ''');
    await db.execute('''
      create table ${DbConstant.quoteCategoryTableName} ( 
        ${DbConstant.id} integer primary key autoincrement, 
        ${DbConstant.quoteCategory} text)
      ''');
    await db.execute('''
      create table if not exists ${DbConstant.vaultMetaTableName} (
        ${DbConstant.metaKey} text primary key,
        ${DbConstant.metaValue} text)
      ''');
  }

  /// THE ONLY code in lib/ that may put a value into the password column.
  ///
  /// PasswordTable.toJson() cannot carry a password, so every write path has
  /// to come through here, and here always encrypts.
  Future<Map<String, Object?>> _rowFor(PasswordTable data) async {
    final Map<String, Object?> row = Map<String, Object?>.from(data.toJson());
    final String? plain = data.password;
    if (plain != null) {
      row[DbConstant.password] =
          (await VaultCrypto.instance.encryptAll(<String>[plain])).single;
      // Never leave a stale plaintext shadow behind.
      row[DbConstant.passwordLegacy] = null;
    }
    return row;
  }

//for password
  Future<void> insertPassword(PasswordTable data) async {
    try {
      final db = await getDatabase;
      await db.insert(
        DbConstant.passwordTableName,
        await _rowFor(data),
      );
    } catch (e) {
      // Rethrow: a caller must never report success for a save that was
      // dropped. The type only, never the data.
      log("===============>>> Error while inserting: ${e.runtimeType}");
      rethrow;
    }
  }

  /// Restore's bulk insert: one channel round trip per chunk to seal, and each
  /// chunk written in one transaction, so a chunk lands whole or not at all.
  /// Same sealing rule as [_rowFor]: every password is encrypted, never raw.
  /// Returns how many rows were written before any failure (which rethrows).
  Future<int> insertPasswords(List<PasswordTable> rows) async {
    const int chunk = 200;
    int written = 0;
    final db = await getDatabase;
    for (int start = 0; start < rows.length; start += chunk) {
      final List<PasswordTable> part =
          rows.sublist(start, (start + chunk).clamp(0, rows.length));
      final List<String> sealed = await VaultCrypto.instance
          .encryptAll(part.map((PasswordTable r) => r.password ?? '').toList());
      await db.transaction((txn) async {
        for (int i = 0; i < part.length; i++) {
          final Map<String, Object?> row =
              Map<String, Object?>.from(part[i].toJson());
          row[DbConstant.password] = sealed[i];
          row[DbConstant.passwordLegacy] = null;
          await txn.insert(DbConstant.passwordTableName, row);
        }
      });
      written += part.length;
    }
    return written;
  }

  Future<bool> deletePassword(PasswordTable data) async {
    try {
      final db = await getDatabase;

      await db.delete(
        DbConstant.passwordTableName,
        where: '${DbConstant.id} = ?',
        whereArgs: [data.id],
      );
      return true;
    } catch (e) {
      log("===============>>> Error while deleting single password: "
          "${e.runtimeType}");
      return false;
    }
  }

  Future<bool> deleteAllPassword() async {
    try {
      final db = await getDatabase;

      await db.delete(
        DbConstant.passwordTableName,
      );
      return true;
    } catch (e) {
      log("===============>>> Error while deleting all password: "
          "${e.runtimeType}");
      return false;
    }
  }

  /// The single read chokepoint: one batched channel hop for the whole table,
  /// not one per row, and no way for a caller to receive a raw envelope.
  Future<List<PasswordTable>> getAllPassword() async {
    try {
      final db = await getDatabase;

      List<Map<String, Object?>> passwords = await db.query(
        DbConstant.passwordTableName,
      );
      final List<PasswordTable> rows = passwordfromJson(passwords);
      await _openPasswords(rows);
      return rows;
    } catch (e) {
      // NEVER return an empty list here. "You have no passwords" is the single
      // most alarming lie a password manager can tell, and a frightened user
      // clears app data or reinstalls, which is what makes the loss real.
      log("===============>>> Error while reading all password: "
          "${e.runtimeType}");
      rethrow;
    }
  }

  Future<void> _openPasswords(List<PasswordTable> rows) async {
    final List<int> indices = <int>[];
    final List<String> stored = <String>[];
    for (int i = 0; i < rows.length; i++) {
      final String? value = rows[i].password;
      if (value != null &&
          value.isNotEmpty &&
          VaultCrypto.hasEnvelopePrefix(value)) {
        indices.add(i);
        stored.add(value);
      }
    }
    // A vault that holds no envelopes at all costs no channel call.
    if (indices.isEmpty) return;

    final List<VaultValue> opened =
        await VaultCrypto.instance.decryptAll(stored);
    for (int k = 0; k < indices.length; k++) {
      final PasswordTable row = rows[indices[k]];
      final VaultValue value = opened[k];
      switch (value.kind) {
        case VaultValueKind.decrypted:
          row.password = value.value;
          row.locked = false;
          break;
        case VaultValueKind.legacyPlaintext:
          // A real password that begins with "v1:" comes through verbatim.
          row.password = stored[k];
          row.locked = false;
          break;
        case VaultValueKind.damaged:
          // NEVER hand the raw blob to the UI: the user would paste
          // "v1:AAAA..." into a login form and believe it was real.
          row.password = '';
          row.locked = true;
          break;
      }
    }
  }

  Future<bool> updatePassword(PasswordTable data) async {
    try {
      final db = await getDatabase;
      final int updated = await db.update(
        DbConstant.passwordTableName,
        await _rowFor(data),
        where: '${DbConstant.id} = ?',
        whereArgs: [data.id],
      );
      // The old code reported success even when zero rows matched.
      return updated > 0;
    } catch (e) {
      log("===============>>> Error while updating: ${e.runtimeType}");
      return false;
    }
  }

  //for quotes
  Future<void> insertQuote(Quote data) async {
    try {
      final db = await getDatabase;
      await db.insert(
        DbConstant.quoteTableName,
        data.toJson(),
      );
    } catch (e) {
      log("===============>>> Error while inserting: $e");
    }
  }

  Future<void> deleteQuote(Quote data) async {
    try {
      final db = await getDatabase;

      await db.delete(
        DbConstant.quoteTableName,
        where: 'id = ?',
        whereArgs: [data.id],
      );
    } catch (e) {
      log("===============>>> Error while deleting quote: $e");
    }
  }

  Future<void> deleteAllQuotes() async {
    try {
      final db = await getDatabase;

      await db.delete(
        DbConstant.quoteTableName,
      );
    } catch (e) {
      log("===============>>> Error while deleting quote: $e");
    }
  }

  Future<Quote?> getinitialQuotes() async {
    try {
      final db = await getDatabase;
      var values = await db.query(
        DbConstant.quoteTableName,
      );
      if (values.isNotEmpty) {
        math.Random random = math.Random();
        int randomIndex = random.nextInt(values.length);
        return Quote.fromJson(values[randomIndex]);
      } else {
        return Quote(quote: "The body achieves what the mind believes.", author: "Erin Gray");
      }
    } catch (e) {
      log("===============>>> Error while reading all quote: $e");
      return null;
    }
  }

  Future<List<Map<String, Object?>>> getAllQuotes() async {
    try {
      final db = await getDatabase;

      return await db.query(
        DbConstant.quoteTableName,
      );
    } catch (e) {
      log("===============>>> Error while reading all quote: $e");
      return [];
    }
  }

  Future<void> updateQuote(Quote data) async {
    try {
      final db = await getDatabase;

      await db.update(
        DbConstant.quoteTableName,
        data.toJson(),
        where: 'id = ?',
        whereArgs: [data.id],
      );
    } catch (e) {
      log("===============>>> Error while updating: $e");
    }
  }

  //for quotes category
  Future<void> insertQuoteCategory(QuoteCategory data) async {
    try {
      final db = await getDatabase;

      await db
          .insert(
        DbConstant.quoteCategoryTableName,
        data.toJson(),
      )
          .then((value) {
        log("$value");
      });
    } catch (e) {
      log("===============>>> Error while inserting: $e");
    }
  }

  Future<void> deleteQuoteCategory(QuoteCategory data) async {
    try {
      final db = await getDatabase;

      await db.delete(
        DbConstant.quoteCategoryTableName,
        where: 'id = ?',
        whereArgs: [data.id],
      );
    } catch (e) {
      log("===============>>> Error while deleting quote cat: $e");
    }
  }

  Future<void> deleteAllQuoteCategory() async {
    try {
      final db = await getDatabase;

      await db.delete(
        DbConstant.quoteCategoryTableName,
      );
    } catch (e) {
      log("===============>>> Error while deleting quote cat: $e");
    }
  }

  Future<void> getAllQuotesCategory() async {
    try {
      final db = await getDatabase;

      await db.query(
        DbConstant.quoteCategoryTableName,
      );
    } catch (e) {
      log("===============>>> Error while reading all quote cat: $e");
    }
  }

  Future<void> updateQuoteCategory(QuoteCategory data) async {
    try {
      final db = await getDatabase;

      await db.update(
        DbConstant.quoteCategoryTableName,
        data.toJson(),
        where: 'id = ?',
        whereArgs: [data.id],
      );
    } catch (e) {
      log("===============>>> Error while updating: $e");
    }
  }
}
