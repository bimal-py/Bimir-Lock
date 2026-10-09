import 'dart:io';

import 'package:bimir_lock/core/errors/app_error_strings.dart';
import 'package:bimir_lock/core/errors/exceptions.dart';

class AppErrorHandler {
  AppErrorHandler._();

  static String getErrorMessage(Object error) {
    if (error is SocketException) return AppErrorStrings.noInternetConnection;
    if (error is AppException) return error.message;
    return AppErrorStrings.somethingWentWrong;
  }
}
