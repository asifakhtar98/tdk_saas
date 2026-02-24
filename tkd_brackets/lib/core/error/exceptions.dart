/// Base exception for data layer errors.
/// These are thrown by data sources and caught by repositories.
/// Repositories convert exceptions to Failure types for the domain layer.
abstract class AppException implements Exception {
  const AppException({required this.message, this.code, this.originalError});

  /// Error message describing what went wrong.
  final String message;

  /// Error code for categorization.
  final String? code;

  /// Original error that caused this exception.
  final dynamic originalError;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ═══════════════════════════════════════════════════════════════════════════
// Server Exceptions (Remote Data Source)
// ═══════════════════════════════════════════════════════════════════════════

/// Exception when server returns an error.
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  /// HTTP status code from the server response.
  final int? statusCode;
}

/// Exception when network is unavailable.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network connection unavailable',
    super.code,
    super.originalError,
  });
}

/// Exception when authentication is required.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Authentication required',
    super.code = '401',
    super.originalError,
  });
}

/// Exception when access is denied.
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access denied',
    super.code = '403',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Cache Exceptions (Local Data Source)
// ═══════════════════════════════════════════════════════════════════════════

/// Exception for cache-related errors.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Exception when reading from cache fails.
class CacheReadException extends CacheException {
  const CacheReadException({
    super.message = 'Failed to read from local cache',
    super.code,
    super.originalError,
  });
}

/// Exception when writing to cache fails.
class CacheWriteException extends CacheException {
  const CacheWriteException({
    super.message = 'Failed to write to local cache',
    super.code,
    super.originalError,
  });
}
