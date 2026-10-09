import 'package:bimir_lock/ui/tokens.dart';
import 'package:bimir_lock/views/faq/faq_page.dart';
import 'package:bimir_lock/views/homePage/add_password.dart';
import 'package:bimir_lock/views/homePage/checkup_page.dart';
import 'package:bimir_lock/views/homePage/home_page.dart';
import 'package:bimir_lock/views/homePage/password_detail.dart';
import 'package:bimir_lock/views/introScreen/introduction_page.dart';
import 'package:bimir_lock/views/introScreen/welcome_page.dart';
import 'package:bimir_lock/views/intruder_page.dart';
import 'package:bimir_lock/modules/notes/notes_bootstrap.dart';
import 'package:bimir_lock/views/pin/change_access_pin.dart';
import 'package:bimir_lock/views/pin/set_access_pin.dart';
import 'package:bimir_lock/views/settings_page.dart';
import 'package:bimir_lock/views/splash_page.dart';
import 'package:bimir_lock/views/user/add_user_detail.dart';
import 'package:flutter/material.dart';

/// Launch, quote and first vault screen "fade through" so the brand mark (a
/// Hero) glides between them; everything else uses the platform's own
/// transition.
const Set<String> _fadeRoutes = <String>{
  SplashPage.routeName,
  WelcomePage.routeName,
  IntroductionPage.routeName,
  HomePage.routeName,
};

Route<dynamic>? generatedRoute(RouteSettings settings) {
  final Route<dynamic>? notes = notesGeneratedRoute(settings);
  if (notes != null) return notes;
  final WidgetBuilder? builder = switch (settings.name) {
    SplashPage.routeName => (_) => const SplashPage(),
    WelcomePage.routeName => (_) => const WelcomePage(),
    IntroductionPage.routeName => (_) => const IntroductionPage(),
    AddUserDetailPage.routeName => (_) => const AddUserDetailPage(),
    HomePage.routeName => (_) => HomePage(),
    AddPasswordPage.routeName => (_) => const AddPasswordPage(),
    PasswordDetailPage.routeName => (_) => const PasswordDetailPage(),
    SetAccessPinPage.routeName => (_) => const SetAccessPinPage(),
    ChangeAccessPinPage.routeName => (_) => const ChangeAccessPinPage(),
    SettingsPage.routeName => (_) => const SettingsPage(),
    CheckupPage.routeName => (_) => const CheckupPage(),
    IntruderPage.routeName => (_) => const IntruderPage(),
    FaqPage.routeName => (_) => const FaqPage(),
    _ => null,
  };
  if (builder == null) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('No route defined for ${settings.name}')),
      ),
    );
  }
  if (_fadeRoutes.contains(settings.name)) {
    return _LaunchRoute(
      settings: settings,
      builder: builder,
      // Long enough for the logo's glide to read as one calm movement.
      duration: switch (settings.name) {
        WelcomePage.routeName => const Duration(milliseconds: 700),
        HomePage.routeName => const Duration(milliseconds: 560),
        _ => Motion.slow,
      },
    );
  }
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}

/// Between two launch screens: the old one fades out over the first third,
/// the new one fades in over the rest, and in between only the logo is moving
/// (over the plain background MaterialApp.builder lays under every page). A
/// cross-fade instead shows both pages half see-through at once, with the
/// logo flying over the muddle.
class _LaunchRoute extends PageRouteBuilder<dynamic> {
  _LaunchRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
    required Duration duration,
  }) : super(
         settings: settings,
         transitionDuration: duration,
         reverseTransitionDuration: Motion.base,
         pageBuilder: (BuildContext context, _, _) => builder(context),
         transitionsBuilder:
             (_, Animation<double> a, Animation<double> out, Widget child) =>
                 FadeTransition(
                   opacity: ReverseAnimation(
                     CurvedAnimation(
                       parent: out,
                       curve: const Interval(0, 0.35, curve: Curves.easeIn),
                     ),
                   ),
                   child: FadeTransition(
                     opacity: CurvedAnimation(
                       parent: a,
                       curve: const Interval(0.3, 1, curve: Curves.easeOut),
                     ),
                     child: child,
                   ),
                 ),
       );

  /// Fades out only for another launch screen. Under anything else (a
  /// platform page sliding in over the vault) it stays as it is.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is _LaunchRoute;
}
