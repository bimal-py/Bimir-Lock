import 'dart:async';

import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import 'package:bimir_lock/utils/helper/vault_crypto.dart';

/// The vault gate and the plaintext -> ciphertext row pass.
///
/// Everything here is content driven, resumable and idempotent. There is NO
/// schema version involved: state is derived from the actual bytes in each row,
/// so an interrupted run is simply picked up where it stopped, at any
/// granularity, any number of times.
///
/// NOTHING in this file may ever log, print or persist a password, an envelope
/// or key material.

/// What one pass of the row migration did. Counts only; never values.
class MigrationResult {
  int total = 0;
  int converted = 0;
  int alreadyDone = 0;
  int skippedEmpty = 0;
  int skippedBusy = 0;
  int failed = 0;
  int recovered = 0;
  final List<String> damagedTitles = <String>[];
  bool keyLost = false;
  bool halted = false;
  bool vacuumed = false;

  bool get isClean =>
      !halted &&
      failed == 0 &&
      recovered == 0 &&
      skippedBusy == 0 &&
      damagedTitles.isEmpty;

  bool get didWork => converted > 0;

  @override
  String toString() => 'MigrationResult(total: $total, converted: $converted, '
      'alreadyDone: $alreadyDone, skippedEmpty: $skippedEmpty, '
      'skippedBusy: $skippedBusy, failed: $failed, recovered: $recovered, '
      'damaged: ${damagedTitles.length}, keyLost: $keyLost, halted: $halted, '
      'vacuumed: $vacuumed)';
}

/// Per row state, derived purely from content. See the spec's state machine.
enum _RowState {
  /// password is plaintext, no shadow. The row to convert.
  legacy,

  /// password is an envelope, shadow still present. The crash window.
  written,

  /// password is an envelope, no shadow. Finished.
  done,

  /// password will not open but the plaintext shadow survives.
  recover,

  /// a structurally valid envelope that fails its tag under a verified key.
  /// Terminal and unrecoverable: never touched, never re-encrypted.
  damaged,

  /// nothing to protect.
  empty,
}

class VaultMigration {
  VaultMigration._();

  static final VaultMigration instance = VaultMigration._();

  static const int chunkSize = 50;
  static const String metaTable = 'VaultMeta';
  static const String kcvMetaKey = 'kcv_v1';
  static const String vacuumMetaKey = 'vacuum_v1';

  /// The public constant the key check value is the envelope of. Not a secret.
  static const String kcvPlaintext = 'bimirlock.kcv.v1';

  final Rx<VaultKeyHealth> health = VaultKeyHealth.unknown.obs;
  final RxBool keyLost = false.obs;
  final Rxn<MigrationResult> lastResult = Rxn<MigrationResult>();

  Database? _db;
  Future<MigrationResult>? _inFlight;

  bool get canWrite => health.value == VaultKeyHealth.ok;

  // ---------------------------------------------------------------------------
  // THE GATE. Runs once per launch, awaited, before any row is touched.
  // It must NEVER throw: it records health and returns.
  // ---------------------------------------------------------------------------
  Future<void> gate(Database db) async {
    _db = db;
    try {
      // Count only rows that could STRUCTURALLY be one of our envelopes. The
      // "v1:" prefix on its own is a pre-filter, never a decision: a real user
      // password that happens to start with "v1:" is not ciphertext and must
      // not be able to halt the migration.
      final int liveEnvelopes = await _countLiveEnvelopes(db);
      final String? storedKcv = await _readMeta(db, kcvMetaKey);

      if (storedKcv == null || storedKcv.isEmpty) {
        // CASE 1/2 - first run. INVARIANT K: every writer (this gate, and the
        // Android autofill service in the same transaction as its row) stores
        // the check value before its first envelope, so with no check value
        // nothing here was sealed by us. Any "v1:"+base64 row is a user's
        // password that only LOOKS like an envelope (an API token, say).
        // Halting on it once locked the whole vault; now it is plaintext.
        //
        // Still safe if a key survives without its check value: ensureKey()
        // with no check value LOADS an existing key and only creates one when
        // none exists, so rows it sealed still open and are recognised.
        final VaultKeyProbe probe = await VaultCrypto.instance.ensureKey();
        await _writeMeta(db, kcvMetaKey, probe.newKeyCheckValue);
        _setHealth(VaultKeyHealth.ok);
        return;
      }

      try {
        // CASE 3 - the normal path.
        await VaultCrypto.instance.ensureKey(keyCheckValue: storedKcv);
        _setHealth(VaultKeyHealth.ok);
        return;
      } on VaultKeyUnavailable catch (e) {
        if (e.code != 'kcv_mismatch') {
          // CASE 6 - transient. Recoverable on a later launch. Do NOT tell the
          // user their data is gone.
          _setHealth(VaultKeyHealth.unavailable);
          return;
        }
        if (liveEnvelopes > 0) {
          // CASE 5 - the key changed under live ciphertext. Terminal, read
          // only. NEVER regenerate, NEVER re-encrypt.
          _setHealth(VaultKeyHealth.keyLost);
          return;
        }
        // CASE 4 - INVARIANT R. Nothing in the vault is encrypted, so the
        // stale key check value can be replaced with nothing lost.
        await _deleteMeta(db, kcvMetaKey);
        final VaultKeyProbe probe = await VaultCrypto.instance.ensureKey();
        await _writeMeta(db, kcvMetaKey, probe.newKeyCheckValue);
        _setHealth(VaultKeyHealth.ok);
        return;
      }
    } catch (e) {
      // Never propagate: a throw here would surface in every database call,
      // including the ones that have nothing to do with passwords.
      _setHealth(VaultKeyHealth.unavailable);
    }
  }

