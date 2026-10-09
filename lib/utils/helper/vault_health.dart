import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/ui/password_tools.dart';

/// Which saved passwords need attention. Worked out on the passwords the vault
/// list already holds in memory; nothing is stored or sent anywhere.
class VaultHealth {
  VaultHealth._(this.weak, this.reused, this._reuseCount);

  /// Entries rated weak or very weak.
  final Set<int> weak;

  /// Entries whose password is also used by at least one other entry.
  final Set<int> reused;

  final Map<int, int> _reuseCount;

  static final VaultHealth empty = VaultHealth._(
    <int>{},
    <int>{},
    <int, int>{},
  );

  /// How many OTHER entries share this entry's password.
  int sharedWith(PasswordTable entry) {
    final int? id = entry.id;
    return id == null ? 0 : (_reuseCount[id] ?? 0);
  }

  bool isWeak(PasswordTable entry) =>
      entry.id != null && weak.contains(entry.id);
  bool isReused(PasswordTable entry) =>
      entry.id != null && reused.contains(entry.id);

  int get attention => (<int>{...weak, ...reused}).length;

  static VaultHealth of(Iterable<PasswordTable> entries) {
    final Set<int> weak = <int>{};
    final Map<String, List<int>> byPassword = <String, List<int>>{};
    for (final PasswordTable e in entries) {
      final int? id = e.id;
      final String pw = e.password ?? '';
      // A locked entry's value is unknown: never guess about it.
      if (id == null || e.locked || pw.isEmpty) continue;
      if (estimateStrength(pw).segments <= 1) weak.add(id);
      byPassword.putIfAbsent(pw, () => <int>[]).add(id);
    }
    final Set<int> reused = <int>{};
    final Map<int, int> count = <int, int>{};
    for (final List<int> ids in byPassword.values) {
      if (ids.length < 2) continue;
      for (final int id in ids) {
        reused.add(id);
        count[id] = ids.length - 1;
      }
    }
    return VaultHealth._(weak, reused, count);
  }
}
