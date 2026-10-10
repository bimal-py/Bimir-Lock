import 'dart:io' show Platform;

import 'package:app_settings/app_settings.dart';
import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

/// What happens when the phone says no. The rule everywhere: ask once while
/// the system is still willing to ask, and once it is not ("Don't allow" for
/// good, or switched off in Settings), say why it matters and offer the way to
/// the right settings page — never fail silently, never nag.
///
/// The camera is the one runtime permission Bimir Lock asks for, handled the
/// way the Callbreak Tracker app's PermissionHelper handles photos. Photos need
/// none: the profile photo comes through the system photo picker (iOS 14+,
/// Android 13+), which hands over only the picture chosen, so the Podfile
/// compiles photo access out (PERMISSION_PHOTOS=0).
class AppPermissions {
  AppPermissions._();

  /// Whether the camera may be used right now. Never prompts — the keypad uses
  /// it, where a system dialog in front of whoever is guessing would be wrong.
  static Future<bool> cameraGranted() async {
    try {
      final PermissionStatus status = await Permission.camera.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      // No permission plugin (tests, an unsupported platform).
      return true;
    }
  }

  /// True when the camera may be used. Asks the system while it still will;
  /// after a permanent refusal, offers Settings with [why] as the reason.
  static Future<bool> camera(
    BuildContext context, {
    required String why,
  }) async {
    PermissionStatus status;
    try {
      status = await Permission.camera.status;
      if (status.isGranted || status.isLimited) return true;
      if (status.isDenied) {
        status = await Permission.camera.request();
        if (status.isGranted || status.isLimited) return true;
      }
    } catch (_) {
      // No permission plugin: let the camera plugin ask, as it did before.
      return true;
    }
    // Refused for good ("Don't allow" twice on Android, once on iOS), or
    // blocked by a profile: the system will not ask again, so only Settings
    // can change it.
    if ((status.isPermanentlyDenied || status.isRestricted) &&
        context.mounted) {
      await offerSettings(
        context,
        title: 'Camera access is off',
        message:
            '$why Turn on Camera for Bimir Lock in your phone\'s settings, then come back.',
        icon: LucideIcons.camera,
      );
    }
    return false;
  }

  /// "It is off; open Settings?" — this app's page in the phone's settings,
  /// where its camera, photo and Face ID switches are.
  static Future<void> offerSettings(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = LucideIcons.settings,
  }) async {
    final bool open = await DialogUtils.showConfirmationDialog(
      context,
      title: title,
      message: message,
      confirmText: 'Open Settings',
      cancelText: 'Not now',
      icon: icon,
    );
    if (open) await openAppPage();
  }

  /// This app's own page in the phone's settings.
  static Future<void> openAppPage() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }

  /// Where fingerprints and faces are enrolled: the security settings on
  /// Android. iOS has no link to Face ID & Passcode, so the Settings app
  /// opens on this app's page instead.
  static Future<void> openSecurity() async {
    try {
      Platform.isAndroid
          ? await AppSettings.openAppSettings(type: AppSettingsType.security)
          : await openAppSettings();
    } catch (_) {}
  }
}
