import 'dart:developer';
import 'dart:io';

import 'package:bimir_lock/controller/introScreen/quotes_category_controller.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/utils/helper/storage_helper.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../views/introScreen/welcome_page.dart';

class AddUserDetailController extends GetxController {
  CoreController cc = Get.find<CoreController>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController userNameController = TextEditingController();
  late TextEditingController dobController = TextEditingController();
  RxBool isPageLoading = false.obs;
  File? userAvatar;
  File? initialUserAvatar;
  RxBool isLoading = false.obs;
  @override
  void onInit() async {
    // showProgressIndicator();
    // String userName =
    await initialfetch();
    if (cc.isUserLoggedIn()) {}

    super.onInit();
  }

  Future<void> initialfetch() async {
    isPageLoading.value = true;
    if (cc.isUserLoggedIn()) {
      String userName = cc.currentUser.value!.userName!;
      String dob = cc.currentUser.value!.dob!;
      userNameController = TextEditingController(text: userName);
      dobController = TextEditingController(text: dob);
      userAvatar = cc.currentUser.value?.userAvatar != null
          ? File(cc.currentUser.value!.userAvatar!)
          : null;
      initialUserAvatar = userAvatar;
    } else {
      userNameController = TextEditingController();
      dobController = TextEditingController();
    }
    isPageLoading.value = false;
    update();
  }

  // showProgressIndicator() {
  //   isPageLoading.value = true;
  //   if (cc.currentUser.value != null) {
  //     userNameController = TextEditingController(text: cc.currentUser.value!.userName);
  //     dobController = TextEditingController(text: cc.currentUser.value!.dob);
  //     userAvatar =
  //         cc.currentUser.value?.userAvatar != null ? File(cc.currentUser.value!.userAvatar!) : null;
  //   }
  //   isPageLoading.value = false;
  //   update();
  // }

  Future pickImage(ImageSource source) async {
    try {
      XFile? pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        userAvatar = File(pickedImage.path);
      }
      update();
    } catch (e) {
      log('======>>>Failed to pick image: $e');
    }
  }

  Future<void> onSaveUserDetail(BuildContext context) async {
    FocusManager.instance.primaryFocus!.unfocus();
    if (userAvatar == null) {
      Fluttertoast.showToast(msg: "Upload Profile Image to save user",
          backgroundColor: Colors.black, textColor: Colors.white);
      return;
    }
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      String imagePath = "";
      if (initialUserAvatar?.path == userAvatar?.path) {
        imagePath = userAvatar!.path;
      } else {
        imagePath = await StorageHelper().storeImage(userAvatar!);
      }

      User userModel = User(
        dob: dobController.text,
        userName: userNameController.text,
        userAvatar: imagePath,
      );

      //if user detail is null then it is first time.
      if (cc.isUserLoggedIn()) {
        //save user
        await StorageHelper().setUser(userModel);
        await cc.loadCurrentUser();
        if (context.mounted) Navigator.of(context).pop(true);
      } else {
        //save user
        await StorageHelper().setUser(userModel);
        //load quotes;
        try {
          QuotesCategoryController c = Get.find<QuotesCategoryController>();
          await c.loadQuotes();
          await cc.loadCurrentUser();
        } catch (e) {
          log("========>>>>>> Error: $e");
        }
        try {
          cc.loadInitQuote().then((value) => navigatorKey.currentState!
              .pushNamedAndRemoveUntil(
                  WelcomePage.routeName, (route) => false));
        } catch (e) {
          log("============>>>Error while loading initial quotes");
        }
      }
    }

    isLoading.value = false;
  }
}
