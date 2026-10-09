import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/ui/lock_glyph.dart';
import 'package:bimir_lock/ui/password_tools.dart';
import 'package:bimir_lock/ui/secret.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/views/user/add_user_detail.dart';
import 'package:bimir_lock/utils/constants.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// First run. Each page shows a real piece of the app you can touch instead
/// of an illustration: reveal a password, watch the lock, generate one.
class IntroductionPage extends StatefulWidget {
  static const String routeName = "/introduction";
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final PageController _pages = PageController();
  int _index = 0;

  static const int _count = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    navigatorKey.currentState!.pushNamed(AddUserDetailPage.routeName);
  }

  void _nextPage() {
    if (_index == _count - 1) return _finish();
    _pages.nextPage(
      duration: Motion.reduced(context)
          ? const Duration(milliseconds: 1)
          : Motion.slow,
      curve: Motion.curve,
    );
  }

  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        maxWidth: Space.maxNarrow + Space.gutter * 2,
        // The slides run edge to edge so each carries its own side padding:
        // mid-swipe that leaves a gap between two slides instead of their
        // cards touching. Everything else gets the gutter here.
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const SizedBox(height: Space.lg),
            _gutter(
              Row(
                children: [
                  const LogoMark(size: 32),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Bimir Lock',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_index < _count - 1)
                    TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (int i) => setState(() => _index = i),
                children: const [
                  _Slide(
                    step: '01',
                    title: 'Locked on this phone',
                    body:
                        'Passwords are encrypted with a key kept in this phone\'s secure hardware. Nothing is uploaded, and there is no account to break into.',
                    demo: _RevealDemo(),
                  ),
                  _Slide(
                    step: '02',
                    title: 'Only you can open it',
                    body:
                        'Every password opens with a 6-digit PIN you choose, or your fingerprint or face. Seven wrong PINs in a row lock the keypad, and can take a photo of whoever is trying.',
                    demo: _LockDemo(),
                  ),
                  _Slide(
                    step: '03',
                    title: 'Strong passwords, made for you',
                    body:
                        'Generate long random passwords, see which saved ones are weak or used twice, and fill them into other apps.',
                    demo: _GeneratorDemo(),
                  ),
                ],
              ),
            ),
            _gutter(_Progress(index: _index, count: _count)),
            const SizedBox(height: Space.lg),
            _gutter(
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  child: Text(
                    _index == _count - 1 ? 'Set up Bimir Lock' : 'Next',
                  ),
                ),
              ),
            ),
            if (_index == _count - 1) ...[
              const SizedBox(height: Space.sm),
              _gutter(const _LegalLine()),
            ],
            const SizedBox(height: Space.lg),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: Space.xs),
            Expanded(
              child: AnimatedContainer(
                duration: Motion.base,
                height: 3,
                decoration: BoxDecoration(
                  color: i <= index ? p.primary : p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.step,
    required this.title,
    required this.body,
    required this.demo,
  });

  final String step;
  final String title;
  final String body;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) =>
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Space.xl),
                  demo,
                  const SizedBox(height: Space.xxl),
                  Text(
                    step,
                    style: BimirPalette.figure(context, color: p.primary),
                  ),
                  const SizedBox(height: Space.sm),
                  Text(title, style: t.headlineMedium),
                  const SizedBox(height: Space.md),
                  Text(body, style: t.bodyLarge?.copyWith(color: p.muted)),
                  const SizedBox(height: Space.xl),
                ],
              ),
            ),
          ),
    );
  }
}

/// A panel the demos sit in, so they read as "a piece of the app".
class _DemoPanel extends StatelessWidget {
  const _DemoPanel({required this.child, this.caption});

  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Panel(padding: const EdgeInsets.all(Space.lg), child: child),
        ),
        if (caption != null) ...[
          const SizedBox(height: Space.sm),
          Text(caption!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _RevealDemo extends StatefulWidget {
  const _RevealDemo();

  @override
  State<_RevealDemo> createState() => _RevealDemoState();
}

class _RevealDemoState extends State<_RevealDemo> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final BimirPalette p = BimirPalette.of(context);
    return _DemoPanel(
      caption: 'Try it: tap the eye.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Monogram('Mail'),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mail', style: t.titleMedium),
                    Text('you@example.com', style: t.bodySmall),
                  ],
                ),
              ),
              LockGlyph(
                open: _shown,
                size: 24,
                color: _shown ? p.success : p.muted,
              ),
            ],
          ),
          const Divider(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: SecretText(
                  value: 'kR9#vM2!pX7@wQ',
                  revealed: _shown,
                  size: 18,
                ),
              ),
              IconButton(
                tooltip: _shown ? 'Hide' : 'Show',
                onPressed: () => setState(() => _shown = !_shown),
                icon: Icon(_shown ? LucideIcons.eyeOff : LucideIcons.eye),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockDemo extends StatelessWidget {
  const _LockDemo();

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    return _DemoPanel(
      child: Row(
        children: [
          LockGlyph(size: 56, color: p.foreground),
          const SizedBox(width: Space.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The real keypad's dots: two typed, the third next.
                Row(
                  children: [
                    for (int i = 0; i < pinLength; i++) ...[
                      if (i > 0) const SizedBox(width: Space.sm + 2),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < 2 ? p.primary : Colors.transparent,
                          border: i < 2
                              ? null
                              : Border.all(
                                  color: i == 2 ? p.primary : p.borderStrong,
                                  width: 1.5,
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Icon(
                      LucideIcons.fingerprintPattern,
                      size: 20,
                      color: p.muted,
                    ),
                    const SizedBox(width: Space.sm),
                    Flexible(
                      child: Text(
                        'or fingerprint / face',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratorDemo extends StatefulWidget {
  const _GeneratorDemo();

  @override
  State<_GeneratorDemo> createState() => _GeneratorDemoState();
}

class _GeneratorDemoState extends State<_GeneratorDemo> {
  String _value = generatePassword(length: 18);

  @override
  Widget build(BuildContext context) {
    return _DemoPanel(
      caption: 'Every tap makes a new one.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SecretText(value: _value, revealed: true, size: 18),
          const SizedBox(height: Space.md),
          StrengthMeter(password: _value),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _value = generatePassword(length: 18)),
            icon: const Icon(LucideIcons.wandSparkles, size: 18),
            label: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}

/// "By continuing you agree to the Terms and the Privacy policy", with both
/// opening in an in-app browser.
class _LegalLine extends StatelessWidget {
  const _LegalLine();

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    final ButtonStyle link = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      minimumSize: const Size(0, 36),
      textStyle: t.labelMedium,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By continuing you agree to the', style: t.bodySmall),
        TextButton(
          style: link,
          onPressed: () => _open(LegalLink.terms),
          child: const Text('Terms'),
        ),
        Text('and', style: t.bodySmall),
        TextButton(
          style: link,
          onPressed: () => _open(LegalLink.privacyPolicy),
          child: const Text('Privacy policy'),
        ),
      ],
    );
  }
}
