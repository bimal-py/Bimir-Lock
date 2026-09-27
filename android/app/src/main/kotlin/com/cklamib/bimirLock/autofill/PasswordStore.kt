package com.cklamib.bimirLock.autofill

import android.content.ContentValues
import android.content.Context
import android.database.DatabaseErrorHandler
import android.database.sqlite.SQLiteDatabase
import android.util.Log
import com.cklamib.bimirLock.crypto.VaultCrypto

// Writes credentials straight into the sqflite database the Flutter app already uses.
// Path, schema and PRAGMA user_version must stay identical to lib/utils/helper/db_helper.dart.
// Passwords are AES-256-GCM sealed by VaultCrypto before they ever reach SQLite: Kotlin, Dart
// and Swift share the "v1:" envelope byte for byte, so a value written here is readable by the
// app and vice versa. Nothing in this file ever reads the password column back.
object PasswordStore {

    private const val TAG = "BimirAutofill"

    // Must match DbConstant in lib/utils/helper/db_constants.dart.
    private const val DB_NAME = "BimirLockPasswords"
    private const val DB_VERSION = 1
    private const val TABLE = "PasswordTable"
    private const val COL_ID = "id"
    private const val COL_TITLE = "title"
    private const val COL_USERNAME = "userName"
    private const val COL_PASSWORD = "password"

    // Plaintext shadow used ONLY by the Dart migration, for the microseconds between writing
    // an envelope and verifying it back off disk. Every write here explicitly clears it.
    private const val COL_PASSWORD_LEGACY = "password_legacy"

    private const val META_TABLE = "VaultMeta"
    private const val COL_META_KEY = "key"
    private const val COL_META_VALUE = "value"
    private const val KCV_KEY = "kcv_v1"

    private const val MAX_FIELD_LENGTH = 512

    enum class Result { INSERTED, UPDATED, SKIPPED, FAILED }

    // Serialises our own writes so two save requests never fight each other.
    @Synchronized
    fun save(context: Context, rawTitle: String?, rawUserName: String?, rawPassword: String?): Result {
        val title = cleanLabel(rawTitle)
        val userName = cleanLabel(rawUserName)
        val password = cleanSecret(rawPassword)

        if (password.isEmpty()) return Result.SKIPPED
        if (title.isEmpty() && userName.isEmpty()) return Result.SKIPPED

        var db: SQLiteDatabase? = null
        return try {
            db = open(context) ?: return Result.FAILED
            db.beginTransaction()
            try {
                ensureSchema(db)
                // INVARIANT K, and the proof that the key we are about to seal under is the vault's
                // key. False means we return without marking the transaction successful, so
                // nothing at all is written.
                if (!kcvGate(db, context)) return Result.FAILED
                // Seal only now. VaultCrypto.encrypt() never creates a key, so on a first run
                // it needs the key kcvGate() just established; sealing earlier is what used
                // to leave an orphan key behind whenever the gate then refused. Keystore work
                // inside the transaction costs milliseconds, and the key check above already
                // runs here. There is deliberately NO plaintext fallback: a skipped save is
                // recoverable by the user in seconds, a surprise plaintext row is a silent
                // security regression nobody would notice.
                val sealed = try {
                    VaultCrypto.encrypt(context.applicationContext, password)
                } catch (t: Throwable) {
                    Log.w(TAG, "encrypt failed: ${t.javaClass.simpleName}")
                    return Result.FAILED
                }
                // An empty userName is not an identity. The parser legitimately fails to
                // find one (password-only screens, unrecognised fields), so (title, "")
                // would collide across unrelated accounts and the update below would
                // destroy the older password. Insert instead: a duplicate row is
                // recoverable, an overwritten password is not.
                val existingId = if (userName.isEmpty()) null else findRowId(db, title, userName)
                val outcome: Result
                if (existingId != null) {
                    val values = ContentValues()
                    values.put(COL_PASSWORD, sealed)
                    // Drop any stale plaintext the migration may have shadowed for this row.
                    values.putNull(COL_PASSWORD_LEGACY)
                    // whereArgs are Strings; the id column has INTEGER affinity so SQLite
                    // converts "12" back to 12 before comparing. Same thing sqflite does.
                    db.update(TABLE, values, "$COL_ID = ?", arrayOf(existingId.toString()))
                    outcome = Result.UPDATED
                } else {
                    val values = ContentValues()
                    values.put(COL_TITLE, title)
                    values.put(COL_USERNAME, userName)
                    values.put(COL_PASSWORD, sealed)
                    values.putNull(COL_PASSWORD_LEGACY)
                    // 'email' is left out on purpose: PasswordTable.toJson() never writes it.
                    db.insertOrThrow(TABLE, null, values)
                    outcome = Result.INSERTED
                }
                db.setTransactionSuccessful()
                outcome
            } finally {
                try {
                    db.endTransaction()
                } catch (t: Throwable) {
                    Log.w(TAG, "endTransaction failed: ${t.javaClass.simpleName}")
                }
            }
        } catch (t: Throwable) {
            // Never log the value itself, only the failure class.
            Log.w(TAG, "save failed: ${t.javaClass.simpleName}")
            Result.FAILED
        } finally {
            try {
                db?.close()
            } catch (t: Throwable) {
                Log.w(TAG, "close failed: ${t.javaClass.simpleName}")
            }
        }
    }