  // ---------------------------------------------------------------------------
  // THE ROW PASS. Single flight, chunked, resumable, no explicit transaction.
  // ---------------------------------------------------------------------------
  Future<MigrationResult> run(Database db) {
    final Future<MigrationResult>? pending = _inFlight;
    if (pending != null) return pending;
    final Future<MigrationResult> started = _run(db).whenComplete(() {
      _inFlight = null;
    });
    _inFlight = started;
    return started;
  }

  Future<MigrationResult> _run(Database db) async {
    _db = db;
    final MigrationResult result = MigrationResult();
    if (health.value != VaultKeyHealth.ok) {
      result.halted = true;
      result.keyLost = health.value == VaultKeyHealth.keyLost;
      lastResult.value = result;
      return result;
    }

    int cursor = 0;
    bool completedFullScan = true;
    try {
      outer:
      while (true) {
        // The cursor is derived from the id and persisted nowhere, so an
        // interruption costs at most one chunk of re-scanning and zero
        // progress. Crypto happens OUTSIDE any transaction.
        final List<Map<String, Object?>> rows = await db.rawQuery(
          'select id, title, password, password_legacy from PasswordTable '
          'where id > ? order by id limit ?',
          <Object?>[cursor, chunkSize],
        );
        if (rows.isEmpty) break;
        cursor = _asInt(rows.last['id']);
        result.total += rows.length;

        final List<_RowState> states = await _classifyChunk(rows);
        for (int i = 0; i < rows.length; i++) {
          final bool keepGoing =
              await _migrateRow(db, rows[i], states[i], result);
          if (!keepGoing) {
            completedFullScan = false;
            result.halted = true;
            break outer;
          }
        }
      }
    } on VaultKeyUnavailable catch (e) {
      completedFullScan = false;
      result.halted = true;
      _setHealth(e.code == 'kcv_mismatch'
          ? VaultKeyHealth.keyLost
          : VaultKeyHealth.unavailable);
    } catch (e) {
      completedFullScan = false;
      result.halted = true;
      result.failed++;
    }

    if (completedFullScan) {
      await _maybeVacuum(db, result);
    }
    result.keyLost = health.value == VaultKeyHealth.keyLost;
    lastResult.value = result;
    return result;
  }

  /// One channel round trip per chunk, and none at all for a chunk that holds
  /// no structurally valid envelopes (the common case on a legacy vault).
  Future<List<_RowState>> _classifyChunk(
      List<Map<String, Object?>> rows) async {
    final List<int> indices = <int>[];
    final List<String> candidates = <String>[];
    for (int i = 0; i < rows.length; i++) {
      final Object? stored = rows[i]['password'];
      if (stored is String && VaultCrypto.isStructurallyEnvelope(stored)) {
        indices.add(i);
        candidates.add(stored);
      }
    }
    final Map<int, VaultValue> opened = <int, VaultValue>{};
    if (candidates.isNotEmpty) {
      final List<VaultValue> values =
          await VaultCrypto.instance.decryptAll(candidates);
      for (int k = 0; k < indices.length; k++) {
        opened[indices[k]] = values[k];
      }
    }

    return <_RowState>[
      for (int i = 0; i < rows.length; i++)
        _stateOf(
          rows[i]['password'],
          rows[i]['password_legacy'],
          opened[i],
        ),
    ];
  }

