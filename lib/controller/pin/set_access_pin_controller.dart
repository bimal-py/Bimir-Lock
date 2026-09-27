import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class SetAccessPinPageController extends GetxController {
  final TextEditingController accessPinController = TextEditingController();
  final TextEditingController reAccessPinController = TextEditingController();
  final CoreController cc = Get.find<CoreController>();
  final formKey = GlobalKey<FormState>();
  RxBool isButtonLoading = false.obs;

  Future<void> onChangeAccessPinTap() async {
    if (formKey.currentState!.validate()) {
      isButtonLoading.value = true;

      StorageHelper storageHelper = StorageHelper();
      await storageHelper.setEncryptedPassword(accessPinController.text);
      isButtonLoading.value = false;
      await cc.loadEncryptedPassword().whenComplete(() {
        navigatorKey.currentState!.pop();
        Fluttertoast.showToast(msg: "Access pin set successfully",
            backgroundColor: Colors.black, textColor: Colors.white);
      });
      isButtonLoading.value = false;
    }
  }
}
