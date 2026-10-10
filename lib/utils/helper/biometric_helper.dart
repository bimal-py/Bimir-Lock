import 'dart:developer';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricOutcome {
  success,
  // The user backed out. Not an error: the PIN field is still there.
  canceled,
  // No hardware, nothing enrolled, or the device has no lock screen.
  notAvailable,
  // Too many failed attempts. The OS unlocks it again later.
  lockedOut,
  failed,
}

/// What this phone can do about fingerprint / face unlock right now. The app
/// PIN works in every one of these; biometrics only ever stand in for typing it.
enum BiometricState {
  /// A fingerprint or face is set up and the app may use it.
  ready,

  /// The phone can do it, but nothing is enrolled yet (phone settings).
  notEnrolled,

  /// On iPhone / iPad: Face ID or Touch ID is not available to this app —
  /// switched off for Bimir Lock in Settings, or not set up on the device.
  blocked,

  /// No fingerprint reader or face unlock at all. PIN only.
  noHardware,
}

// Every local_auth call goes through here so no exception can reach a widget.
// Biometrics only ever stand in for typing the access PIN; they never replace it.
class BiometricHelper {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      log("biometric availability check failed: ${e.runtimeType}");
      return false;
    }
  }

  /// Why biometric unlock can or cannot be switched on, so Settings can say
  /// what to do about it instead of only "not available".
  Future<BiometricState> state() async {
    try {
      // True when the hardware exists, enrolled or not.
      if (!await _auth.canCheckBiometrics) {
        // Every iPhone and iPad this app runs on has Face ID or Touch ID, so
        // "cannot check" there means it is off for this app or not set up.
        return Platform.isIOS
            ? BiometricState.blocked
            : BiometricState.noHardware;
      }
      return (await _auth.getAvailableBiometrics()).isEmpty
          ? BiometricState.notEnrolled
          : BiometricState.ready;
    } catch (e) {
      log("biometric state check failed: ${e.runtimeType}");
      return BiometricState.noHardware;
    }
  }

  // "Face ID" on a Face ID iPhone, "fingerprint" everywhere else.
  // On iPhone: "Face ID", or "Touch ID" on a Touch ID model. Face ID is also
  // the answer when nothing is enrolled yet, since that is what current
  // iPhones have. Elsewhere: "fingerprint" (or "face unlock").
  Future<String> label() async {
    List<BiometricType> types = const <BiometricType>[];
    try {
      types = await _auth.getAvailableBiometrics();
    } catch (_) {}
    final bool face = types.contains(BiometricType.face);
    final bool finger = types.contains(BiometricType.fingerprint);
    if (Platform.isIOS) return finger && !face ? "Touch ID" : "Face ID";
    if (face && !finger) return "face unlock";
    return "fingerprint";
  }

  Future<BiometricOutcome> authenticate(String reason) async {
    try {
      final bool ok = await _auth.authenticate(
        localizedReason: reason,
        // The app PIN is the fallback, not the device passcode. Allowing the
        // passcode would let anyone who knows the phone's passcode skip the
        // app's own PIN.
        biometricOnly: true,
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.canceled;
    } on LocalAuthException catch (e) {
      log("biometric auth: ${e.code}");
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
        case LocalAuthExceptionCode.authInProgress:
        case LocalAuthExceptionCode.userRequestedFallback:
          return BiometricOutcome.canceled;
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        case LocalAuthExceptionCode.uiUnavailable:
          return BiometricOutcome.notAvailable;
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return BiometricOutcome.lockedOut;
        default:
          return BiometricOutcome.failed;
      }
    } on PlatformException catch (e) {
      log("biometric auth platform error: ${e.code}");
      return BiometricOutcome.failed;
    } on MissingPluginException {
      return BiometricOutcome.notAvailable;
    } catch (e) {
      log("biometric auth failed: ${e.runtimeType}");
      return BiometricOutcome.failed;
    }
  }
}
