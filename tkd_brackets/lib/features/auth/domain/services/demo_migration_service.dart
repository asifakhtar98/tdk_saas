/// Abstract service for demo data migration.
abstract class DemoMigrationService {
  /// Returns true if demo data exists and can be migrated.
  Future<bool> hasDemoData();

  /// Migrates all demo data to production.
  ///
  /// [newOrganizationId] — The production organization ID that will
  /// replace the demo organization ID.
  ///
  /// Returns the count of entities migrated.
  /// Throws [DemoMigrationException] on failure.
  Future<int> migrateDemoData(String newOrganizationId);
}

/// Exception thrown when demo migration fails.
class DemoMigrationException implements Exception {
  DemoMigrationException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DemoMigrationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
