import 'package:bimir_lock/controller/homePage/home_page_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/models/password_table.dart';
import 'package:bimir_lock/utils/helper/db_helper.dart';
import 'package:bimir_lock/utils/helper/vault_crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class AddPasswordController extends GetxController {
  HomePageController homePageController = Get.find<HomePageController>();
  TextEditingController mediaTitleController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController reTypePasswordController = TextEditingController();
  // TextEditingController mediaTitleController = TextEditingController(text: "Facebook");
  // TextEditingController emailController = TextEditingController(text: "bimal@gmail.com");
  // TextEditingController userNameController = TextEditingController(text: "Bimal kc");
  // TextEditingController passwordController = TextEditingController(text: "password");
  // TextEditingController reTypePasswordController = TextEditingController(text: "password");
  RxBool hidePassword = true.obs;
  RxBool hideRetypePassword = true.obs;
  RxBool isButtonLoading = false.obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void togglePassword() {
    hidePassword.value = !hidePassword.value;
  }

  void toggleRetypePassword() {
    hideRetypePassword.value = !hideRetypePassword.value;
  }

  Future<void> onSavePassword() async {
    if (formKey.currentState!.validate()) {
      isButtonLoading.value = true;
      PasswordTable passwordTable = PasswordTable(
          title: mediaTitleController.text,
          userName: userNameController.text,
          password: passwordController.text);
      DataBaseHelper dataBaseHelper = DataBaseHelper();
      try {
        await dataBaseHelper.insertPassword(passwordTable);
      } on VaultKeyUnavailable catch (_) {
        // The save was DROPPED, so do not pop the route as though it worked.
        // Nothing was written: better a save the user can retry than a
        // password stored in a form we cannot read back.
        isButtonLoading.value = false;
        Fluttertoast.showToast(
            msg: "Couldn't secure this password on this device. "
                "Nothing was saved - please try again.",
            backgroundColor: Colors.black,
            textColor: Colors.white);
        return;
      } catch (_) {
        isButtonLoading.value = false;
        Fluttertoast.showToast(
            msg: "Couldn't save this password. Please try again.",
            backgroundColor: Colors.black,
            textColor: Colors.white);
        return;
      }

      isButtonLoading.value = false;
      homePageController
          .loadPasswords()
          .whenComplete(() => navigatorKey.currentState!.pop());
    }
    isButtonLoading.value = false;
  }
}
