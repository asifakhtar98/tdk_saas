import 'package:injectable/injectable.dart';

import 'package:tkd_brackets/core/error/error_reporting_service.dart';

/// Abstract interface for sync conflict notifications.
///
/// Placeholder for FR69: Visual notification for conflict resolution.
/// Full implementation with UI widgets will be in a future story.
abstract class SyncNotificationService {
  /// Notifies when a sync conflict has been resolved.
  ///
  /// [tableName] The database table where the conflict occurred
  /// [recordId] The UUID of the record with the conflict
  /// [winner] Which version won: 'local' or 'remote'
  void notifyConflictResolved({
    required String tableName,
    required String recordId,
    required String winner,
  });
}

/// Stub implementation of [SyncNotificationService].
///
/// Logs conflicts for now. Full visual notification implementation
/// will be added in a future UI story for FR69.
@LazySingleton(as: SyncNotificationService)
class SyncNotificationServiceImplementation implements SyncNotificationService {
  SyncNotificationServiceImplementation(this._errorReportingService);

  final ErrorReportingService _errorReportingService;

  @override
  void notifyConflictResolved({
    required String tableName,
    required String recordId,
    required String winner,
  }) {
    // Placeholder: log conflict resolution for now
    // FR69 visual notification will be implemented in UI story
    _errorReportingService.addBreadcrumb(
      message: 'Sync conflict resolved: $tableName/$recordId - $winner wins',
      category: 'sync',
      data: {'tableName': tableName, 'recordId': recordId, 'winner': winner},
    );
  }
}
