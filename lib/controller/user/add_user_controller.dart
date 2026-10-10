import 'dart:developer';
import 'dart:io';

import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/ui/widgets.dart';
import 'package:bimir_lock/utils/helper/app_permissions.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/user_model.dart';

class AddUserDetailController extends GetxController {
  CoreController cc = Get.find<CoreController>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController userNameController = TextEditingController();
  File? userAvatar;
  File? initialUserAvatar;
  RxBool isLoading = false.obs;

  /// First run (no profile yet): saving continues to PIN setup.
  bool get isFirstRun => !cc.isUserLoggedIn();

  @override
  void onInit() {
    super.onInit();
    if (cc.isUserLoggedIn()) {
      userNameController.text = cc.currentUser.value?.userName ?? '';
      // Already resolved for this install and known to exist, so a stale path
      // from an older version shows as "no photo" and asks for a new one.
      userAvatar = cc.avatarFile.value;
      initialUserAvatar = userAvatar;
    }
  }

  @override
  void onClose() {
    userNameController.dispose();
    super.onClose();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        // Without this, iOS asks for the whole photo library just to read a
        // picture's extra metadata (location and the like), which a profile
        // photo has no use for. The picker alone needs no permission.
        requestFullMetadata: false,
      );
      if (pickedImage != null) {
        userAvatar = File(pickedImage.path);
      }
      update();
    } on PlatformException catch (e) {
      log('Failed to pick image: ${e.code}');
      final bool camera = source == ImageSource.camera;
      final BuildContext? context = navigatorKey.currentContext;
      // The phone said no (now, or earlier in Settings): say so and offer the
      // way to change it, rather than a note that explains nothing.
      if (e.code.contains('access_denied') &&
          context != null &&
          context.mounted) {
        await AppPermissions.offerSettings(
          context,
          title: camera ? 'Camera access is off' : 'Photo access is off',
          message: camera
              ? 'Taking a profile photo needs the camera. Turn on Camera for Bimir Lock in your phone\'s settings, then come back.'
              : 'Choosing a profile photo needs your photos. Allow Photos for Bimir Lock in your phone\'s settings, then come back.',
          icon: camera ? LucideIcons.camera : LucideIcons.image,
        );
        return;
      }
      showNote("Couldn't open the ${camera ? 'camera' : 'photo library'}.");
    } catch (e) {
      log('Failed to pick image: ${e.runtimeType}');
      showNote(
        "Couldn't open the ${source == ImageSource.camera ? 'camera' : 'photo library'}.",
      );
    }
  }

  void removeImage() {
    userAvatar = null;
    update();
  }

  Future<void> onSaveUserDetail(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      // The photo is optional. A picked photo whose temporary file the OS has
      // since cleared is treated as no photo rather than blocking the save.
      final File? avatar = userAvatar;
      String? imagePath;
      if (avatar != null && await avatar.exists()) {
        if (initialUserAvatar?.path == avatar.path) {
          // Unchanged: keep the stored name.
          imagePath = StorageHelper.avatarFileName(avatar.path);
        } else {
          try {
            imagePath = await StorageHelper().storeImage(
              avatar,
              replacing: cc.currentUser.value?.userAvatar,
            );
          } catch (e) {
            log("storeImage failed: ${e.runtimeType}");
            showNote("Couldn't save the photo. Please pick it again.");
            return;
          }
        }
      }

      final bool firstRun = isFirstRun;
      await StorageHelper().setUser(
        User(userName: userNameController.text.trim(), userAvatar: imagePath),
      );
      await cc.loadCurrentUser();

      if (firstRun) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          SetAccessPinPage.routeName,
          (route) => false,
          arguments: const PinSetupArgs(onboarding: true),
        );
      } else if (context.mounted) {
        showNote('Profile saved');
        Navigator.of(context).pop(true);
      }
    } finally {
      // Always, so a failed save can never leave the button spinning.
      isLoading.value = false;
    }
  }
}
