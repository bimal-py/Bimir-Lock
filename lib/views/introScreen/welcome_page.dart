import 'dart:async';

import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/core/theme/colors/app_colors.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/quote_book.dart';
import 'package:bimir_lock/views/homePage/home_page.dart';
import 'package:bimir_lock/views/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The launch screen: the logo (carried up from the splash), a greeting,
/// one quote about keeping things safe, then the vault. The thin line at the
/// bottom shows how long the quote stays; tap anywhere to go on at once.
class WelcomePage extends StatefulWidget {
  static const String routeName = "/welcome";
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  final CoreController cc = Get.find<CoreController>();
  late final AnimationController _timer = AnimationController(vsync: this)
    ..addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) _continue();
    });
  // The words arrive once the logo has settled from its flight.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Quote? _quote;
  bool _leaving = false;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    // The vault loads (and decrypts) while the quote is read, so the vault
    // screen's first frame is its finished list, not a spinner swapped out
    // under the gliding logo.
    if (!Get.isRegistered<HomePageController>()) Get.put(HomePageController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      // The splash picks the quote while it waits, so it is on the first
      // frame rather than popping in during the logo's glide.
      final Object? picked = ModalRoute.of(context)?.settings.arguments;
      picked is Quote ? _show(picked) : _next();
    }
    if (_enter.isDismissed) {
      Motion.reduced(context) ? _enter.value = 1 : _enter.forward();
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    _enter.dispose();
    super.dispose();
  }

  Widget _rise(Interval interval, Widget child) {
    final Animation<double> a = CurvedAnimation(
      parent: _enter,
      curve: interval,
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  Future<void> _next() async {
    final Quote q = await QuoteBook.random();
    if (!mounted) return;
    setState(() => _show(q));
  }

  void _show(Quote q) {
    _quote = q;
    // Readable again later in Settings › Quotes.
    unawaited(QuoteHistory.add(q));
    // About 2.5 s plus reading time, within 3–7 s.
    final int ms = (2500 + q.text.length * 40).clamp(3000, 7000);
    _timer
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0);
  }

  void _continue() {
    if (_leaving) return;
    _leaving = true;
    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      HomePage.routeName,
      (route) => false,
    );
  }

  String get _hello {
    final int h = DateTime.now().hour;
    return h >= 5 && h < 12
        ? 'Good morning'
        : h >= 12 && h < 17
        ? 'Good afternoon'
        : h >= 17 && h < 22
        ? 'Good evening'
        : 'Hello';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    final Quote? q = _quote;
    final String? name = cc.firstName;
    // Smaller in landscape, where height is short.
    final double logo = (MediaQuery.sizeOf(context).height * 0.09).clamp(
      48.0,
      72.0,
    );

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: PageBody(
          maxWidth: Space.maxNarrow + Space.gutter * 2,
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.lg, Space.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              BrandHero(size: logo),
              const SizedBox(height: Space.lg),
              _rise(
                const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
                Text(
                  name == null ? _hello : '$_hello, $name',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Space.xxl),
              // The card hangs from the greeting; whatever height is left
              // over sits under it, above the hint.
              Expanded(
                flex: 12,
                child: _rise(
                  const Interval(0.45, 1, curve: Curves.easeOutCubic),
                  AnimatedSwitcher(
                    duration: Motion.reduced(context)
                        ? Duration.zero
                        : Motion.slow,
                    layoutBuilder: (Widget? current, List<Widget> previous) =>
                        Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[...previous, ?current],
                        ),
                    child: q == null
                        ? const SizedBox.shrink()
                        : _QuoteCard(key: ValueKey<String>(q.text), quote: q),
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              Icon(LucideIcons.lockKeyholeOpen, size: 26, color: s.primary),
              const SizedBox(height: Space.sm),
              Text(
                'Tap anywhere to open your vault',
                style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: [
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _timer,
                      builder: (BuildContext context, _) =>
                          LinearProgressIndicator(
                            value: _timer.value,
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                            color: s.primary,
                            backgroundColor: s.surfaceContainerHighest,
                          ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  IconButton(
                    tooltip: 'Another quote',
                    onPressed: _next,
                    icon: Icon(
                      LucideIcons.refreshCw,
                      size: 20,
                      color: s.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The quote in an outlined card: a crimson quotation mark between two
/// hairlines, the words, who said them. Scaled down as a whole when it would
/// not fit, so a long quote with very large system text still shows complete.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ColorScheme s = Theme.of(context).colorScheme;
    // Up to 72 wide, narrower when a small phone and large text leave less.
    Widget rule() => Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 72),
        child: Container(height: 1, color: s.outlineVariant),
      ),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final Widget body = Container(
          width: box.maxWidth,
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.xl,
            Space.xl,
            Space.xxl,
          ),
          decoration: BoxDecoration(
            color: s.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: s.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  rule(),
                  const SizedBox(width: Space.lg),
                  ExcludeSemantics(
                    // An opening quote mark sits high in its line; drop it so
                    // it lines up with the rules beside it.
                    child: Transform.translate(
                      offset: const Offset(0, 11),
                      child: Text(
                        '\u201C',
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 48,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: s.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.lg),
                  rule(),
                ],
              ),
              const SizedBox(height: Space.xl),
              Text(
                quote.text,
                textAlign: TextAlign.center,
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: Space.xl),
              Text(
                quote.author,
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(color: s.primary),
              ),
              if (quote.source != null) ...[
                const SizedBox(height: Space.xs),
                Text(
                  quote.source!,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: box.maxHeight),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: body,
          ),
        );
      },
    );
  }
}
