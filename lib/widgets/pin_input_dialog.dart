import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/utils/helper/biometric_helper.dart';
import 'package:bimir_lock/utils/validators.dart';
import 'package:bimir_lock/widgets/access_pin.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class PinInputMenuDialog extends StatefulWidget {
  final Function(String password) onConfirm;

  const PinInputMenuDialog({
    super.key,
    required this.onConfirm,
    this.message,
    this.allowBiometric = true,
  });
  final String? message;
  // False when the dialog is itself confirming the PIN to turn biometrics on.
  final bool allowBiometric;

  @override
  State<PinInputMenuDialog> createState() => _PinInputMenuDialogState();
}

class _PinInputMenuDialogState extends State<PinInputMenuDialog> {
  final TextEditingController textController = TextEditingController();
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  final BiometricController bc = Get.find<BiometricController>();
  bool _scanning = false;

  bool get _offerBiometric =>
      widget.allowBiometric &&
      bc.canUse &&
      Get.find<CoreController>().encryptedPassword != null;

  @override
  void initState() {
    super.initState();
    // Prompt once, straight away. Cancelling leaves the PIN field to type into.
    if (_offerBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning || !mounted) return;
    setState(() => _scanning = true);
    final BiometricOutcome outcome = await bc.helper.authenticate(
      "Unlock your password with ${bc.label.value}",
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    switch (outcome) {
      case BiometricOutcome.success:
        // A good scan stands in for typing the PIN, so hand the callers the
        // stored PIN and every existing "PIN is valid" branch runs unchanged.
        final String? pin = Get.find<CoreController>().encryptedPassword;
        if (pin != null) widget.onConfirm(pin);
        break;
      case BiometricOutcome.lockedOut:
        _toast("Too many attempts. Enter your PIN instead.");
        break;
      case BiometricOutcome.notAvailable:
        await bc.refreshStatus();
        if (mounted) setState(() {});
        _toast("${bc.label.value} isn't available right now. Enter your PIN.");
        break;
      case BiometricOutcome.canceled:
      case BiometricOutcome.failed:
        break;
    }
  }

  void _toast(String msg) => Fluttertoast.showToast(
    msg: msg,
    backgroundColor: Colors.black,
    textColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final String? message = widget.message;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      // Scrolls when the keyboard squeezes the dialog on small screens.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(50),
                color: theme.colorScheme.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 50,
                    color: const Color(0xFF000000).withValues(alpha: 0.4),
                    spreadRadius: 80,
                    offset: const Offset(0, 40),
                  ),
                  BoxShadow(
                    blurRadius: 50,
                    color: const Color(0xFF000000).withValues(alpha: 0.4),
                    spreadRadius: 80,
                    offset: const Offset(0, 40),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Icon(Icons.close, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      textAlign: TextAlign.center,
                      message ??
                          "The password you are trying to access is protected with a pin. Please enter the pin to proceed.",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: globalKey,
                      child: Column(
                        children: [
                          AccessPinWidget(
                            pinController: textController,
                            validator: Validators.checkPinField,
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (globalKey.currentState!.validate()) {
                          widget.onConfirm(textController.text);
                        }
                      },
                      child: const Text("Check Pin"),
                    ),
                    if (_offerBiometric) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _scanning ? null : _scan,
                        icon: const Icon(Icons.fingerprint, size: 28),
                        label: Text("Use ${bc.label.value}"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
