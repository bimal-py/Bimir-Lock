import Foundation
import SQLite3

/// Read-only access to the vault from the AutoFill extension.
///
/// The app keeps the database in the App Group container (AppDelegate.databaseDirectory)
/// precisely so this separate process can open it. The extension NEVER writes: it cannot run
/// the app's migration and must not race it. Titles and usernames are stored in the clear
/// (only passwords are sealed), so listing needs no key; a password is opened only after the
/// user has authenticated, under a key first proven against the vault's check value.
///
/// Nothing here logs, prints or keeps a password beyond returning it.
struct VaultEntry {
    let id: Int64
    let title: String
    let userName: String
}

enum VaultStoreError: Error {
    /// The app has never created its database in the App Group (not opened since installing
    /// this version, or the group is missing from the signing profile).
    case noDatabase
    case unreadable
    /// The key on this device is not the key the vault was sealed with, or is missing.
    case keyUnavailable
}

enum VaultStore {
    private static let appGroupId = "group.com.cklamib.bimirLock"
    private static let dbName = "BimirLockPasswords"
    private static let maxEntries = 500

    private static func databaseURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("Database", isDirectory: true)
            .appendingPathComponent(dbName)
    }

    private static func open() throws -> OpaquePointer {
        guard let url = databaseURL(), FileManager.default.fileExists(atPath: url.path) else {
            throw VaultStoreError.noDatabase
        }
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let handle = db else {
            sqlite3_close(db)
            throw VaultStoreError.unreadable
        }
        // The app may be writing at this moment; wait briefly rather than fail.
        sqlite3_busy_timeout(handle, 2000)
        return handle
    }

    static func listEntries() throws -> [VaultEntry] {
        let db = try open()
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        let sql = "select id, ifnull(title, ''), ifnull(userName, '') from PasswordTable "
            + "where ifnull(password, '') != '' order by id limit \(maxEntries)"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw VaultStoreError.unreadable
        }
        defer { sqlite3_finalize(statement) }
        var out: [VaultEntry] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            out.append(VaultEntry(
                id: sqlite3_column_int64(statement, 0),
                title: text(statement, 1) ?? "",
                userName: text(statement, 2) ?? ""))
        }
        return out
    }

    /// Call ONLY after the user has authenticated.
    static func password(id: Int64) throws -> String {
        let db = try open()
        defer { sqlite3_close(db) }

        guard let stored = try single(db, "select password from PasswordTable where id = ? limit 1", id: id) else {
            throw VaultStoreError.unreadable
        }
        // INVARIANT K: with no check value nothing in the table was sealed by the app, so the
        // stored value IS the password. A missing VaultMeta table (older schema) means the same.
        guard let kcv = try? single(db, "select value from VaultMeta where key = 'kcv_v1' limit 1", id: nil) else {
            return stored
        }
        do {
            // Proves this is the vault's key before trusting decode(): under any other key a
            // real envelope would fail its tag and read back as "plaintext". Never creates a key.
            _ = try VaultCrypto.ensureKey(storedKcv: kcv)
            guard let value = try VaultCrypto.decode(stored).value else {
                throw VaultStoreError.unreadable
            }
            return value
        } catch is VaultStoreError {
            throw VaultStoreError.unreadable
        } catch {
            throw VaultStoreError.keyUnavailable
        }
    }

    private static func single(_ db: OpaquePointer, _ sql: String, id: Int64?) throws -> String? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw VaultStoreError.unreadable
        }
        defer { sqlite3_finalize(statement) }
        if let id = id { sqlite3_bind_int64(statement, 1, id) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return text(statement, 0)
    }

    private static func text(_ statement: OpaquePointer?, _ column: Int32) -> String? {
        guard let raw = sqlite3_column_text(statement, column) else { return nil }
        return String(cString: raw)
    }
}
