import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/faq_search.dart';
import 'package:bimir_lock/views/faq/faq_entries.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Questions people ask about Bimir Lock, and a search that understands how
/// they ask them — the Callbreak Tracker app's FAQ, in this app's design.
/// Settings › Help › FAQ.
///
/// Browsed by topic when nothing is typed. Searched, it opens the question
/// that was plainly asked as the best match and lists the related ones under
/// it, so a half-remembered question still finds its answer.
class FaqPage extends StatefulWidget {
  static const String routeName = '/faq';
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  static final FaqSearch _search = FaqSearch(faqEntries);

  /// What people tend to wonder first — tapping one searches it.
  static const List<String> _tryThese = <String>[
    'forgot my PIN',
    'move to a new phone',
    'turn on autofill',
    'is it encrypted',
  ];

  final TextEditingController _query = TextEditingController();
  FaqTopic? _topic;
  final Set<FaqEntry> _open = <FaqEntry>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _searchFor(String text) {
    _query
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    setState(_open.clear);
  }

  @override
  Widget build(BuildContext context) {
    final String query = _query.text.trim();
    final FaqResults? results = query.isEmpty ? null : _search.search(query);
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: PageBody(
        top: false,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.sm,
                Space.gutter,
                Space.md,
              ),
              child: _SearchField(
                controller: _query,
                onChanged: (_) => setState(_open.clear),
                onClear: () => _searchFor(''),
              ),
            ),
            // Topics while browsing. Searching, the results speak for
            // themselves.
            if (query.isEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  children: [
                    _TopicChip(
                      label: 'All',
                      selected: _topic == null,
                      onTap: () => setState(() => _topic = null),
                    ),
                    for (final FaqTopic topic in FaqTopic.values)
                      _TopicChip(
                        label: topic.label,
                        selected: _topic == topic,
                        onTap: () => setState(() => _topic = topic),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.md,
                  Space.gutter,
                  Space.xxl,
                ),
                children: results == null
                    ? _browse(context)
                    : _found(context, query, results),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Every question, by topic.
  List<Widget> _browse(BuildContext context) {
    final List<FaqEntry> shown = <FaqEntry>[
      for (final FaqEntry entry in faqEntries)
        if (_topic == null || entry.topic == _topic) entry,
    ];
    return <Widget>[
      if (_topic == null) ...[
        _Hint(ideas: _tryThese, onIdea: _searchFor),
        const SizedBox(height: Space.lg),
      ],
      for (final FaqEntry entry in shown) _entry(entry),
    ];
  }

  /// What a search turned up.
  List<Widget> _found(BuildContext context, String query, FaqResults found) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    if (found.isEmpty) {
      return <Widget>[
        const SizedBox(height: Space.xxl),
        Icon(LucideIcons.searchX, size: 40, color: s.onSurfaceVariant),
        const SizedBox(height: Space.md),
        Text(
          'Nothing on "$query" yet.',
          textAlign: TextAlign.center,
          style: t.titleMedium,
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Try fewer words, or clear the search to browse by topic.',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        ),
      ];
    }
    return <Widget>[
      if (found.best != null) ...[
        _SectionLabel(text: 'Best match', colour: s.primary),
        _entry(found.best!, open: true),
      ],
      if (found.related.isNotEmpty) ...[
        if (found.best != null) const SizedBox(height: Space.md),
        _SectionLabel(
          text: found.best == null
              ? 'Did you mean one of these?'
              : 'Related questions',
          colour: s.onSurfaceVariant,
        ),
        for (final FaqEntry entry in found.related) _entry(entry),
      ],
    ];
  }

  Widget _entry(FaqEntry entry, {bool open = false}) {
    final bool isOpen = open || _open.contains(entry);
    return _FaqCard(
      entry: entry,
      open: isOpen,
      onTap: () => setState(() {
        if (_open.contains(entry) || open) {
          _open.remove(entry);
        } else {
          _open.add(entry);
        }
      }),
    );
  }
}

/// The pill search field, as on the vault.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    final OutlineInputBorder pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        hintText: 'Ask anything, like "forgot PIN"',
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
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: onClear,
              ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// How to search, with a few questions to try.
class _Hint extends StatelessWidget {
  const _Hint({required this.ideas, required this.onIdea});

  final List<String> ideas;
  final ValueChanged<String> onIdea;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type a question in your own words. It understands PIN or passcode, '
          'Face ID or fingerprint, export or backup, and small typos. Or try:',
          style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final String idea in ideas)
              ActionChip(
                avatar: Icon(LucideIcons.search, size: 16, color: s.primary),
                label: Text(idea),
                onPressed: () => onIdea(idea),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.colour});

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Space.xs, bottom: Space.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colour),
      ),
    );
  }
}

/// A question that opens to its answer.
class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.entry,
    required this.open,
    required this.onTap,
  });

  final FaqEntry entry;
  final bool open;
  final VoidCallback onTap;

  static const Map<FaqTopic, IconData> _icons = <FaqTopic, IconData>{
    FaqTopic.unlock: LucideIcons.keyRound,
    FaqTopic.passwords: LucideIcons.lockKeyhole,
    FaqTopic.autofill: LucideIcons.textCursorInput,
    FaqTopic.backup: LucideIcons.hardDriveDownload,
    FaqTopic.privacy: LucideIcons.shieldCheck,
    FaqTopic.app: LucideIcons.smartphone,
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Panel(
        borderColor: open ? s.primary.withValues(alpha: 0.5) : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icons[entry.topic], size: 18, color: s.primary),
                    const SizedBox(width: Space.md),
                    Expanded(child: Text(entry.question, style: t.titleSmall)),
                    const SizedBox(width: Space.sm),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: MediaQuery.of(context).disableAnimations
                          ? Duration.zero
                          : Motion.fast,
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: s.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (open) ...[
                  const SizedBox(height: Space.sm),
                  Padding(
                    padding: const EdgeInsets.only(left: 18 + Space.md),
                    child: Text(
                      entry.answer,
                      style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
