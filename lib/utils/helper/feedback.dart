import 'dart:io';

import 'package:bimir_lock/utils/constants.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings › Help: "Report a problem" and "Rate Bimir Lock", after the
/// Callbreak Tracker app's EmailHelper and support section.
class AppFeedback {
  AppFeedback._();

  /// Opens the user's email app with a report addressed to the developer.
  ///
  /// The body carries only what helps reproduce a bug — app version, system
  /// version, device model — and the user sees and can edit all of it before
  /// anything is sent. Nothing leaves the phone unless they press Send. Returns
  /// false when no email app could be opened.
  static Future<bool> reportProblem() async {
    final String body = await reportBody();
    final Uri mail = Uri(
      scheme: 'mailto',
      path: ContactLink.email,
      // Built by hand: Uri's queryParameters writes spaces as "+", which mail
      // apps show literally.
      query:
          'subject=${Uri.encodeComponent(await reportSubject())}'
          '&body=${Uri.encodeComponent(body)}',
    );
    try {
      return await launchUrl(mail, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<String> reportSubject() async =>
      'Bimir Lock ${await _appVersion()}: problem report';

  /// The prefilled email. Public so a test can check it never asks for a
  /// password.
  static Future<String> reportBody() async {
    return <String>[
      'What happened:',
      '',
      '',
      'What you expected:',
      '',
      '',
      'Steps to make it happen again:',
      '',
      '',
      'Please never send a password, PIN or backup password in this email.',
      '',
      '— Details (edit or delete anything you prefer not to share) —',
      'App: Bimir Lock ${await _appVersion()}',
      'System: ${await _system()}',
    ].join('\n');
  }

  /// "Rate Bimir Lock": the app's page on the App Store or Google Play.
  ///
  /// The store page, not the in-app rating sheet: this is the user's own
  /// choice, the sheet may be rationed by the OS and not appear, and a store
  /// page always does. The automatic sheet is ReviewPrompt's job.
  static Future<bool> openStorePage() async {
    try {
      await InAppReview.instance.openStoreListing(
        appStoreId: StoreLink.appStoreId,
      );
      return true;
    } catch (_) {
      final Uri page = Uri.parse(
        Platform.isIOS ? StoreLink.appStore : StoreLink.googlePlay,
      );
      try {
        return await launchUrl(page, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<String> _appVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (_) {
      return 'unknown version';
    }
  }

  static Future<String> _system() async {
    try {
      final DeviceInfoPlugin device = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final AndroidDeviceInfo a = await device.androidInfo;
        return '${a.manufacturer} ${a.model}, Android ${a.version.release} '
            '(API ${a.version.sdkInt})';
      }
      if (Platform.isIOS) {
        final IosDeviceInfo i = await device.iosInfo;
        return '${i.utsname.machine}, ${i.systemName} ${i.systemVersion}';
      }
    } catch (_) {
      // Fall through to what dart:io knows without a plugin.
    }
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }
}