  _RowState _stateOf(Object? stored, Object? shadow, VaultValue? opened) {
    if (stored is! String || stored.isEmpty) return _RowState.empty;
    final bool hasShadow = shadow is String && shadow.isNotEmpty;
    // No decrypt attempt means the value cannot structurally be an envelope,
    // which is exactly the plaintext classification.
    final VaultValueKind kind = opened?.kind ?? VaultValueKind.legacyPlaintext;
    switch (kind) {
      case VaultValueKind.decrypted:
        return hasShadow ? _RowState.written : _RowState.done;
      case VaultValueKind.legacyPlaintext:
        return hasShadow ? _RowState.recover : _RowState.legacy;
      case VaultValueKind.damaged:
        return hasShadow ? _RowState.recover : _RowState.damaged;
    }
  }

  /// Returns false to HALT the whole pass.
  Future<bool> _migrateRow(
    Database db,
    Map<String, Object?> row,
    _RowState state,
    MigrationResult result,
  ) async {
    final int id = _asInt(row['id']);
    final String? stored = row['password'] as String?;
    final String? shadow = row['password_legacy'] as String?;

    switch (state) {
      case _RowState.empty:
        result.skippedEmpty++;
        return true;

      case _RowState.done:
        result.alreadyDone++;
        return true;

      case _RowState.damaged:
        // Leave the bytes EXACTLY as they are. Re-encrypting them would
        // destroy the last trace of a row that might one day be recoverable.
        final Object? title = row['title'];
        result.damagedTitles.add(title is String && title.isNotEmpty
            ? title
            : 'Entry #$id');
        return true;

      case _RowState.written:
        // The crash window: the envelope is on disk and verified openable, the
        // shadow is still there. Release the shadow, but only once the opened
        // value is confirmed to be the shadow byte for byte.
        final List<VaultValue> opened =
            await VaultCrypto.instance.decryptAll(<String>[stored!]);
        if (!opened.single.isDecrypted || opened.single.value != shadow) {
          // Should be unreachable: T1 writes both from one plaintext. If it
          // ever happens, keep BOTH copies and be loud rather than clever.
          result.failed++;
          return true;
        }
        await db.rawUpdate(
          'update PasswordTable set password_legacy = null '
          'where id = ? and password = ?',
          <Object?>[id, stored],
        );
        result.converted++;
        return true;

      case _RowState.recover:
        // The ciphertext will not open but the plaintext shadow survives.
        // Restore it and HALT: whatever broke the key will break every other
        // row too.
        await db.rawUpdate(
          'update PasswordTable set password = password_legacy, '
          'password_legacy = null '
          'where id = ? and password_legacy is not null',
          <Object?>[id],
        );
        result.recovered++;
        _setHealth(VaultKeyHealth.keyLost);
        return false;

      case _RowState.legacy:
        return _convertLegacyRow(db, id, stored!, result);
    }
  }

  /// The actual conversion. The ORDERING is the safety.
  Future<bool> _convertLegacyRow(
    Database db,
    int id,
    String plain,
    MigrationResult result,
  ) async {
    // (b) seal.
    final String envelope;
    try {
      envelope = (await VaultCrypto.instance.encryptAll(<String>[plain])).single;
    } on VaultKeyUnavailable catch (e) {
      _setHealth(e.code == 'kcv_mismatch'
          ? VaultKeyHealth.keyLost
          : VaultKeyHealth.unavailable);
      return false;
    } catch (e) {
      result.failed++;
      return true;
    }

    // (c) VERIFY BEFORE DESTROY #1, in memory, BEFORE any write.
    try {
      final VaultValue check =
          (await VaultCrypto.instance.decryptAll(<String>[envelope])).single;
      if (!check.isDecrypted || check.value != plain) {
        result.failed++;
        return true;
      }
    } on VaultKeyUnavailable catch (e) {
      _setHealth(e.code == 'kcv_mismatch'
          ? VaultKeyHealth.keyLost
          : VaultKeyHealth.unavailable);
      return false;
    } catch (e) {
      result.failed++;
      return true;
    }

    // (d) T1, compare and swap. The value guard means a write that landed
    // since our SELECT (the autofill service saving a password, say) is never
    // clobbered: 0 rows affected simply means skip, and the next pass picks
    // the row up. `is` not `=`, because SQL `= null` is never true.
    final int swapped = await db.rawUpdate(
      'update PasswordTable set password = ?, password_legacy = ? '
      'where id = ? and password is ?',
      <Object?>[envelope, plain, id, plain],
    );
    if (swapped == 0) {
      result.skippedBusy++;
      return true;
    }

    // (e) VERIFY BEFORE DESTROY #2, FROM DISK. Catches encoding, truncation
    // and NUL handling that an in-memory compare cannot.
    bool readsBack = false;
    bool keyFailed = false;
    try {
      final List<Map<String, Object?>> rows = await db.rawQuery(
        'select password from PasswordTable where id = ?',
        <Object?>[id],
      );
      final Object? reread = rows.isEmpty ? null : rows.first['password'];
      if (reread is String && reread.isNotEmpty) {
        final VaultValue opened =
            (await VaultCrypto.instance.decryptAll(<String>[reread])).single;
        readsBack = opened.isDecrypted && opened.value == plain;
      }
    } on VaultKeyUnavailable {
      keyFailed = true;
    } catch (e) {
      readsBack = false;
    }

    if (!readsBack) {
      // T2 - roll the row back. The plaintext survives.
      await db.rawUpdate(
        'update PasswordTable set password = password_legacy, '
        'password_legacy = null '
        'where id = ? and password_legacy is not null',
        <Object?>[id],
      );
      result.failed++;
      result.recovered++;
      if (keyFailed) {
        _setHealth(VaultKeyHealth.unavailable);
        return false;
      }
      return true;
    }

    // (f) T3 - release the shadow. Only now, after the ciphertext round
    // tripped twice: once in memory and once off disk.
    await db.rawUpdate(
      'update PasswordTable set password_legacy = null '
      'where id = ? and password = ?',
      <Object?>[id, envelope],
    );
    result.converted++;
    return true;
  }

