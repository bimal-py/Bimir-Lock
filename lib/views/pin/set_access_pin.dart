import 'dart:async';

import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/ui/lock_glyph.dart';
import 'package:bimir_lock/ui/pin_pad.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:bimir_lock/views/introScreen/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PinSetupArgs {
  const PinSetupArgs({this.onboarding = false});

  /// Part of first-run setup: no back button, a "Skip for now", and the
  /// launch screen afterwards instead of popping.
  final bool onboarding;
}

class SetAccessPinPage extends StatelessWidget {
  static const String routeName = "/set-access-pin";

  const SetAccessPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    return PinSetupView(
      changing: false,
      onboarding: args is PinSetupArgs && args.onboarding,
    );
  }
}

enum _Step { current, choose, repeat }

/// Setting or changing the access PIN on the app's own keypad, one step at a
/// time: (current PIN) → new PIN → the same again.
class PinSetupView extends StatefulWidget {
  const PinSetupView({
    super.key,
    required this.changing,
    this.onboarding = false,
    this.pickFor,
    this.resetting = false,
  });

  final bool changing;
  final bool onboarding;

  /// After "Forgot PIN?" proved it is the owner: a new PIN without the old.
  final bool resetting;

  /// Choosing a PIN for one entry (named here) rather than the app PIN: the
  /// screen pops with the chosen PIN instead of saving anything.
  final String? pickFor;

  @override
  State<PinSetupView> createState() => _PinSetupViewState();
}

class _PinSetupViewState extends State<PinSetupView> {
  final CoreController cc = Get.find<CoreController>();
  final StorageHelper storage = StorageHelper();
  final GlobalKey<PinPadState> _pad = GlobalKey<PinPadState>();

