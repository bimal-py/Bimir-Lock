import 'package:bimir_lock/utils/helper/autofill_helper.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

// The enabled state belongs to the OS, not to us. The user can turn us on or off
// in system settings while the app is in the background, so it is never cached:
// it is re-read on init and every time the app comes back to the foreground.
class AutofillController extends GetxController with WidgetsBindingObserver {
  final AutofillHelper autofillHelper = AutofillHelper();

  RxBool isSupported = false.obs;
  RxBool isEnabled = false.obs;
  RxBool isBusy = false.obs;

  bool _observerAdded = false;

  @override
  void onInit() {
    super.onInit();
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    refreshStatus();
  }

  @override
  void onClose() {
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      refreshStatus();
    }
  }

  Future<void> refreshStatus() async {
    final bool supported = await autofillHelper.isSupported();
    isSupported.value = supported;
    isEnabled.value = supported ? await autofillHelper.isEnabled() : false;
  }

  // Turning autofill on can only be done by the user in system settings, so we
  // just open it and let the resume callback read back what really happened.
  // Nothing here is optimistic: back out of the picker and the switch stays off.
  Future<void> toggleAutofill(bool value) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      if (value) {
        final bool opened = await autofillHelper.openSettings();
        if (!opened) {
          Fluttertoast.showToast(
              msg: "Autofill settings are not available on this device.",
              backgroundColor: Colors.black,
              textColor: Colors.white);
        }
      } else {
        await autofillHelper.disableService();
        await refreshStatus();
      }
    } finally {
      isBusy.value = false;
    }
  }
}
