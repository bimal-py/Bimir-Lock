import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bimir_lock/utils/helper/pin_guard.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One time the keypad locked after too many wrong PINs.
@immutable
class IntruderEvent {
  const IntruderEvent({required this.at, required this.attempt, this.photo});

  final DateTime at;

  /// Which wrong PIN in a row this was: 10 for the first lock, 17 for the next…
  final int attempt;

  /// File name inside the intruder folder, or null when no photo was taken
  /// (turned off, no camera, or the camera refused). Only the name is kept:
  /// the app's folder path changes across iOS updates.
  final String? photo;

  Map<String, Object?> toJson() => <String, Object?>{
    'at': at.millisecondsSinceEpoch,
    'attempt': attempt,
    'photo': photo,
  };

  static IntruderEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? at = json['at'];
    final Object? attempt = json['attempt'];
    final Object? photo = json['photo'];
    if (at is! int || attempt is! int) return null;
    return IntruderEvent(
      at: DateTime.fromMillisecondsSinceEpoch(at),
      attempt: attempt,
      photo: photo is String ? photo : null,
    );
  }
}

/// Wrong-PIN alerts, with an optional front-camera photo of whoever typed
/// them. Every lock of the keypad is recorded (see PinGuard.stages: the 10th
/// wrong PIN in a row, then the 17th, 22nd, 25th…); the photo is taken only when the owner switched it on,
/// which is also when the camera permission was asked for, so the system
/// never asks the person at the keypad.
///
/// Photos stay in the app's own storage and are never uploaded.
class IntruderWatch {
  IntruderWatch._();

  static const String _enabledKey = 'intruder_photo_on';
  static const String _logKey = 'intruder_log';
  static const String _unseenKey = 'intruder_unseen';
  static const String _folder = 'intruders';

  /// Older entries (and their photos) are dropped past this many.
  static const int keep = 30;

  /// Locks not yet looked at by the owner. The vault shows a banner while
  /// this is above zero.
  static final ValueNotifier<int> unseen = ValueNotifier<int>(0);

  static bool _capturing = false;

  static Future<bool> isEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool on) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, on);
  }

  /// Opens the front camera once and closes it again, without taking a
  /// photo. This is what asks for the camera permission, while the owner is
  /// the one holding the phone. False when there is no camera or it was
  /// refused.
  static Future<bool> checkCamera() async {
    CameraController? controller;
    try {
      controller = CameraController(
        await _frontCamera(),
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      return true;
    } catch (e) {
      log('intruder camera check failed: ${e.runtimeType}');
      return false;
    } finally {
      await controller?.dispose();
    }
  }

  /// Records a wrong PIN, and when it locked the keypad, logs the lock and
  /// (if switched on) takes the photo. Returns the lock. Never throws for the
  /// photo: a failed capture must not get in the way of the keypad.
  static Future<Duration> recordWrongPin() async {
    final Duration lock = await PinGuard.recordFailure();
    if (lock > Duration.zero) {
      final int attempt = await PinGuard.failures();
      unawaited(_onLock(attempt));
    }
    return lock;
  }

  static Future<void> _onLock(int attempt) async {
    String? photo;
    if (await isEnabled()) photo = await _capture();
    await _append(
      IntruderEvent(at: DateTime.now(), attempt: attempt, photo: photo),
    );
  }

  static Future<CameraDescription> _frontCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('no camera');
    return cameras.firstWhere(
      (CameraDescription c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  static Future<String?> _capture() async {
    // A second lock while the first photo is still being taken.
    if (_capturing) return null;
    _capturing = true;
    CameraController? controller;
    try {
      controller = CameraController(
        await _frontCamera(),
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      // The first frames come out dark while exposure settles.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final XFile shot = await controller.takePicture();
      final Directory dir = await _dir();
      final String name = 'intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(shot.path).copy('${dir.path}/$name');
      try {
        await File(shot.path).delete();
      } catch (_) {}
      return name;
    } catch (e) {
      log('intruder photo failed: ${e.runtimeType}');
      return null;
    } finally {
      await controller?.dispose();
      _capturing = false;
    }
  }

  static Future<Directory> _dir() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}/$_folder');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// The photo's file, or null when there is none or it has gone missing.
  static Future<File?> photoFile(IntruderEvent e) async {
    final String? name = e.photo;
    if (name == null) return null;
    final File f = File('${(await _dir()).path}/$name');
    return f.existsSync() ? f : null;
  }

  /// Newest first.
  static Future<List<IntruderEvent>> events() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_logKey);
    if (raw == null) return <IntruderEvent>[];
    try {
      final Object? list = jsonDecode(raw);
      if (list is! List) return <IntruderEvent>[];
      return <IntruderEvent>[
        for (final Object? item in list) ?IntruderEvent.fromJson(item),
      ]..sort((IntruderEvent a, IntruderEvent b) => b.at.compareTo(a.at));
    } on FormatException {
      return <IntruderEvent>[];
    }
  }

  static Future<void> _save(List<IntruderEvent> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _logKey,
      jsonEncode(list.map((IntruderEvent e) => e.toJson()).toList()),
    );
  }

  static Future<void> _append(IntruderEvent e) async {
    final List<IntruderEvent> list = await events();
    list.insert(0, e);
    while (list.length > keep) {
      await _deletePhoto(list.removeLast());
    }
    await _save(list);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int count = (prefs.getInt(_unseenKey) ?? 0) + 1;
    await prefs.setInt(_unseenKey, count);
    unseen.value = count;
  }

  /// Reads the unseen count from disk into [unseen].
  static Future<void> refresh() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    unseen.value = prefs.getInt(_unseenKey) ?? 0;
  }

  static Future<void> markSeen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_unseenKey);
    unseen.value = 0;
  }

  static Future<void> delete(IntruderEvent e) async {
    final List<IntruderEvent> list = await events();
    list.removeWhere(
      (IntruderEvent x) =>
          x.at == e.at && x.attempt == e.attempt && x.photo == e.photo,
    );
    await _deletePhoto(e);
    await _save(list);
  }

  static Future<void> clear() async {
    for (final IntruderEvent e in await events()) {
      await _deletePhoto(e);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
    await markSeen();
  }

  static Future<void> _deletePhoto(IntruderEvent e) async {
    try {
      await (await photoFile(e))?.delete();
    } catch (_) {}
  }
}
