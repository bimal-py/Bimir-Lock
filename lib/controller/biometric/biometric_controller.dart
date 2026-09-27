import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/utils/helper/biometric_helper.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

// "Enabled" is the user's choice; "available" is what the device can do right
// now. The user can remove every fingerprint in system settings while we are in
// the background, so availability is re-read on resume and only the two together
// make the PIN dialog offer biometrics.
class BiometricController extends GetxController with WidgetsBindingObserver {
  final BiometricHelper helper = BiometricHelper();
  final StorageHelper storageHelper = StorageHelper();

  RxBool isAvailable = false.obs;
  RxBool isEnabled = false.obs;
  RxString label = "fingerprint".obs;
  bool _busy = false;

  bool get canUse => isAvailable.value && isEnabled.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshStatus();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) refreshStatus();
  }

  Future<void> refreshStatus() async {
    isAvailable.value = await helper.isAvailable();
    isEnabled.value = await storageHelper.readBiometricUnlock();
    label.value = await helper.label();
  }

  // Turning it ON needs the access PIN first, then a successful scan. Without
  // the PIN step, anyone holding the unlocked phone with their own finger
  // enrolled could switch it on and walk straight past the app PIN.
  Future<void> toggle(
    bool value, {
    required Future<bool> Function() confirmPin,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      if (!value) {
        await storageHelper.saveBiometricUnlock(false);
        isEnabled.value = false;
        return;
      }
      final CoreController cc = Get.find<CoreController>();
      if (cc.encryptedPassword == null) {
        _toast("Set an access PIN first.");
        return;
      }
      await refreshStatus();
      if (!isAvailable.value) {
        _toast("Set up ${label.value} in your phone's settings first.");
        return;
      }
      if (!await confirmPin()) return;
      final BiometricOutcome outcome = await helper.authenticate(
        "Confirm it's you to turn on ${label.value} unlock",
      );
      if (outcome == BiometricOutcome.success) {
        await storageHelper.saveBiometricUnlock(true);
        isEnabled.value = true;
        _toast("${_capital(label.value)} unlock is on.");
      } else if (outcome == BiometricOutcome.lockedOut) {
        _toast("Too many attempts. Try again later.");
      }
    } finally {
      _busy = false;
    }
  }

  void _toast(String msg) => Fluttertoast.showToast(
    msg: msg,
    backgroundColor: Colors.black,
    textColor: Colors.white,
  );

  String _capital(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
