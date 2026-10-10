import 'dart:io';

import 'package:bimir_lock/utils/helper/autofill_helper.dart';
import 'package:flutter/material.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:get/get.dart';

// The enabled state belongs to the OS, not to us. The user can turn us on or off
// in system settings while the app is in the background, so it is never cached:
// it is re-read on init and every time the app comes back to the foreground.
class AutofillController extends GetxController with WidgetsBindingObserver {
  AutofillController({AutofillHelper? helper})
    : autofillHelper = helper ?? AutofillHelper();

  final AutofillHelper autofillHelper;

  RxBool isSupported = false.obs;
  RxBool isEnabled = false.obs;

  /// iPhone / iPad: whether Bimir Lock is switched on as an AutoFill provider
  /// in the phone's settings. Read-only here; iOS owns the switch.
  RxBool iosEnabled = false.obs;
  RxBool isBusy = false.obs;

  bool _observerAdded = false;

  /// This phone can fill passwords from Bimir Lock at all: every iPhone and
  /// iPad, and Android where the autofill framework exists.
  bool get available => Platform.isIOS || isSupported.value;

  /// AutoFill is switched on for Bimir Lock in the phone's settings.
  bool get on => Platform.isIOS ? iosEnabled.value : isEnabled.value;

  /// The shortest way this phone has to switching it on: Apple's own prompt
  /// or its settings page on iPhone, the system's service picker on Android.
  /// The state is read back afterwards (and again when the app resumes).
  Future<void> turnOn() async {
    Platform.isIOS ? await IosAutofill.turnOn() : await toggleAutofill(true);
    await refreshStatus();
  }

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
    iosEnabled.value = await IosAutofill.isEnabled();
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
          showNote("Autofill settings are not available on this device.");
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
