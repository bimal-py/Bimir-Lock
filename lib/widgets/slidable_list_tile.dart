import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/views/homePage/password_detail.dart';
import 'package:bimir_lock/widgets/pin_input_dialog.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/utils/helper/biometric_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class SlidableListTile extends StatelessWidget {
  final HomePageController hc = Get.find<HomePageController>();
  SlidableListTile({super.key, required this.passwordTable});
  final CoreController cc = Get.find<CoreController>();

  final PasswordTable passwordTable;
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(
        top: 10,
        bottom: 20,
        right: 10,
        left: 10,
      ),
      child: Slidable(
        useTextDirection: true,
        key: UniqueKey(),

        //we want to pass context and value false when editing so as to disable dismissible while popping
        startActionPane: ActionPane(
          closeThreshold: 0.9,
          motion: const BehindMotion(),
          dismissible: DismissiblePane(
            closeOnCancel: true,
            confirmDismiss: () async {
              bool success = await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        "Do you want to Edit this password?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            bool? pinValid = await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (context) {
                                  return PinInputMenuDialog(
                                    message:
                                        "The password you are trying to edit is protected with a pin. Please enter the pin to proceed.",
                                    onConfirm: (pin) {
                                      if (cc.encryptedPassword == pin) {
                                        Navigator.pop(context, true);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "invalid pin",
                                            backgroundColor: Colors.black, textColor: Colors.white);
                                      }
                                    },
                                  );
                                });
                            if (pinValid ?? false) {
                              if (context.mounted) {
                                Navigator.pop(context, false);
                              }
                              navigatorKey.currentState!.pushNamed(
                                PasswordDetailPage.routeName,
                                arguments: PasswordDetailPageArgument(
                                  passwordTable: passwordTable,
                                  isEdit: true,
                                ),
                              );
                            } else {
                              if (context.mounted) {
                                Navigator.pop(context, false);
                              }
                            }
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  });
              return success;
            },
            onDismissed: () {},
          ),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.circular(15),
              onPressed: (val) {
                showDialog(
                    barrierDismissible: true,
                    context: val,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          "Do you want to Edit this password?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              bool? pinValid = await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (context) {
                                    return PinInputMenuDialog(
                                      message:
                                          "The password you are trying to edit is protected with a pin. Please enter the pin to proceed.",
                                      onConfirm: (pin) {
                                        if (cc.encryptedPassword == pin) {
                                          Navigator.pop(context, true);
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: "invalid pin",
                                              backgroundColor: Colors.black, textColor: Colors.white);
                                          // Navigator.pop(context, false);
                                        }
                                      },
                                    );
                                  });
                              if (pinValid ?? false) {
                                if (context.mounted) {
                                  Navigator.pop(context, false);
                                }
                                navigatorKey.currentState!.pushNamed(
                                  PasswordDetailPage.routeName,
                                  arguments: PasswordDetailPageArgument(
                                    passwordTable: passwordTable,
                                    isEdit: true,
                                  ),
                                );
                              } else {
                                if (context.mounted) {
                                  Navigator.pop(context, false);
                                }
                              }
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      );
                    });
              },
              backgroundColor: theme.colorScheme.onSurfaceVariant,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
          ],
        ),

        //we want to pass context and value true when deleting so as to enable dismissible while popping
        endActionPane: ActionPane(
          closeThreshold: 0.9,
          motion: const BehindMotion(),
          dismissible: DismissiblePane(
            closeOnCancel: true,
            confirmDismiss: () async {
              bool success = await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        "Do you want to delete?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            bool? pinValid = await showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (context) {
                                  return PinInputMenuDialog(
                                    message:
                                        "The password you are trying to delete is protected with a pin. Please enter the pin to proceed.",
                                    onConfirm: (pin) {
                                      if (cc.encryptedPassword == pin) {
                                        Navigator.pop(context, true);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "invalid pin",
                                            backgroundColor: Colors.black, textColor: Colors.white);
                                      }
                                    },
                                  );
                                });
                            if (context.mounted) {
                              Navigator.pop(context, pinValid ?? false);
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  });
              return success;
            },
            onDismissed: () async {
              bool success = await hc.deletePassword(passwordTable);
              if (success) {
                hc.passwords?.remove(passwordTable);
                Fluttertoast.showToast(msg: "Passowrd deleted successfully",
                    backgroundColor: Colors.black, textColor: Colors.white);
              }
            },
          ),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.circular(15),
              onPressed: (val) {
                showDialog(
                    barrierDismissible: true,
                    context: val,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          "Do you want to delete?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              bool? pinValid = await showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (context) {
                                    return PinInputMenuDialog(
                                      message:
                                          "The password you are trying to delete is protected with a pin. Please enter the pin to proceed.",
                                      onConfirm: (pin) {
                                        if (cc.encryptedPassword == pin) {
                                          Navigator.pop(context, true);
                                        } else {
                                          Fluttertoast.showToast(
                                              msg: "invalid pin",
                                              backgroundColor: Colors.black, textColor: Colors.white);
                                        }
                                        // if (pin == "1234") {
                                        //   Navigator.pop(context, true);
                                        // } else {
                                        //   Fluttertoast.showToast(
                                        //       msg: "invalid pin");
                                        //   // Navigator.pop(context, false);
                                        // }
                                      },
                                    );
                                  });
                              if (pinValid ?? false) {
                                hc.deletePassword(passwordTable);
                                hc.passwords?.remove(passwordTable);
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } else {
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              }
                              // if (context.mounted) Navigator.pop(context, pinValid ?? false);

                              // hc.deletePassword(passwordTable);
                              // hc.passwords?.remove(passwordTable);
                              // Navigator.pop(context, true);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    });
              },
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          elevation: 10,
          semanticContainer: false,
          surfaceTintColor: theme.colorScheme.surfaceTint,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            leading: Checkbox(
              value: true,
              onChanged: (value) {},
            ),
            title: Text(
              passwordTable.title ?? "Media Title",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              // passwordTable.userName == null
              // ? passwordTable.email!.substring(0, 3).padRight(6, "*")
              passwordTable.userName!.length < 3
                  ? passwordTable.userName!.padRight(6, "*")
                  : passwordTable.userName!.substring(0, 3).padRight(6, "*"),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            isThreeLine: false,
            contentPadding: const EdgeInsets.only(right: 10),
            trailing: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (context) {
                          return PinInputMenuDialog(
                            onConfirm: (pin) {
                              if (cc.encryptedPassword == pin) {
                                Navigator.pop(context, true);
                                navigatorKey.currentState!.pushNamed(
                                  PasswordDetailPage.routeName,
                                  arguments: PasswordDetailPageArgument(
                                    passwordTable: passwordTable,
                                    isEdit: false,
                                  ),
                                );
                              } else {
                                Fluttertoast.showToast(msg: "invalid pin",
                                    backgroundColor: Colors.black, textColor: Colors.white);
                              }
                            },
                          );
                        });
                  },
                  icon: const Icon(
                    Icons.password_rounded,
                    size: 30,
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Container(
                  height: 40,
                  width: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(
                  width: 5,
                ),
                IconButton(
                  onPressed: () async {
                    final BiometricController bc =
                        Get.find<BiometricController>();
                    await bc.refreshStatus();
                    if (!bc.isAvailable.value) {
                      Fluttertoast.showToast(
                          msg:
                              "Set up ${bc.label.value} in your phone's settings first.",
                          backgroundColor: Colors.black,
                          textColor: Colors.white);
                      return;
                    }
                    if (!bc.isEnabled.value) {
                      Fluttertoast.showToast(
                          msg:
                              "Turn on ${bc.label.value} unlock in the menu first.",
                          backgroundColor: Colors.black,
                          textColor: Colors.white);
                      return;
                    }
                    final BiometricOutcome outcome = await bc.helper
                        .authenticate("Unlock your password with ${bc.label.value}");
                    if (outcome == BiometricOutcome.success) {
                      navigatorKey.currentState!.pushNamed(
                        PasswordDetailPage.routeName,
                        arguments: PasswordDetailPageArgument(
                          passwordTable: passwordTable,
                          isEdit: false,
                        ),
                      );
                    } else if (outcome == BiometricOutcome.lockedOut) {
                      Fluttertoast.showToast(
                          msg: "Too many attempts. Use your PIN instead.",
                          backgroundColor: Colors.black,
                          textColor: Colors.white);
                    }
                  },
                  icon: const Icon(
                    Icons.fingerprint,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
