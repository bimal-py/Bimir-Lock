import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/vault_health.dart';
import 'package:bimir_lock/views/homePage/entry_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Password Checkup, after Google Password Manager's: what needs attention and
/// why, with each entry one tap away. Worked out on this phone only.
class CheckupPage extends StatelessWidget {
  static const String routeName = '/checkup';
  const CheckupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomePageController c = Get.find<HomePageController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Password Checkup')),
      body: Obx(() {
        final List<PasswordTable> all = c.passwords ?? <PasswordTable>[];
        final VaultHealth h = c.health.value;
        final TextTheme t = Theme.of(context).textTheme;
        final ColorScheme s = Theme.of(context).colorScheme;
        final BimirPalette p = BimirPalette.of(context);
        final bool clean = h.attention == 0;

        // Reused passwords, grouped by the password they share.
        final Map<String, List<PasswordTable>> reused = <String, List<PasswordTable>>{};
        for (final PasswordTable e in all) {
          if (h.isReused(e)) reused.putIfAbsent(e.password ?? '', () => <PasswordTable>[]).add(e);
        }
        final List<PasswordTable> weak =
            all.where((PasswordTable e) => h.isWeak(e) && !h.isReused(e)).toList();

        return PageBody(
          top: false,
          child: ListView(
            children: [
              const SizedBox(height: Space.lg),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: clean ? s.primaryContainer : p.warningSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    clean ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                    size: 40,
                    color: clean ? s.onPrimaryContainer : p.warning,
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              Text(
                clean
                    ? 'Your passwords look good'
                    : '${h.attention} ${h.attention == 1 ? 'password needs' : 'passwords need'} attention',
                style: t.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.sm),
              Text(
                clean
                    ? 'None of your ${all.length} saved passwords is weak or used more than once.'
                    : 'Checked on this phone. Nothing was sent anywhere.',
                style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (reused.isNotEmpty) ...[
                const SizedBox(height: Space.xxl),
                _SectionTitle(
                  icon: LucideIcons.repeat2,
                  title: 'Reused passwords',
                  body: 'If one of these sites leaks, the others are exposed too. Give each its own password.',
                  colour: p.danger,
                ),
                for (final List<PasswordTable> group in reused.values) ...[
                  const SizedBox(height: Space.md),
                  RowGroup(
                    title: 'Same password on ${group.length} sites',
                    children: [for (final PasswordTable e in group) _EntryTile(entry: e)],
                  ),
                ],
              ],
              if (weak.isNotEmpty) ...[
                const SizedBox(height: Space.xxl),
                _SectionTitle(
                  icon: LucideIcons.triangleAlert,
                  title: 'Weak passwords',
                  body: 'Short, common or patterned passwords are guessed quickly. A generated one takes a second.',
                  colour: p.warning,
                ),
                const SizedBox(height: Space.md),
                RowGroup(children: [for (final PasswordTable e in weak) _EntryTile(entry: e)]),
              ],
              const SizedBox(height: Space.xxl),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.body,
    required this.colour,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colour),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.titleMedium),
              const SizedBox(height: 2),
              Text(body, style: t.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final PasswordTable entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      leading: Monogram(entryTitle(entry)),
      title: Text(entryTitle(entry), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(maskUser(entry.userName), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: TextButton(
        onPressed: () => editEntry(context, entry),
        child: const Text('Change'),
      ),
      onTap: () => openEntry(context, entry),
    );
  }
}
