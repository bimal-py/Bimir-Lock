import 'dart:async';

import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/ui/forgot_pin.dart';
import 'package:bimir_lock/ui/lock_glyph.dart';
import 'package:bimir_lock/ui/pin_pad.dart';
import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/utils/helper/biometric_helper.dart';
import 'package:bimir_lock/utils/helper/entry_lock.dart';
import 'package:bimir_lock/utils/helper/intruder_watch.dart';
import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Asks for the access PIN (or fingerprint / Face ID when turned on) before
/// something protected happens. Resolves true only after a correct PIN or a
/// successful scan. This is the ONE place the app checks the PIN.
///
/// [allowBiometric] is false when the PIN itself is what is being confirmed,
/// e.g. to switch biometric unlock on.
///
/// With [entryId], an entry that has a PIN of its own asks for THAT PIN
/// instead, and never accepts a fingerprint or face: a second secret is the
/// whole point of giving an entry its own PIN.
Future<bool> confirmIdentity(
  BuildContext context, {
  required String title,
  String? message,
  bool allowBiometric = true,
  int? entryId,
}) async {
  final bool ownPin = await EntryLock.hasOwnPin(entryId);
  if (!context.mounted) return false;
  final CoreController cc = Get.find<CoreController>();
  if (!ownPin && cc.encryptedPassword == null) {
    await _askToSetPin(context);
    return false;
  }
  final bool? ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _UnlockSheet(
      title: title,
      message: ownPin ? 'This password has its own PIN.' : message,
      allowBiometric: allowBiometric && !ownPin,
      entryId: ownPin ? entryId : null,
    ),
  );
  return ok ?? false;
}

Future<void> _askToSetPin(BuildContext context) async {
  final bool go = await DialogUtils.showConfirmationDialog(
    context,
    title: 'Set an access PIN first',
    message:
        'Your passwords open with a PIN that only you know. It takes a few seconds to set one up.',
    confirmText: 'Set PIN',
    cancelText: 'Not now',
    icon: Icons.lock_outline_rounded,
  );
  if (go) navigatorKey.currentState!.pushNamed(SetAccessPinPage.routeName);
}

class _UnlockSheet extends StatefulWidget {
  const _UnlockSheet({
    required this.title,
    required this.allowBiometric,
    this.message,
    this.entryId,
  });

  final String title;
  final String? message;
  final bool allowBiometric;

  /// Set when the entry's own PIN is being asked for.
  final int? entryId;

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  final CoreController cc = Get.find<CoreController>();
  final BiometricController bc = Get.find<BiometricController>();
  final GlobalKey<PinPadState> _pad = GlobalKey<PinPadState>();

  bool _open = false;
  bool _scanning = false;
  String? _status;
  bool _statusIsError = false;
  Duration _lockedFor = Duration.zero;
  Timer? _ticker;

  bool get _offerBiometric => widget.allowBiometric && bc.canUse;