  /// SQLite does not zero freed pages, so after in place UPDATEs every
  /// pre-migration plaintext is still sitting in the file. Without this the
  /// migration would be theatre for exactly the users it exists to protect.
  ///
  /// Honest limitation: VACUUM rebuilds the database file, but it cannot
  /// scrub blocks the filesystem itself has retained.
  Future<void> _maybeVacuum(Database db, MigrationResult result) async {
    if (!result.isClean) return;
    try {
      final int shadows = _firstInt(await db.rawQuery(
        'select count(*) from PasswordTable where password_legacy is not null',
      ));
      if (shadows != 0) return;
      if (await _readMeta(db, vacuumMetaKey) != null) return;
      await db.execute('VACUUM');
      await _writeMeta(db, vacuumMetaKey, 'done');
      result.vacuumed = true;
    } catch (e) {
      // SQLITE_BUSY (the autofill service may have the file open) or anything
      // else: do NOT record the marker. It is retried on a later launch.
    }
  }

  /// Re-probes after a transient failure. A keyLost vault is terminal for this
  /// launch and is never re-probed: a second probe is exactly the thing that
  /// could mint a new key over live ciphertext.
  Future<MigrationResult?> retry() async {
    final Database? db = _db;
    if (db == null) return lastResult.value;
    if (health.value == VaultKeyHealth.keyLost) return lastResult.value;
    if (health.value != VaultKeyHealth.ok) {
      await gate(db);
    }
    if (health.value != VaultKeyHealth.ok) return lastResult.value;
    return run(db);
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------
  Future<int> _countLiveEnvelopes(Database db) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "select password from PasswordTable where password like 'v1:%'",
    );
    int count = 0;
    for (final Map<String, Object?> row in rows) {
      final Object? value = row['password'];
      if (value is String && VaultCrypto.isStructurallyEnvelope(value)) {
        count++;
      }
    }
    return count;
  }

  Future<String?> _readMeta(Database db, String key) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'select value from VaultMeta where key = ? limit 1',
      <Object?>[key],
    );
    if (rows.isEmpty) return null;
    final Object? value = rows.first['value'];
    return value is String ? value : null;
  }

  Future<void> _writeMeta(Database db, String key, String value) async {
    await db.rawInsert(
      'insert or replace into VaultMeta (key, value) values (?, ?)',
      <Object?>[key, value],
    );
  }

  Future<void> _deleteMeta(Database db, String key) async {
    await db.rawDelete(
      'delete from VaultMeta where key = ?',
      <Object?>[key],
    );
  }

  void _setHealth(VaultKeyHealth value) {
    if (value != VaultKeyHealth.ok) {
      // Fail closed for the rest of this launch: no display of raw bytes, no
      // re-encryption and above all no write.
      VaultCrypto.instance.invalidate();
    }
    health.value = value;
    keyLost.value = value == VaultKeyHealth.keyLost;
  }

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;

  static int _firstInt(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return 0;
    final Object? value = rows.first.values.first;
    return value is num ? value.toInt() : 0;
  }

  /// Test only. Puts the singleton back to a pristine launch state.
  void resetForTesting() {
    _db = null;
    _inFlight = null;
    health.value = VaultKeyHealth.unknown;
    keyLost.value = false;
    lastResult.value = null;
  }
}
