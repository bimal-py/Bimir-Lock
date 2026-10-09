/// Thrown by infrastructure (storage, platform). Catch in repositories and
/// translate into a [Failure].
class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}

class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}