  @override
  void initState() {
    super.initState();
    _checkLock();
    // Prompt once, straight away. Cancelling leaves the keypad to type into.
    if (_offerBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _checkLock() async {
    final Duration left = await PinGuard.remaining();
    if (!mounted) return;
    _setLock(left);
  }

  void _setLock(Duration left) {
    _ticker?.cancel();
    setState(() => _lockedFor = left);
    if (left <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return t.cancel();
      final Duration next = _lockedFor - const Duration(seconds: 1);
      setState(() {
        _lockedFor = next.isNegative ? Duration.zero : next;
        if (_lockedFor == Duration.zero) {
          _status = null;
          t.cancel();
        }
      });
    });
  }

  Future<void> _succeed() async {
    await PinGuard.recordSuccess();
    if (!mounted) return;
    setState(() {
      _open = true;
      _status = null;
    });
    // Long enough to see the shackle lift; it is the confirmation.
    await Future<void>.delayed(
      Motion.reduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 360),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<bool> _check(String pin) async {
    if (_lockedFor > Duration.zero) return false;
    final int? entry = widget.entryId;
    final bool right =
        isDebugMasterPin(pin) ||
        (entry != null
            ? await EntryLock.matches(entry, pin)
            : cc.encryptedPassword == pin);
    if (right) {
      unawaited(_succeed());
      return true;
    }
    final Duration lock = await IntruderWatch.recordWrongPin();
    final int failures = await PinGuard.failures();
    if (!mounted) return false;
    setState(() {
      _statusIsError = true;
      final int left = PinGuard.attempts - failures;
      _status = lock > Duration.zero
          ? null
          : left <= 2
          ? 'Wrong PIN. $left ${left == 1 ? 'try' : 'tries'} left before a 30-second lock.'
          : 'Wrong PIN. Try again.';
    });
    if (lock > Duration.zero) _setLock(lock);
    return false;
  }

  Future<void> _scan() async {
    if (_scanning || !mounted) return;
    setState(() => _scanning = true);
    final BiometricOutcome outcome = await bc.helper.authenticate(
      widget.message ?? widget.title,
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    switch (outcome) {
      case BiometricOutcome.success:
        HapticFeedback.mediumImpact();
        await _succeed();
      case BiometricOutcome.lockedOut:
        setState(() {
          _statusIsError = true;
          _status = 'Too many ${bc.label.value} attempts. Use your PIN.';
        });
      case BiometricOutcome.notAvailable:
        await bc.refreshStatus();
        if (!mounted) return;
        setState(() {
          _statusIsError = false;
          _status =
              "${_capital(bc.label.value)} isn't available right now. Use your PIN.";
        });
      case BiometricOutcome.canceled:
      case BiometricOutcome.failed:
        break;
    }
  }

  String _capital(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
    final bool locked = _lockedFor > Duration.zero;

    final String? line = locked
        ? _offerBiometric
              ? 'Too many wrong PINs. Try again in ${_clock(_lockedFor)}, or use ${bc.label.value}.'
              : 'Too many wrong PINs. Try again in ${_clock(_lockedFor)}.'
        : _status;
    final Color lineColour = locked || _statusIsError ? p.danger : p.muted;

    final Widget header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
          child: LockGlyph(open: _open, size: 30, color: p.onPrimarySoft),
        ),
        const SizedBox(height: Space.md),
        Text(widget.title, style: t.titleLarge, textAlign: TextAlign.center),
        if (widget.message != null) ...[
          const SizedBox(height: Space.xs),
          Text(
            widget.message!,
            style: t.bodyMedium?.copyWith(color: p.muted),
            textAlign: TextAlign.center,
          ),
        ],
        AnimatedSize(
          duration: Motion.fast,
          alignment: Alignment.topCenter,
          child: line == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(
                    line,
                    style: t.bodySmall?.copyWith(color: lineColour),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: PinPad(
            key: _pad,
            // A PIN chosen before PINs went to 6 digits keeps its own length.
            length: widget.entryId != null
                ? pinLength
                : cc.encryptedPassword?.length ?? pinLength,
            enabled: !locked && !_open,
            header: header,
            onCompleted: _check,
            leadingKey: _offerBiometric
                ? PinPadKey(
                    icon: bc.label.value.contains('Face') || bc.label.value.contains('face')
                        ? LucideIcons.scanFace
                        : LucideIcons.fingerprintPattern,
                    label: 'Use ${bc.label.value}',
                    onTap: _scan,
                    // Still works while wrong PINs have the digits locked:
                    // the phone keeps its own limit on failed scans.
                    enabled: !_open,
                  )
                : null,
            // The app PIN only; an entry's own PIN has no reset.
            footer: widget.entryId != null || _open
                ? null
                : TextButton(
                    onPressed: () {
                      final NavigatorState nav = Navigator.of(context);
                      nav.pop(false);
                      forgotPin(nav.context);
                    },
                    child: const Text('Forgot PIN?'),
                  ),
          ),
        ),
      ),
    );
  }
}
