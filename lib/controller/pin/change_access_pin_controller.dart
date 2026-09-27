import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class ChangeAccessPinPageController extends GetxController {
  final TextEditingController accessPinController = TextEditingController();
  final TextEditingController newAccessPinController = TextEditingController();
  final TextEditingController reNewAccessPinController =
      TextEditingController();
  StorageHelper storageHelper = StorageHelper();
  final CoreController cc = Get.find<CoreController>();
  final formKey = GlobalKey<FormState>();
  RxBool isButtonLoading = false.obs;

  Future<void> onChangeAccessPinTap() async {
    if (formKey.currentState!.validate()) {
      isButtonLoading.value = true;

      var password = await storageHelper.getEncryptedPassword();

      if (password != accessPinController.text) {
        Fluttertoast.showToast(msg: "Invalid old access pin.",
            backgroundColor: Colors.black, textColor: Colors.white);
        return;
      } else if (password == newAccessPinController.text) {
        Fluttertoast.showToast(msg: "Old and new access pin cannot be same.",
            backgroundColor: Colors.black, textColor: Colors.white);
        return;
      } else {
        await storageHelper.setEncryptedPassword(newAccessPinController.text);
        isButtonLoading.value = false;
        await cc.loadEncryptedPassword().whenComplete(() {
          navigatorKey.currentState!.pop();
          Fluttertoast.showToast(msg: "Access pin set successfully",
              backgroundColor: Colors.black, textColor: Colors.white);
        });
      }
      isButtonLoading.value = false;
    }
  }
}