  late _Step _step = widget.changing ? _Step.current : _Step.choose;
  String? _chosen;
  String? _error;
  bool _done = false;
  Duration _lockedFor = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.changing) _checkLock();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _checkLock() async => _setLock(await PinGuard.remaining());

  void _setLock(Duration left) {
    if (!mounted) return;
    _ticker?.cancel();
    setState(() => _lockedFor = left);
    if (left <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return t.cancel();
      setState(() {
        final Duration next = _lockedFor - const Duration(seconds: 1);
        _lockedFor = next.isNegative ? Duration.zero : next;
        if (_lockedFor == Duration.zero) t.cancel();
      });
      if (_lockedFor == Duration.zero) unawaited(_showTriesLeft());
    });
  }

  /// Once a lock ends, how many tries are left before the next one.
  Future<void> _showTriesLeft() async {
    final String? line = PinGuard.triesLeftLine(await PinGuard.failures());
    if (!mounted || line == null || _step != _Step.current) return;
    setState(() => _error = '${line[0].toUpperCase()}${line.substring(1)}');
  }

  void _advance(_Step next) {
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _step = next;
        _error = null;
      });
      _pad.currentState?.clear();
    });
  }

  Future<bool> _onCompleted(String pin) async {
    switch (_step) {
      case _Step.current:
        if (_lockedFor > Duration.zero) return false;
        if (pin == cc.encryptedPassword || isDebugMasterPin(pin)) {
          await PinGuard.recordSuccess();
          _advance(_Step.choose);
          return true;
        }
        final Duration lock = await IntruderWatch.recordWrongPin();
        final String? left = PinGuard.triesLeftLine(await PinGuard.failures());
        if (!mounted) return false;
        setState(
          () => _error = left == null || lock > Duration.zero
              ? 'That is not your current PIN.'
              : 'That is not your current PIN. ${left[0].toUpperCase()}${left.substring(1)}',
        );
        if (lock > Duration.zero) _setLock(lock);
        return false;

      case _Step.choose:
        final String? weak = pinWeakness(pin);
        if (weak != null) {
          setState(() => _error = weak);
          return false;
        }
        if (widget.pickFor != null && pin == cc.encryptedPassword) {
          setState(
            () => _error =
                'That is your app PIN. A different one is what makes this entry extra safe.',
          );
          return false;
        }
        if (widget.changing && pin == cc.encryptedPassword) {
          setState(
            () => _error = 'That is your current PIN. Choose a different one.',
          );
          return false;
        }
        _chosen = pin;
        _advance(_Step.repeat);
        return true;

      case _Step.repeat:
        if (pin != _chosen) {
          setState(() {
            _error = "Those didn't match. Choose your new PIN again.";
            _step = _Step.choose;
            _chosen = null;
          });
          return false;
        }
        if (widget.pickFor != null) {
          setState(() => _done = true);
          unawaited(_finish(picked: pin));
          return true;
        }
        await storage.setEncryptedPassword(pin);
        await cc.loadEncryptedPassword();
        if (cc.encryptedPassword != pin) {
          // Never report success for a PIN that did not actually save.
          setState(() {
            _error = "Couldn't save the PIN. Please try again.";
            _step = _Step.choose;
          });
          return false;
        }
        await PinGuard.recordSuccess();
        setState(() => _done = true);
        unawaited(_finish());
        return true;
    }
  }

  Future<void> _finish({String? picked}) async {
    await Future<void>.delayed(
      Motion.reduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 420),
    );
    if (!mounted) return;
    if (picked != null) {
      Navigator.of(context).pop(picked);
    } else if (widget.onboarding) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil(
        WelcomePage.routeName,
        (route) => false,
      );
    } else {
      showNote(
        widget.resetting
            ? 'New PIN set'
            : widget.changing
            ? 'Access PIN changed'
            : 'Access PIN set',
      );
      Navigator.of(context).pop(true);
    }
  }

  void _skip() {
    navigatorKey.currentState!.pushNamedAndRemoveUntil(
      WelcomePage.routeName,
      (route) => false,
    );
  }

  String _clock(Duration d) {
    final int s = d.inSeconds + (d.inMilliseconds % 1000 > 0 ? 1 : 0);
    return s >= 60
        ? '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}'
        : '$s s';
  }

  @override
  Widget build(BuildContext context) {
    final BimirPalette p = BimirPalette.of(context);
    final TextTheme t = Theme.of(context).textTheme;

    final (String title, String body) = switch (_step) {
      _Step.current => ('Enter your current PIN', 'To make sure it is you.'),
      _Step.choose => (
        widget.changing || widget.resetting
            ? 'Choose a new $pinLength-digit PIN'
            : 'Choose a $pinLength-digit PIN',
        widget.pickFor != null
            ? 'Only this password will open with it. If you forget it, you can still delete the entry with your app PIN.'
            : 'You will use it to open your passwords. Avoid dates and patterns.',
      ),
      _Step.repeat => ('Enter it once more', 'So a typo cannot lock you out.'),
    };
    final bool locked = _lockedFor > Duration.zero;
    final String? line = locked
        ? 'Too many wrong PINs. Try again in ${_clock(_lockedFor)}.'
        : _error;

    final Widget header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onboarding) ...[
          Text(
            'STEP 2 OF 2',
            style: BimirPalette.figure(context, color: p.primary),
          ),
          const SizedBox(height: Space.md),
        ],
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
          child: LockGlyph(open: _done, size: 30, color: p.onPrimarySoft),
        ),
        const SizedBox(height: Space.md),
        AnimatedSwitcher(
          duration: Motion.reduced(context) ? Duration.zero : Motion.base,
          child: Column(
            key: ValueKey<_Step>(_step),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: Space.xs),
              Text(
                body,
                style: t.bodyMedium?.copyWith(color: p.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: AnimatedSize(
            duration: Motion.fast,
            child: line == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Text(
                      line,
                      style: t.bodySmall?.copyWith(color: p.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ],
    );

    return PopScope(
      canPop: !widget.onboarding,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.onboarding,
          title: Text(
            widget.onboarding
                ? ''
                : widget.pickFor != null
                ? 'PIN for ${widget.pickFor}'
                : widget.resetting
                ? 'Reset access PIN'
                : widget.changing
                ? 'Change access PIN'
                : 'Set access PIN',
          ),
          actions: [
            if (widget.onboarding)
              TextButton(onPressed: _skip, child: const Text('Skip for now')),
          ],
        ),
        body: PageBody(
          top: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) =>
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.lg),
                        child: PinPad(
                          key: _pad,
                          // The current PIN may be an older 4-digit one.
                          length: _step == _Step.current
                              ? cc.encryptedPassword?.length ?? pinLength
                              : pinLength,
                          header: header,
                          enabled: !locked && !_done,
                          onCompleted: _onCompleted,
                        ),
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

/// Opens the keypad to choose a PIN for one entry. Resolves to the PIN, or
/// null when backed out of.
Future<String?> pickEntryPin(BuildContext context, String entryTitle) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => PinSetupView(changing: false, pickFor: entryTitle),
    ),
  );
}
