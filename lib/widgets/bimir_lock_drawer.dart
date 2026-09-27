import 'package:bimir_lock/controller/autofill/autofill_controller.dart';
import 'package:bimir_lock/controller/backup/backup_controller.dart';
import 'package:bimir_lock/controller/biometric/biometric_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/utils/constants.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:bimir_lock/utils/image_path.dart';
import 'package:bimir_lock/views/pin/change_access_pin.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:bimir_lock/widgets/contact_link_widget.dart';
import 'package:bimir_lock/widgets/drawer_tile.dart';
import 'package:bimir_lock/widgets/pin_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:bimir_lock/widgets/user_avatar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../views/user/add_user_detail.dart';

class BimirLockDrawer extends StatelessWidget {
  final CoreController cc = Get.find<CoreController>();
  final AutofillController ac = Get.find<AutofillController>();
  final BiometricController bc = Get.find<BiometricController>();
  final BackupController backup = BackupController();
  BimirLockDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Material(
                        elevation: 10,
                        borderRadius: BorderRadius.circular(100.0),
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GetBuilder<CoreController>(
                            init: cc,
                            builder: (cont) => UserAvatar(
                              file: cc.avatarFile.value,
                              iconColor: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      InkWell(
                        onTap: () {
                          navigatorKey.currentState!
                              .pushNamed(AddUserDetailPage.routeName);
                        },
                        child: DrawerTile(
                          iconData: Icons.person_add_alt_rounded,
                          title: "Edit User detail",
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          StorageHelper storageHelper = StorageHelper();
                          String? password =
                              await storageHelper.getEncryptedPassword();
                          if (password != null) {
                            navigatorKey.currentState!
                                .pushNamed(ChangeAccessPinPage.routeName);
                          } else {
                            navigatorKey.currentState!
                                .pushNamed(SetAccessPinPage.routeName);
                            Fluttertoast.showToast(
                                msg:
                                    "You have not set the access pin yet. Please set it first.",
                                backgroundColor: Colors.black,
                                textColor: Colors.white);
                          }
                        },
                        child: DrawerTile(
                          iconData: Icons.password,
                          title: "Change pin",
                        ),
                      ),
                      Obx(
                        () => DrawerTile(
                          iconData: Icons.fingerprint,
                          title: bc.label.value == "Face ID"
                              ? "Face ID unlock"
                              : "Fingerprint unlock",
                          hasSwitch: true,
                          switchValue: bc.isEnabled,
                          onSwitchChanged: (value) => bc.toggle(
                            value,
                            confirmPin: () async =>
                                await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => PinInputMenuDialog(
                                    allowBiometric: false,
                                    message:
                                        "Enter your access pin to turn on ${bc.label.value} unlock.",
                                    onConfirm: (pin) {
                                      if (cc.encryptedPassword == pin) {
                                        Navigator.pop(dialogContext, true);
                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "invalid pin",
                                            backgroundColor: Colors.black,
                                            textColor: Colors.white);
                                      }
                                    },
                                  ),
                                ) ??
                                false,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          backup.backUp();
                        },
                        child: DrawerTile(
                          iconData: Icons.backup_outlined,
                          title: "Back up passwords",
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          backup.restore();
                        },
                        child: DrawerTile(
                          iconData: Icons.restore,
                          title: "Restore from backup",
                        ),
                      ),
                      DrawerTile(
                        iconData: Icons.mode_edit,
                        title: "Dark Mode",
                        hasSwitch: true,
                      ),
                      // Android only. The tile hides itself when the
                      // device has no autofill framework, as on iOS.
                      Obx(
                        () => ac.isSupported.value
                            ? DrawerTile(
                                iconData: Icons.auto_fix_high,
                                title: "Autofill",
                                hasSwitch: true,
                                switchValue: ac.isEnabled,
                                onSwitchChanged: ac.toggleAutofill,
                              )
                            : const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      const Column(
                        children: [
                          Text(
                            "Get connected with Creator",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Wrap(
                            spacing: 20,
                            alignment: WrapAlignment.center,
                            runSpacing: 10,
                            children: [
                              ContactLinkWidget(
                                linkSvgIcon: ImagePath.linkedinIconPath,
                                linkUrl: ContactLink.linkedinLink,
                              ),
                              ContactLinkWidget(
                                linkSvgIcon: ImagePath.githubIconPath,
                                linkUrl: ContactLink.githubLink,
                              ),
                              ContactLinkWidget(
                                linkSvgIcon: ImagePath.youtubeIconPath,
                                linkUrl: ContactLink.youtubeLink,
                              ),
                              ContactLinkWidget(
                                linkSvgIcon: ImagePath.twitterIconPath,
                                linkUrl: ContactLink.twitterLink,
                              ),
                              ContactLinkWidget(
                                linkSvgIcon: ImagePath.instagramIconPath,
                                linkUrl: ContactLink.instagramLink,
                              ),
                              ContactLinkWidget(
                                linkSvgIcon: ImagePath.facebookIconPath,
                                linkUrl: ContactLink.facebookLink,
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
