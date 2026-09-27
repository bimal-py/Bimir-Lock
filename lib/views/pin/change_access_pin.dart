import 'package:bimir_lock/controller/pin/change_access_pin_controller.dart';
import 'package:bimir_lock/utils/validators.dart';
import 'package:bimir_lock/widgets/access_pin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeAccessPinPage extends StatefulWidget {
  static const String routeName = "/change-access-pin";

  const ChangeAccessPinPage({super.key});

  @override
  State<ChangeAccessPinPage> createState() => _ChangeAccessPinPageState();
}

class _ChangeAccessPinPageState extends State<ChangeAccessPinPage> {
  late ChangeAccessPinPageController c;

  @override
  void initState() {
    c = Get.put(ChangeAccessPinPageController());
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<ChangeAccessPinPageController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              highlightColor: Colors.transparent,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 30,
              ),
            ),
          ),
          automaticallyImplyLeading: false,
          title: const Text(
            "Change Access Pin",
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35.0),
                      ),
                      elevation: 10,
                      semanticContainer: false,
                      surfaceTintColor: theme.colorScheme.surfaceTint,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: c.formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Enter your access pin:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              AccessPinWidget(
                                pinController: c.accessPinController,
                                validator: Validators.checkPinField,
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              const Text(
                                "Enter new access pin:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              AccessPinWidget(
                                pinController: c.newAccessPinController,
                                validator: Validators.checkPinField,
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              const Text(
                                "Re-enter new access pin:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              AccessPinWidget(
                                  pinController: c.reNewAccessPinController,
                                  onCompleted: (p0) {},
                                  validator: (value) =>
                                      Validators.checkConfirmPin(
                                          c.newAccessPinController.text, value)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                    ),
                    FloatingActionButton.extended(
                        heroTag: "saveButton",
                        onPressed: () {
                          c.onChangeAccessPinTap();
                        },
                        label: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
