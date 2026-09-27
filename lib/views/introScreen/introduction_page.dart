import 'package:bimir_lock/utils/image_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../../controller/introScreen/introduction_controller.dart';

class IntroductionPage extends StatelessWidget {
  static const String routeName = "/introduction";
  final c = IntroductionController();
  IntroductionPage({super.key});

  final introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: IntroductionScreen(
              key: introKey,
              allowImplicitScrolling: false,
              pages: [
                PageViewModel(
                    title: "Robust Authentication",
                    body:
                        "Bimir-Lock employs a robust authentication system to ensure that only authorized users can access your passwords.",
                    image: SvgPicture.asset(
                      ImagePath.intro1Path,
                      width: width * 0.5,
                    )
                    // decoration: pageDecoration,
                    ),
                PageViewModel(
                  title: "Anytime Access",
                  body:
                      "Access your passwords anytime, anywhere with Bimir-Lock's mobile accessibility. Whether you're on the go or at home, our app puts your security in your hands, allowing you to manage your passwords with ease and convenience.",
                  image: SvgPicture.asset(
                    ImagePath.intro2Path,
                    width: width * 0.5,
                  ),
                ),
                PageViewModel(
                  title: "Regular Updates",
                  body:
                      "Benefit from regular updates and enhancements with Bimir-Lock. Our team is committed to staying ahead of emerging threats, ensuring that your data is protected with the latest security measures.",
                  image: SvgPicture.asset(
                    ImagePath.intro3Path,
                    width: width * 0.5,
                  ),
                ),
                PageViewModel(
                  title: "Performance Optimization",
                  body:
                      "Enjoy optimal performance with Bimir-Lock's efficient design. Our app minimizes resource usage while maximizing security and usability, providing you with a seamless and responsive experience.",
                  image: SvgPicture.asset(
                    ImagePath.intro4Path,
                    width: width * 0.5,
                  ),
                ),
              ],
              onDone: () => c.onIntroEnd(),
              onSkip: () => c.onIntroEnd(), // You can override onSkip callback
              showSkipButton: true,
              skipOrBackFlex: 0,
              nextFlex: 0,
              showBackButton: false,

              back: const Icon(Icons.arrow_back),
              skip: const Text('Skip',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              next: const Icon(Icons.arrow_forward),
              done: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              curve: Curves.fastLinearToSlowEaseIn,
              controlsMargin: const EdgeInsets.all(16),
              controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
              dotsDecorator: const DotsDecorator(
                size: Size(10.0, 10.0),
                color: Color(0xFFBDBDBD),
                activeSize: Size(22.0, 10.0),
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
