import 'package:bimir_lock/core/utils/helpers/dialog/dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

/// The one runtime permission Bimir Lock asks for, the camera, handled the way
/// the Callbreak Tracker app's PermissionHelper handles photos: ask once, and
/// when the answer was "never", say so and offer the phone's settings instead
/// of failing silently.
///
/// Photos need no permission: the profile photo comes through the system photo
/// picker (iOS 14+, Android 13+), which hands over only the picture chosen.
/// Asking for the library anyway would add a prompt that does nothing, so the
/// Podfile compiles photo access out (PERMISSION_PHOTOS=0).
class AppPermissions {
  AppPermissions._();

  /// True when the camera may be used. Asks the system the first time; after
  /// a permanent refusal, offers to open Settings with [why] as the reason.
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
      // No permission plugin (tests, an unsupported platform): let the camera
      // plugin ask, as it did before.
      return true;
    }
    // Refused for good ("Don't allow" twice on Android, or once on iOS), or
    // blocked by a profile: the system will not ask again, so only Settings
    // can change it.
    if ((status.isPermanentlyDenied || status.isRestricted) &&
        context.mounted) {
      await _offerSettings(context, why: why);
    }
    return false;
  }

  static Future<void> _offerSettings(
    BuildContext context, {
    required String why,
  }) async {
    final bool open = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Camera access is off',
      message:
          '$why Turn on Camera for Bimir Lock in your phone\'s settings, then come back.',
      confirmText: 'Open Settings',
      cancelText: 'Not now',
      icon: LucideIcons.camera,
    );
    if (open) await openAppSettings();
  }
}
