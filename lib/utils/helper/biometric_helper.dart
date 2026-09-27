import 'dart:developer';

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

  // "Face ID" on a Face ID iPhone, "fingerprint" everywhere else.
  Future<String> label() async {
    try {
      final List<BiometricType> types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face) &&
          !types.contains(BiometricType.fingerprint)) {
        return "Face ID";
      }
    } catch (_) {}
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
