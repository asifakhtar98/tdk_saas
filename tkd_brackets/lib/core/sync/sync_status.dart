import 'package:flutter/foundation.dart';

/// Represents the current synchronization status with the remote server.
///
/// Used by SyncService to communicate sync state changes throughout
/// the application, particularly for UI indicators.
enum SyncStatus {
  /// All local changes have been successfully synced to remote.
  synced,

  /// A sync operation is currently in progress.
  syncing,

  /// There are local changes waiting to be synced.
  pendingChanges,

  /// The last sync operation failed with an error.
  error,
}

/// Holds error details when [SyncStatus] is [SyncStatus.error].
///
/// Provides both user-friendly and technical error information
/// for display and debugging purposes.
@immutable
class SyncError {
  /// Creates a new [SyncError] with the given details.
  const SyncError({
    required this.message,
    this.technicalDetails,
    this.failedOperationCount = 0,
  });

  /// User-friendly error message suitable for display in UI.
  final String message;

  /// Technical details for debugging (logged to error service).
  final String? technicalDetails;

  /// Number of operations that failed during sync.
  final int failedOperationCount;

  @override
  String toString() => 'SyncError(message: $message, '
      'technicalDetails: $technicalDetails, '
      'failedOperationCount: $failedOperationCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          technicalDetails == other.technicalDetails &&
          failedOperationCount == other.failedOperationCount;

  @override
  int get hashCode =>
      Object.hash(message, technicalDetails, failedOperationCount);
}
