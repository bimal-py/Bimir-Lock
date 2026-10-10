import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';

// Thin wrapper over the native autofill channel. Android only, and every call
// answers with a safe default instead of throwing, so a missing channel or a
// platform side error can never take the app down.
class AutofillHelper {
  static const MethodChannel _channel =
      MethodChannel("com.cklamib.bimirLock/autofill");

  Future<bool> _invokeBool(String method) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } on MissingPluginException catch (e) {
      log("=================>>>>>> autofill channel missing for $method: $e");
      return false;
    } on PlatformException catch (e) {
      log("=================>>>>>> autofill $method failed: $e");
      return false;
    } catch (e) {
      log("=================>>>>>> autofill $method error: $e");
      return false;
    }
  }

  // Does this device have the autofill framework at all.
  Future<bool> isSupported() => _invokeBool("isAutofillSupported");

  // Is Bimir Lock the autofill service the user picked.
  Future<bool> isEnabled() => _invokeBool("isAutofillEnabled");

  // Opens the system picker. False means there is no such screen on this device.
  Future<bool> openSettings() => _invokeBool("openAutofillSettings");

  Future<bool> disableService() => _invokeBool("disableAutofillService");

  // The phone's security settings, where a fingerprint or face is enrolled.
  // Rides this channel because it is the app's one Android channel. False on
  // iOS, or when the phone has no such screen.
  Future<bool> openSecuritySettings() => _invokeBool("openSecuritySettings");
}