    private fun open(context: Context): SQLiteDatabase? {
        val app = context.applicationContext
        val file = try {
            // Same absolute path sqflite resolves: getDatabasesPath() + "/BimirLockPasswords".
            app.getDatabasePath(DB_NAME)
        } catch (t: Throwable) {
            Log.w(TAG, "getDatabasePath failed: ${t.javaClass.simpleName}")
            return null
        }

        val parent = file.parentFile
        if (parent != null && !parent.exists()) {
            try {
                parent.mkdirs()
            } catch (t: Throwable) {
                Log.w(TAG, "mkdirs failed: ${t.javaClass.simpleName}")
            }
            if (!parent.exists()) {
                Log.w(TAG, "databases directory unavailable")
                return null
            }
        }

        // One attempt only. SQLite already waits on its own 2500 ms busy timeout, and the
        // system gives the whole save request 5 s, so sleeping and retrying on top of that
        // risks blowing the budget instead of saving.
        return try {
            // No ENABLE_WRITE_AHEAD_LOGGING: sqflite keeps WAL off and the mode is
            // sticky in the file header, so turning it on here would change it for the app too.
            // The 4-arg overload is API 11; the OpenParams one is API 27, above our floor of 26.
            SQLiteDatabase.openDatabase(
                file.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.CREATE_IF_NECESSARY,
                KeepFileOnCorruption
            )
        } catch (t: Throwable) {
            Log.w(TAG, "open failed: ${t.javaClass.simpleName}")
            null
        }
    }

    // sqflite's openDatabase(version: 1) reads PRAGMA user_version and re-runs its onCreate
    // whenever it reads 0. If we created the file and left it at 0 the app's next open would
    // run CREATE TABLE against tables that already exist, the open would throw, and every
    // password would disappear from the UI. So create every table and stamp the version.
    // Schema state is derived from the table's actual shape, never from a version number:
    // this is idempotent and safe to run on every open, in either order with the Dart side.
    // Runs inside the caller's transaction.
    private fun ensureSchema(db: SQLiteDatabase) {
        db.execSQL(
            "create table if not exists PasswordTable (" +
                "id integer primary key autoincrement, title text, userName text, email text, " +
                "password text, password_legacy text)"
        )
        db.execSQL(
            "create table if not exists QuotesTable (" +
                "id integer primary key autoincrement, quote text, author text)"
        )
        db.execSQL(
            "create table if not exists QuotesCategoryTable (" +
                "id integer primary key autoincrement, quoteCategory text)"
        )
        db.execSQL(
            "create table if not exists VaultMeta (key text primary key, value text)"
        )
        // An existing v1 install has PasswordTable but not the shadow column. This must
        // precede the version stamp below, and it must share this transaction.
        addColumnIfMissing(db, TABLE, COL_PASSWORD_LEGACY, "text")
        // Only ever raise it. A newer app version may have set a higher number.
        if (db.version < DB_VERSION) {
            db.version = DB_VERSION
        }
    }

