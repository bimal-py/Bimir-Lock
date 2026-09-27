import 'dart:io';

import 'package:bimir_lock/utils/helper/storage_helper.dart';
import 'package:intl/intl.dart';

extension DateFormatter on DateTime {
  String formatDate() {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}

extension GetExtension on File {
  String getExtension() {
    return path.substring(path.lastIndexOf('.'), path.length);
  }

  Future<String> getNewDbFilePath() async {
    var newPath = await StorageHelper().getImageLocation();
    var ext = getExtension();
    return "$newPath/image$ext";
  }
}
