import 'package:bimir_lock/core/theme/colors/app_colors.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/quote_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The quotes the opening screen has shown, newest first — for the one that
/// went by too fast. Settings › Quotes › Recently seen quotes.
class QuotesPage extends StatefulWidget {
  static const String routeName = '/quotes';
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  List<SeenQuote>? _seen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<SeenQuote> seen = await QuoteHistory.all();
    if (mounted) setState(() => _seen = seen);
  }

  Future<void> _clear() async {
    final bool sure = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Clear recent quotes?',
      message: 'The list starts again with the next quote you see.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      dialogType: DialogType.danger,
    );
    if (!sure) return;
    await QuoteHistory.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final List<SeenQuote>? seen = _seen;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent quotes'),
        actions: [
          if (seen != null && seen.isNotEmpty)
            TextButton(onPressed: _clear, child: const Text('Clear all')),
        ],
      ),
      body: PageBody(
        top: false,
        child: seen == null
            ? const SizedBox.shrink()
            : seen.isEmpty
            ? const EmptyMessage(
                icon: LucideIcons.quote,
                title: 'No quotes yet',
                body:
                    'The quotes you see when Bimir Lock opens will be listed here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.only(
                  top: Space.sm,
                  bottom: Space.xxl,
                ),
                itemCount: seen.length,
                separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                itemBuilder: (BuildContext context, int i) =>
                    _QuoteTile(seen: seen[i]),
              ),
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({required this.seen});

  final SeenQuote seen;

  String _when(DateTime at) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(at.year, at.month, at.day);
    final String time = DateFormat.jm().format(at);
    if (day == today) return 'Today, $time';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    }
    return DateFormat.yMMMd().format(at);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    final Quote q = seen.quote;
    final String attribution = q.source == null
        ? q.author
        : '${q.author}, ${q.source}';
    return Panel(
      child: InkWell(
        onLongPress: () async {
          await Clipboard.setData(
            ClipboardData(text: '“${q.text}” — $attribution'),
          );
          showNote('Quote copied');
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.lg,
            Space.lg,
            Space.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(
                  '“',
                  style: TextStyle(
                    fontFamily: AppFonts.sans,
                    fontSize: 32,
                    height: 0.9,
                    fontWeight: FontWeight.w700,
                    color: s.primary,
                  ),
                ),
              ),
              Text(
                q.text,
                style: t.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                attribution,
                style: t.bodyMedium?.copyWith(color: s.primary),
              ),
              const SizedBox(height: Space.sm),
              Text(
                _when(seen.at),
                style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