    // ALTER TABLE ADD COLUMN with no DEFAULT is an O(1) metadata-only change. Do not add a
    // DEFAULT: that would rewrite every row of the vault for nothing.
    private fun addColumnIfMissing(db: SQLiteDatabase, table: String, column: String, type: String) {
        if (columnNames(db, table).contains(column)) return
        try {
            db.execSQL("alter table $table add column $column $type")
        } catch (t: Throwable) {
            // Only reachable when PRAGMA table_info could not be read and the column was in
            // fact already there. A genuinely missing column surfaces on the write below,
            // which fails the save rather than damaging anything.
            Log.w(TAG, "add column skipped: ${t.javaClass.simpleName}")
        }
    }

    // Table name is a compile-time constant; PRAGMA takes no bind parameters.
    private fun columnNames(db: SQLiteDatabase, table: String): Set<String> {
        val names = HashSet<String>()
        db.rawQuery("pragma table_info($table)", null).use { cursor ->
            val nameIndex = cursor.getColumnIndex("name")
            if (nameIndex < 0) return names
            while (cursor.moveToNext()) {
                if (!cursor.isNull(nameIndex)) names.add(cursor.getString(nameIndex))
            }
        }
        return names
    }

    // INVARIANT K. Called inside save()'s transaction, after ensureSchema and before any
    // write. False means: do not write anything at all, return FAILED.
    //
    // Kotlin deliberately does NOT implement INVARIANT R (replacing a stale key check value
    // when nothing is encrypted yet). A mismatch here just skips this one autofill save and
    // lets the app repair the vault on its next launch, where the user can be told about it.
    private fun kcvGate(db: SQLiteDatabase, context: Context): Boolean {
        val app = context.applicationContext
        val stored = try {
            readMeta(db, KCV_KEY)
        } catch (t: Throwable) {
            Log.w(TAG, "kcv read failed: ${t.javaClass.simpleName}")
            return false
        }

        if (stored == null) {
            // INVARIANT K: every writer (this one and the Dart gate) stores the check value
            // before or together with its first envelope. So with no check value, nothing in
            // the table was sealed by us, and a "v1:..." value there is a user's password
            // that merely looks like an envelope, e.g. an API token. Refusing here (as a
            // prefix count once did) would block saves on a perfectly ordinary vault.
            val fresh = try {
                VaultCrypto.ensureKey(app, null)
            } catch (t: Throwable) {
                Log.w(TAG, "ensureKey failed: ${t.javaClass.simpleName}")
                return false
            }
            return try {
                val values = ContentValues()
                values.put(COL_META_KEY, KCV_KEY)
                values.put(COL_META_VALUE, fresh)
                // Same transaction as the row write that follows, so a row can never exist
                // without the check value that proves which key opens it.
                val rowId = db.insertWithOnConflict(
                    META_TABLE, null, values, SQLiteDatabase.CONFLICT_REPLACE
                )
                // insertWithOnConflict reports failure by returning -1 instead of throwing.
                // Treating that as success would write an encrypted row with no key check
                // value, which is exactly the INVARIANT K violation this gate exists to stop.
                if (rowId == -1L) {
                    Log.w(TAG, "kcv insert rejected; refusing to write")
                    false
                } else {
                    true
                }
            } catch (t: Throwable) {
                Log.w(TAG, "kcv write failed: ${t.javaClass.simpleName}")
                false
            }
        }

        return try {
            VaultCrypto.ensureKey(app, stored) == stored
        } catch (t: Throwable) {
            Log.w(TAG, "kcv verify failed: ${t.javaClass.simpleName}")
            false
        }
    }

    private fun readMeta(db: SQLiteDatabase, key: String): String? {
        val sql = "select $COL_META_VALUE from $META_TABLE where $COL_META_KEY = ? limit 1"
        db.rawQuery(sql, arrayOf(key)).use { cursor ->
            return if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getString(0) else null
        }
    }

    // ---- fill (read) side ----------------------------------------------------

    class Entry(val id: Long, val title: String, val userName: String)

    private const val MAX_ENTRIES = 500

