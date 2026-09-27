import 'package:auto_size_text/auto_size_text.dart';
import 'package:bimir_lock/core/core_controller.dart';
import 'package:bimir_lock/main.dart';
import 'package:bimir_lock/views/homePage/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../utils/image_path.dart';

class WelcomePage extends StatefulWidget {
  static const String routeName = "/welcome";
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final CoreController cc = Get.put(CoreController());

  AutoSizeGroup autoSizeGroup = AutoSizeGroup();

  @override
  void initState() {
    Future.delayed((const Duration(seconds: 3))).whenComplete(() => navigatorKey
        .currentState!
        .pushNamedAndRemoveUntil(HomePage.routeName, (route) => false));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    //for assigning height
    var mHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: SafeArea(
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 15,
            ),
            Container(
              height: mHeight / 5,
              // width: 50,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Image.asset(ImagePath.logoBPath),
            ),
            SizedBox(
              height: mHeight / 13,
            ),
            Container(
              // height: mHeight / 3,
              constraints: BoxConstraints(
                maxHeight: mHeight / 3,
                // minHeight:
              ),
              child: AutoSizeText(
                "\"${cc.initialQuote.value?.quote}\"",
                group: autoSizeGroup,
                maxFontSize: 26,
                minFontSize: 12,
                style: const TextStyle(
                  fontSize: 28,
                  wordSpacing: 1,
                  letterSpacing: 0.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: AutoSizeText(
                "- ${cc.initialQuote.value?.author}",
                group: autoSizeGroup,
                style: const TextStyle(
                  fontSize: 25,
                  wordSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            Column(
              children: [
                const Text("Welcome to Bimir Lock",
                    style: TextStyle(
                      fontSize: 25,
                    )),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  cc.currentUser.value!.userName!
                      .split(' ')
                      .first
                      .capitalizeFirst!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                SizedBox(
                    // height: 10,
                    child: LoadingAnimationWidget.fourRotatingDots(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  size: 50,
                )),
                const SizedBox(
                  height: 20,
                ),
              ],
            )
          ],
        ),
      )),
    );
  }
}
