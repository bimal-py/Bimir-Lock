import 'package:bimir_lock/controller/pin/set_access_pin_controller.dart';
import 'package:bimir_lock/utils/validators.dart';
import 'package:bimir_lock/widgets/access_pin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SetAccessPinPage extends StatefulWidget {
  static const String routeName = "/set-access-pin";

  const SetAccessPinPage({super.key});

  @override
  State<SetAccessPinPage> createState() => _SetAccessPinPageState();
}

class _SetAccessPinPageState extends State<SetAccessPinPage> {
  late SetAccessPinPageController c;

  @override
  void initState() {
    c = Get.put(SetAccessPinPageController());
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<SetAccessPinPageController>();
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
            "Set Access Pin",
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
                                height: 40,
                              ),
                              const Text(
                                "Re-Enter your access pin:",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              AccessPinWidget(
                                  pinController: c.reAccessPinController,
                                  onCompleted: (p0) {},
                                  validator: (value) =>
                                      Validators.checkConfirmPin(
                                          c.accessPinController.text, value)),
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