    // Titles and usernames only. Those are stored in the clear (only passwords are
    // sealed), so listing them needs no key. Never creates the database.
    fun listEntries(context: Context): List<Entry> {
        val db = openForRead(context) ?: return emptyList()
        return try {
            val out = ArrayList<Entry>()
            val sql = "select $COL_ID, ifnull($COL_TITLE, ''), ifnull($COL_USERNAME, '') " +
                "from $TABLE where ifnull($COL_PASSWORD, '') != '' order by $COL_ID"
            db.rawQuery(sql, null).use { cursor ->
                while (cursor.moveToNext() && out.size < MAX_ENTRIES) {
                    out.add(Entry(cursor.getLong(0), cursor.getString(1), cursor.getString(2)))
                }
            }
            out
        } catch (t: Throwable) {
            Log.w(TAG, "list failed: ${t.javaClass.simpleName}")
            emptyList()
        } finally {
            try { db.close() } catch (t: Throwable) { }
        }
    }

    // Call ONLY after the user has authenticated. Null on any failure: a fill that
    // does not happen is fine, a wrong value typed into a login form is not.
    fun revealPassword(context: Context, id: Long): String? {
        val db = openForRead(context) ?: return null
        return try {
            val stored = db.rawQuery(
                "select $COL_PASSWORD from $TABLE where $COL_ID = ? limit 1", arrayOf(id.toString())
            ).use { cursor ->
                if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getString(0) else null
            } ?: return null
            // INVARIANT K: with no check value nothing in the table was sealed by us, so the
            // stored value IS the password (a vault the app has not migrated yet).
            val kcv = try { readMeta(db, KCV_KEY) } catch (t: Throwable) { null }
                ?: return stored
            val app = context.applicationContext
            // Proves this is the vault's key before trusting decode(): under any other key
            // a real envelope would fail its tag and read back as "plaintext".
            VaultCrypto.ensureKey(app, kcv)
            VaultCrypto.decode(app, stored).value
        } catch (t: Throwable) {
            Log.w(TAG, "reveal failed: ${t.javaClass.simpleName}")
            null
        } finally {
            try { db.close() } catch (t: Throwable) { }
        }
    }

    private fun openForRead(context: Context): SQLiteDatabase? {
        return try {
            val file = context.applicationContext.getDatabasePath(DB_NAME)
            if (!file.exists()) return null
            SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY)
        } catch (t: Throwable) {
            Log.w(TAG, "open for read failed: ${t.javaClass.simpleName}")
            null
        }
    }

    // Table and column names are compile-time constants; every value is bound.
    private fun findRowId(db: SQLiteDatabase, title: String, userName: String): Long? {
        val sql = "select $COL_ID from $TABLE " +
            "where ifnull($COL_TITLE, '') = ? and ifnull($COL_USERNAME, '') = ? " +
            "order by $COL_ID limit 1"
        db.rawQuery(sql, arrayOf(title, userName)).use { cursor ->
            return if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getLong(0) else null
        }
    }

    // Labels: strip control chars, collapse to a trimmed value, cap length.
    private fun cleanLabel(value: String?): String = clean(value, trim = true)

    // Secrets: strip control chars (a NUL would truncate the string on the Dart
    // side) but never trim -- leading/trailing spaces can be part of the password.
    private fun cleanSecret(value: String?): String = clean(value, trim = false)

    private fun clean(value: String?, trim: Boolean): String {
        if (value.isNullOrEmpty()) return ""
        val builder = StringBuilder(value.length)
        for (ch in value) {
            if (ch.code >= 0x20 && ch.code != 0x7F) builder.append(ch)
        }
        var out = builder.toString()
        if (trim) out = out.trim()
        if (out.length > MAX_FIELD_LENGTH) out = out.substring(0, MAX_FIELD_LENGTH)
        // never leave half a surrogate pair, whatever produced the string
        if (out.isNotEmpty() && Character.isHighSurrogate(out[out.length - 1])) {
            out = out.substring(0, out.length - 1)
        }
        return out
    }

    // Android's default handler DELETES the file when SQLite reports corruption.
    // That would wipe the whole vault, so we log and let the save fail instead.
    private object KeepFileOnCorruption : DatabaseErrorHandler {
        override fun onCorruption(db: SQLiteDatabase) {
            Log.w(TAG, "database reported corrupt; leaving the file in place")
        }
    }
}
