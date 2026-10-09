import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/quote_book.dart';
import 'package:bimir_lock/views/introScreen/introduction_page.dart';
import 'package:bimir_lock/views/introScreen/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The brand mark while the app loads. It eases in over the plain launch
/// screen, stays as long as loading takes (plus a beat, so it never flashes),
/// then hands over to the quote or to first-run setup. The mark is a Hero, and
/// the quote screen keeps it centred too, so it glides straight up into place.
class SplashPage extends StatefulWidget {
  static const String routeName = "/splashPage";
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final CoreController c = Get.put(CoreController());
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    _go();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in.isDismissed) {
      Motion.reduced(context) ? _in.value = 1 : _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    Quote? quote;
    await Future.wait(<Future<void>>[
      c.ready,
      Future<void>.delayed(const Duration(milliseconds: 900)),
      // Picked now, so the quote screen has it on its first frame.
      () async {
        try {
          quote = await QuoteBook.random();
        } catch (_) {
          // The quote screen picks one itself then.
        }
      }(),
    ]);
    if (!mounted) return;
    final bool known = c.isUserLoggedIn();
    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      known ? WelcomePage.routeName : IntroductionPage.routeName,
      (route) => false,
      arguments: known ? quote : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> logo = CurvedAnimation(
      parent: _in,
      curve: Curves.easeOutCubic,
    );
    final Animation<double> name = CurvedAnimation(
      parent: _in,
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
    );
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: logo,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(logo),
                child: const BrandHero(size: 128),
              ),
            ),
            const SizedBox(height: Space.lg),
            FadeTransition(
              opacity: name,
              child: Text(
                'Bimir Lock',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String brandHeroTag = 'brand-mark';

/// The logo as the Hero that flies between the launch screens and the vault.
/// The path is a straight line rather than Material's arc: the mark moves
/// up, or up and across, without swinging out on the way.
class BrandHero extends StatelessWidget {
  const BrandHero({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: brandHeroTag,
      createRectTween: (Rect? begin, Rect? end) =>
          RectTween(begin: begin, end: end),
      child: LogoMark(size: size),
    );
  }
}
