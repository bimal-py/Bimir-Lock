import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/controller/backup/backup_controller.dart';
import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/modules/notes/notes_bootstrap.dart';
import 'package:bimir_lock/ui/coach_marks.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/unlock.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/ui/autofill_guide.dart';
import 'package:bimir_lock/ui/intruder_prompt.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:bimir_lock/utils/helper/vault_health.dart';
import 'package:bimir_lock/views/homePage/add_password.dart';
import 'package:bimir_lock/views/homePage/checkup_page.dart';
import 'package:bimir_lock/views/homePage/entry_actions.dart';
import 'package:bimir_lock/views/intruder_page.dart';
import 'package:bimir_lock/views/settings_page.dart';
import 'package:bimir_lock/views/splash_page.dart';
import 'package:bimir_lock/widgets/vault_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:upgrader/upgrader.dart';

/// The vault, laid out like Google Password Manager: a search bar pinned
/// under the title, a Password Checkup card, then every saved site A to Z,
/// with a round Add button at the bottom. Names and a masked username are visible;
/// everything else opens behind the PIN.
class HomePage extends StatelessWidget {
  static const String routeName = "/homePage";
  HomePage({super.key});

  final HomePageController c = Get.put(HomePageController());

  void _add(BuildContext context) {
    if (c.vaultHealth.value == VaultKeyHealth.keyLost) {
      // Fail closed: a write while the key is unusable would either be
      // impossible to encrypt or would overwrite something we cannot read back.
      DialogUtils.showInformationDialog(
        context,
        title: "Vault locked",
        message:
            "Bimir Lock can't unlock your saved passwords on this device, so adding a new one is disabled. Your saved data has not been changed.",
        dialogType: DialogType.warning,
        icon: Icons.lock_outline_rounded,
      );
      return;
    }
    navigatorKey.currentState!.pushNamed(AddPasswordPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return UpgradeAlert(
      showIgnore: false,
      barrierDismissible: false,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Obx(() {
          final List<PasswordTable> all = c.passwords ?? <PasswordTable>[];
          final List<PasswordTable> rows = c.visible;
          final bool empty = all.isEmpty;
          // Read here so children rebuild when only the key's health changes
          // (their own reads are not tracked by this Obx).
          c.vaultHealth.value;
          final bool showAdd = !empty && !c.loading;
          return Scaffold(
            // A crimson circle, and only when there is a list to add to: an
            // empty vault already has its own Add button in the middle.
            floatingActionButton: AnimatedScale(
              scale: showAdd ? 1 : 0,
              duration: Motion.base,
              // Only a target while it is shown: a tour must never point at
              // a button that has shrunk to nothing.
              child: showAdd
                  ? CoachTarget(
                      id: 'vault.add',
                      child: _AddButton(onPressed: () => _add(context)),
                    )
                  : _AddButton(onPressed: () {}),
            ),
            appBar: AppBar(
              titleSpacing: Space.gutter,
              title: Row(
                children: [
                  const BrandHero(size: 32),
                  const SizedBox(width: Space.sm),
                  Flexible(
                    child: Text(
                      'Bimir Lock',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleLarge,
                    ),
                  ),
                ],
              ),
              actions: [
                CoachTarget(
                  id: 'vault.notes',
                  child: RoundIconButton(
                    icon: LucideIcons.notebookPen,
                    tooltip: 'Notes',
                    onPressed: () =>
                        navigatorKey.currentState!.pushNamed(notesHomeRoute),
                  ),
                ),
                const SizedBox(width: Space.sm),
                CoachTarget(
                  id: 'vault.settings',
                  child: RoundIconButton(
                    icon: LucideIcons.settings,
                    tooltip: 'Settings',
                    onPressed: () => navigatorKey.currentState!.pushNamed(
                      SettingsPage.routeName,
                    ),
                  ),
                ),
                const SizedBox(width: Space.gutter - Space.xs),
              ],
            ),
            body: PageBody(
              top: false,
              bottom: false,
              padding: EdgeInsets.zero,
              child: _VaultTour(
                loaded: !c.loading,
                hasList: showAdd,
                child: Column(
                  children: [
                    // Pinned: stays put while the list scrolls. An empty
                    // vault has nothing to search, and its own Add button.
                    if (!empty && !c.loading) _PinnedSearch(c: c),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          await c.loadPasswords();
                        },
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification n) {
                            if (n.depth == 0) {
                              final bool under = n.metrics.pixels > 0.5;
                              if (c.listScrolled.value != under) {
                                c.listScrolled.value = under;
                              }
                            }
                            return false;
                          },
                          child: SlidableAutoCloseBehavior(
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Space.gutter,
                                  ),
                                  sliver: SliverList.list(
                                    children: [
                                      const SizedBox(height: Space.xs),
                                      VaultStatusBanner(controller: c),
                                      const _IntruderBanner(),
                                      if (!empty) ...[
                                        CoachTarget(
                                          id: 'vault.checkup',
                                          child: _CheckupCard(c: c),
                                        ),
                                        const SizedBox(height: Space.xl),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: Space.xs,
                                          ),
                                          child: Text(
                                            c.searchedValue.isEmpty
                                                ? 'Passwords · ${all.length}'
                                                : '${rows.length} of ${all.length}',
                                            style: t.titleSmall?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: Space.sm),
                                      ],
                                    ],
                                  ),
                                ),
                                if (c.loading)
                                  const SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (empty)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Space.gutter,
                                      ),
                                      child: c.vaultError.value != null
                                          // Never let a read failure read as "you have no
                                          // passwords": that is what makes a frightened
                                          // user clear app data. The banner above says
                                          // what happened.
                                          ? const SizedBox.shrink()
                                          : Center(
                                              child: EmptyMessage(
                                                icon: LucideIcons.keyRound,
                                                title: 'No passwords yet',
                                                body:
                                                    'Save your first password. It is encrypted on this phone and opens only with your PIN.',
                                                action: CoachTarget(
                                                  id: 'vault.addFirst',
                                                  child: FilledButton.icon(
                                                    onPressed: () =>
                                                        _add(context),
                                                    icon: const Icon(
                                                      LucideIcons.plus,
                                                      size: 18,
                                                    ),
                                                    label: const Text(
                                                      'Add password',
                                                    ),
                                                  ),
                                                ),
                                                secondary: TextButton.icon(
                                                  onPressed: BackupController()
                                                      .restore,
                                                  icon: const Icon(
                                                    LucideIcons.fileDown,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'Restore from a backup',
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  )
                                else if (rows.isEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Space.gutter,
                                      ),
                                      child: EmptyMessage(
                                        icon: LucideIcons.search,
                                        title: 'No matches',
                                        body:
                                            'No site or username contains "${c.searchedValue}".',
                                        action: TextButton(
                                          onPressed: c.clearSearch,
                                          child: const Text('Clear search'),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  _EntryList(
                                    rows: rows,
                                    health: c.health.value,
                                  ),
                                // Room for the Add button over the last row.
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 96),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Runs the vault's first-time tour once the screen has settled.
/// The vault's first-time tips, in two parts remembered separately. Notes
/// and Settings (and, in an empty vault, the first Add) show on the very
/// first visit. The list tips (Checkup, rows, search, Add) need a list, so
/// they show as soon as there is one: straight away for a vault that already
/// has passwords (one tour with everything), or after the first is saved.
class _VaultTour extends StatefulWidget {
  const _VaultTour({
    required this.loaded,
    required this.hasList,
    required this.child,
  });

  /// The first read of the vault is done, so it is known whether it is empty.
  final bool loaded;
  final bool hasList;
  final Widget child;

  @override
  State<_VaultTour> createState() => _VaultTourState();
}

class _VaultTourState extends State<_VaultTour> {
  @override
  void initState() {
    super.initState();
    if (widget.loaded) _start();
  }

  @override
  void didUpdateWidget(covariant _VaultTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loaded && !oldWidget.loaded ||
        widget.hasList && !oldWidget.hasList) {
      _start();
    }
  }

  void _start() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Whoever saw the old all-in-one tour (kept under [CoachTours.vault])
      // has seen the basics too.
      if (await CoachMarks.store.hasSeen(CoachTours.vault)) {
        await CoachMarks.store.markSeen(CoachTours.vaultBasics);
      }
      if (!mounted) return;
      // Two one-time offers, one after the other and before any tips, so
      // nothing stacks: AutoFill first, then the Wrong PIN alerts photo.
      await AutofillPrompt.maybeShow(context);
      if (!mounted) return;
      await IntruderPrompt.maybeShow(context);
      if (!mounted) return;
      CoachMarks.showParts(
        context,
        delay: const Duration(milliseconds: 900),
        parts: const <(String, List<CoachStep>)>[
          (
            CoachTours.vault,
            <CoachStep>[
              CoachStep(
                targetId: 'vault.checkup',
                title: 'Password Checkup',
                body:
                    'See which passwords are weak or used on more than one site, and fix them.',
              ),
              CoachStep(
                targetId: 'vault.row',
                title: 'Open, swipe, hold',
                body:
                    'Tap to open with your PIN. Swipe right to edit, left to delete. Hold for copy and more.',
              ),
              CoachStep(
                targetId: 'vault.search',
                title: 'Search',
                body: 'Find a site or username as you type.',
              ),
              CoachStep(
                targetId: 'vault.add',
                circle: true,
                title: 'Add a password',
                body: 'Type one in, or let Bimir Lock generate a strong one.',
              ),
            ],
          ),
          (
            CoachTours.vaultBasics,
            <CoachStep>[
              CoachStep(
                targetId: 'vault.addFirst',
                title: 'Add your first password',
                body:
                    'Type one in, or let Bimir Lock generate a strong one. It is encrypted before it is saved.',
              ),
              CoachStep(
                targetId: 'vault.notes',
                circle: true,
                title: 'Notes',
                body:
                    'Everyday notes. They are not encrypted, so keep codes and other secrets in a password\'s own note.',
              ),
              CoachStep(
                targetId: 'vault.settings',
                circle: true,
                title: 'Settings',
                body:
                    'Theme, PIN, Face ID or fingerprint, backups, and these tips again.',
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The search field, pinned under the title. A hairline appears under it
/// once the list scrolls beneath.
class _PinnedSearch extends StatelessWidget {
  const _PinnedSearch({required this.c});

  final HomePageController c;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    return Obx(
      () => AnimatedContainer(
        duration: Motion.fast,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: c.listScrolled.value
                  ? s.outlineVariant
                  : s.outlineVariant.withValues(alpha: 0),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.md,
        ),
        child: CoachTarget(
          id: 'vault.search',
          child: _SearchBar(c: c),
        ),
      ),
    );
  }
}

/// The one filled button on the screen: a crimson circle at the bottom
/// right, where the thumb is.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Add password',
      child: Semantics(
        button: true,
        label: 'Add password',
        child: Material(
          color: s.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 58,
              child: Icon(LucideIcons.plus, size: 26, color: s.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after the keypad locked on someone, until the owner has looked.
/// Reviewing needs the PIN, so it cannot be cleared by whoever was guessing.
class _IntruderBanner extends StatelessWidget {
  const _IntruderBanner();

  Future<void> _review(BuildContext context) async {
    final bool ok = await confirmIdentity(
      context,
      title: 'Wrong PIN alerts',
      message: 'Confirm it is you.',
    );
    if (ok) navigatorKey.currentState!.pushNamed(IntruderPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: IntruderWatch.unseen,
      builder: (BuildContext context, int n, _) {
        if (n == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: Space.lg),
          child: Notice(
            tone: Tone.danger,
            icon: LucideIcons.shieldAlert,
            title: 'Someone tried to get in',
            message: n == 1
                ? 'The keypad locked after too many wrong PINs.'
                : 'The keypad locked $n times after too many wrong PINs.',
            action: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _review(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  alignment: Alignment.centerLeft,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Review'),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A pill-shaped search field, as in Google's apps.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.c});

  final HomePageController c;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final OutlineInputBorder pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: c.searchEditingController,
      onChanged: c.searchPassword,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        hintText: 'Search passwords',
        filled: true,
        fillColor: s.surfaceContainerHigh,
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.xl,
          vertical: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: Space.lg, right: Space.sm),
          child: Icon(LucideIcons.search, size: 20, color: s.onSurfaceVariant),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: c.searchedValue.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: c.clearSearch,
              ),
      ),
    );
  }
}

/// "Password Checkup": the vault's health in one line, opening the full list.
class _CheckupCard extends StatelessWidget {
  const _CheckupCard({required this.c});

  final HomePageController c;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    final VaultHealth h = c.health.value;
    final bool keyLost = c.vaultHealth.value == VaultKeyHealth.keyLost;
    final bool issues = h.attention > 0;
    final List<String> parts = <String>[
      if (h.reused.isNotEmpty) '${h.reused.length} reused',
      if (h.weak.isNotEmpty) '${h.weak.length} weak',
    ];
    final Color tint = issues ? p.warningSoft : s.primaryContainer;
    final Color ink = issues ? p.warning : s.onPrimaryContainer;
    return Panel(
      child: InkWell(
        onTap: keyLost
            ? null
            : () => navigatorKey.currentState!.pushNamed(CheckupPage.routeName),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                child: Icon(
                  issues ? LucideIcons.shieldAlert : LucideIcons.shieldCheck,
                  size: 22,
                  color: ink,
                ),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password Checkup', style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      keyLost
                          ? "Can't be checked right now"
                          : issues
                          ? '${parts.join(' · ')} · tap to fix'
                          : 'No weak or reused passwords',
                      style: t.bodySmall?.copyWith(
                        color: issues ? p.warning : s.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: s.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every entry A to Z in one rounded group, with a letter above each group
/// once the list is long. Built lazily, so thousands of entries scroll as
/// smoothly as ten.
class _EntryList extends StatelessWidget {
  const _EntryList({required this.rows, required this.health});

  final List<PasswordTable> rows;
  final VaultHealth health;

  static String _letter(PasswordTable e) {
    final String first = entryTitle(e).characters.first.toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }

  @override
  Widget build(BuildContext context) {
    final bool letters = rows.length >= 20;
    final List<Object> items = <Object>[];
    String? current;
    for (final PasswordTable e in rows) {
      final String l = _letter(e);
      if (letters && l != current) {
        items.add(l);
        current = l;
      }
      items.add(e);
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int i) {
          final Object item = items[i];
          if (item is String) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                Space.xs,
                i == 0 ? 0 : Space.lg,
                Space.xs,
                Space.sm,
              ),
              child: Eyebrow(item),
            );
          }
          final bool first = i == 0 || items[i - 1] is String;
          final bool last = i + 1 >= items.length || items[i + 1] is String;
          final PasswordTable e = item as PasswordTable;
          final Widget row = _EntryRow(
            entry: e,
            health: health,
            first: first,
            last: last,
          );
          return identical(e, rows.first)
              ? CoachTarget(id: 'vault.row', child: row)
              : row;
        },
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.health,
    required this.first,
    required this.last,
  });

  final PasswordTable entry;
  final VaultHealth health;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    final bool weak = health.isWeak(entry);
    final bool reused = health.isReused(entry);
    final String? flag = entry.locked
        ? "Can't open"
        : reused
        ? 'Reused'
        : weak
        ? 'Weak'
        : null;
    final bool redFlag = entry.locked || reused;
    const Radius r = Radius.circular(Radii.card);
    final BorderRadius shape = BorderRadius.vertical(
      top: first ? r : Radius.zero,
      bottom: last ? r : Radius.zero,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 2),
      child: ClipRRect(
        borderRadius: shape,
        child: Slidable(
          key: ValueKey<int?>(entry.id),
          groupTag: 'vault',
          // Swipe right: edit. Swipe left: delete. Both still ask for the PIN.
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.26,
            children: [
              SlidableAction(
                onPressed: (_) => editEntry(context, entry),
                backgroundColor: s.primaryContainer,
                foregroundColor: s.onPrimaryContainer,
                icon: LucideIcons.pencil,
                label: 'Edit',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.26,
            children: [
              SlidableAction(
                onPressed: (_) => deleteEntry(context, entry),
                backgroundColor: s.errorContainer,
                foregroundColor: s.onErrorContainer,
                icon: LucideIcons.trash2,
                label: 'Delete',
              ),
            ],
          ),
          child: Material(
            color: s.surfaceContainerLow,
            child: InkWell(
              onTap: () => openEntry(context, entry),
              onLongPress: () => showEntryActions(context, entry),
              child: Semantics(
                button: true,
                hint:
                    'Opens with your PIN. Swipe right to edit, left to delete, or hold for more.',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.md,
                  ),
                  child: Row(
                    children: [
                      Monogram(entryTitle(entry)),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entryTitle(entry),
                              style: t.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              maskUser(entry.userName),
                              style: t.bodySmall?.copyWith(
                                color: s.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (flag != null) ...[
                        const SizedBox(width: Space.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: redFlag ? p.dangerSoft : p.warningSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            flag,
                            style: t.labelSmall?.copyWith(
                              color: redFlag ? s.onErrorContainer : p.warning,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: Space.xs),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: s.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
