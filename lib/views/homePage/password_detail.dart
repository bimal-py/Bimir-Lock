import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/controller/homePage/password_detail_controller.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../../widgets/custom/custom_text_field.dart';

//this class require argument
class PasswordDetailPage extends StatefulWidget {
  static const String routeName = "/passwordDetailPage";
  const PasswordDetailPage({
    super.key,
  });

  @override
  State<PasswordDetailPage> createState() => _PasswordDetailPageState();
}

class _PasswordDetailPageState extends State<PasswordDetailPage> {
  late PasswordDetailController c;
  PasswordDetailPageArgument? _passwordDetailPageArgument;
  Rxn<PasswordTable> passwordTable = Rxn();

  @override
  void initState() {
    c = Get.put(PasswordDetailController());

    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    final widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      if (ModalRoute.of(context)?.settings.arguments != null) {
        _passwordDetailPageArgument = ModalRoute.of(context)!.settings.arguments
            as PasswordDetailPageArgument;
        if (_passwordDetailPageArgument != null) {
          c.isEdit.value = _passwordDetailPageArgument!.isEdit;
          passwordTable.value = _passwordDetailPageArgument!.passwordTable;
          c.titleController.text = passwordTable.value!.title ?? "";
          c.userNameController.text = passwordTable.value!.userName ?? "";
          // A locked row is one whose stored value could not be opened. Its
          // bytes are left exactly as they are: the field stays empty, editing
          // is forced off, and onSaveTap refuses. Putting the value straight
          // into the controller (and letting Save write it back) is how the
          // only copy of an unreadable password used to get replaced with "".
          c.locked.value = passwordTable.value!.locked;
          if (passwordTable.value!.locked) {
            c.isEdit.value = false;
            c.passwordController.text = "";
          } else {
            c.passwordController.text = passwordTable.value!.password ?? "";
          }
          c.id = passwordTable.value!.id;
        }
      }
    });
  }

  @override
  void dispose() {
    Get.delete<PasswordDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
            "Detail page",
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          // actions: [
          //   PopupMenuButton(
          //     splashRadius: 0,
          //     // shadowColor: AppColor.tertiaryTextColor,
          //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
          //     position: PopupMenuPosition.under,
          //     shape: const RoundedRectangleBorder(
          //       borderRadius: BorderRadius.all(
          //         Radius.circular(4.0),
          //       ),
          //     ),
          //     constraints: const BoxConstraints(minWidth: 119, minHeight: 123),
          //     onSelected: (value) async {
          //       if (value == "Edit") {
          //         c.onEditTap();
          //       } else if (value == "Delete") {
          //         bool? result = await showDialog(
          //           context: context,
          //           builder: (context) {
          //             return AlertDialog(
          //               title: const Text("Consent required!!!"),
          //               content: const Text(
          //                 "Do you really want to delete this password detial. Once deleted you cannot recover it back.",
          //               ),
          //               actions: [
          //                 TextButton(
          //                   onPressed: () {
          //                     Navigator.of(context).pop(true);
          //                   },
          //                   child: const Text(
          //                     "Ok",
          //                   ),
          //                 ),
          //                 TextButton(
          //                   onPressed: () {
          //                     Navigator.of(context).pop(false);
          //                   },
          //                   child: const Text(
          //                     "Cancel",
          //                   ),
          //                 ),
          //               ],
          //             );
          //           },
          //         );
          //         if (result != null && result) {
          //           var success = await c.onDeleteTap(passwordTable!);
          //           if (success) {
          //             HomePageController hpc = Get.find();
          //             await hpc.loadPasswords();
          //             Fluttertoast.showToast(
          //                 msg: "Password deleted successfully");
          //             if (context.mounted) {
          //               Navigator.of(context).pop();
          //             }
          //           } else {
          //             Fluttertoast.showToast(
          //                 msg: "Error encountered while deleting password");
          //           }
          //         }
          //       }
          //     },
          //     offset: const Offset(-20, 0),
          //     itemBuilder: (BuildContext context) => [
          //       PopupMenuItem(
          //         value: "Edit",
          //         child: Row(
          //           children: [
          //             Icon(
          //               Icons.edit,
          //               color: theme.colorScheme.onSurfaceVariant,
          //             ),
          //             const SizedBox(
          //               width: 5,
          //             ),
          //             Text(
          //               "Edit",
          //               style: TextStyle(
          //                 fontSize: 16,
          //                 fontWeight: FontWeight.w400,
          //                 color: theme.colorScheme.onSurfaceVariant,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       PopupMenuItem(
          //         value: "Delete",
          //         child: Row(
          //           children: [
          //             Icon(
          //               Icons.delete,
          //               color: theme.colorScheme.error,
          //             ),
          //             const SizedBox(
          //               width: 5,
          //             ),
          //             Text(
          //               "Delete",
          //               style: TextStyle(
          //                 fontSize: 16,
          //                 fontWeight: FontWeight.w400,
          //                 color: theme.colorScheme.error,
          //               ),
          //             )
          //           ],
          //         ),
          //       ),
          //     ],
          //     child: const Padding(
          //       padding: EdgeInsets.only(right: 24),
          //       child: Icon(
          //         Icons.more_vert_rounded,
          //       ),
          //     ),
          //   )
          // ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: c.formKey,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(
                                () => Text(
                                  "${passwordTable.value?.title.toString().capitalizeFirst}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              Obx(
                                () => BimirLockTextField(
                                  label: "Media Title",
                                  controller: c.titleController,
                                  readOnly: !c.isEdit.value,
                                  validator: Validators.checkFieldEmpty,
                                  // readOnly: false,
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              Obx(
                                () => BimirLockTextField(
                                  label: "User Name/ Email",
                                  controller: c.userNameController,
                                  readOnly: !c.isEdit.value,
                                  hasCopy: true,
                                  validator: Validators.checkFieldEmpty,
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              Obx(
                                () => BimirLockTextField(
                                  label: "Password",
                                  controller: c.passwordController,
                                  readOnly: !c.isEdit.value || c.locked.value,
                                  hasCopy: true,
                                  canCopy: !c.locked.value,
                                  validator: c.locked.value
                                      ? null
                                      : Validators.checkPasswordField,
                                ),
                              ),
                              Obx(
                                () => c.locked.value
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Text(
                                          "This entry can't be unlocked on this "
                                          "device. It has not been changed or "
                                          "deleted. You'll need to reset this "
                                          "password with the provider.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 80,
                      ),
                      Obx(
                        () => c.isEdit.value && !c.readOnly
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    FloatingActionButton.extended(
                                      heroTag: "editpassword",
                                      onPressed: () async {
                                        if (c.formKey.currentState!.validate()) {
                                          bool? result = await showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    "Consent required!!!"),
                                                content: const Text(
                                                  "Do you want to edit this password detial.",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(true);
                                                    },
                                                    child: const Text(
                                                      "Ok",
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(false);
                                                    },
                                                    child: const Text(
                                                      "Cancel",
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (result != null && result) {
                                            var success = await c.onSaveTap();
                                            if (success) {
                                              HomePageController hpc = Get.find();
                                              await hpc.loadPasswords();
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "Password updated successfully",
                                                  backgroundColor: Colors.black, textColor: Colors.white);
                                              if (context.mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "Error encountered while deleting password",
                                                  backgroundColor: Colors.black, textColor: Colors.white);
                                            }
                                          }
                                        }
                                      },
                                      label: const Text(
                                        "Update detail",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // FloatingActionButton.extended(
                                    //   heroTag: "editpasswordCancel",
                                    //   onPressed: () {
                                    //     c.onCancelTap();
                                    //   },
                                    //   label: const Text(
                                    //     "Cancel",
                                    //     style: TextStyle(
                                    //       fontSize: 18,
                                    //       fontWeight: FontWeight.w500,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // floatingActionButton: FloatingActionButton.extended(onPressed: () {}, label: Text("Save")),
        // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class PasswordDetailPageArgument {
  PasswordDetailPageArgument({
    required this.passwordTable,
    required this.isEdit,
  });
  final PasswordTable passwordTable;
  final bool isEdit;
}
