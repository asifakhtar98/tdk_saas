import 'package:equatable/equatable.dart';

/// Base failure class for all domain-level errors.
/// All use cases return `Either<Failure, T>`.
///
/// Failures are user-facing errors that bubble up from the domain layer.
/// For data-layer errors, use Exception types instead.
abstract class Failure extends Equatable {
  const Failure({required this.userFriendlyMessage, this.technicalDetails});

  /// Message safe to display to end users.
  final String userFriendlyMessage;

  /// Technical details for logging/debugging (not shown to users).
  final String? technicalDetails;

  @override
  List<Object?> get props => [userFriendlyMessage, technicalDetails];
}

// ═══════════════════════════════════════════════════════════════════════════
// Network Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when unable to connect to the server.
class ServerConnectionFailure extends Failure {
  const ServerConnectionFailure({
    super.userFriendlyMessage =
        'Unable to connect to server. Please check your internet connection.',
    super.technicalDetails,
  });
}

/// Failure when server returns an error response.
class ServerResponseFailure extends Failure {
  const ServerResponseFailure({
    required super.userFriendlyMessage,
    super.technicalDetails,
    this.statusCode,
  });

  /// HTTP status code from the server response.
  final int? statusCode;

  @override
  List<Object?> get props => [
    userFriendlyMessage,
    technicalDetails,
    statusCode,
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// Local Storage Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when unable to access local storage.
class LocalCacheAccessFailure extends Failure {
  const LocalCacheAccessFailure({
    super.userFriendlyMessage = 'Unable to access local storage.',
    super.technicalDetails,
  });
}

/// Failure when unable to write to local storage.
class LocalCacheWriteFailure extends Failure {
  const LocalCacheWriteFailure({
    super.userFriendlyMessage = 'Unable to save data locally.',
    super.technicalDetails,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Sync Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when data synchronization fails.
class DataSynchronizationFailure extends Failure {
  const DataSynchronizationFailure({
    super.userFriendlyMessage = 'Unable to sync data. Changes saved locally.',
    super.technicalDetails,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Validation Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when input validation fails.
class InputValidationFailure extends Failure {
  const InputValidationFailure({
    required super.userFriendlyMessage,
    required this.fieldErrors,
  });

  /// Map of field names to error messages.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [userFriendlyMessage, fieldErrors];
}

// ═══════════════════════════════════════════════════════════════════════════
// Authentication Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure when user session has expired.
class AuthenticationSessionExpiredFailure extends Failure {
  const AuthenticationSessionExpiredFailure({
    super.userFriendlyMessage =
        'Your session has expired. Please sign in again.',
  });
}

/// Failure when user lacks permission for an action.
class AuthorizationPermissionDeniedFailure extends Failure {
  const AuthorizationPermissionDeniedFailure({
    super.userFriendlyMessage =
        'You do not have permission to perform this action.',
    super.technicalDetails,
  });
}

/// Generic failure for authentication errors.
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.userFriendlyMessage,
    super.technicalDetails,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Demo Migration Failures
// ═══════════════════════════════════════════════════════════════════════════

/// Failure reasons for demo migration.
enum DemoMigrationFailureReason {
  /// No demo data exists to migrate.
  noData,

  /// Migration is already in progress.
  alreadyInProgress,

  /// Data integrity check failed.
  dataIntegrity,
}

/// Failure when demo data migration fails.
class DemoMigrationFailure extends Failure {
  const DemoMigrationFailure({
    required this.reason,
    required super.userFriendlyMessage,
    super.technicalDetails,
  });

  /// The specific reason for the migration failure.
  final DemoMigrationFailureReason reason;

  @override
  List<Object?> get props => [userFriendlyMessage, technicalDetails, reason];
}
