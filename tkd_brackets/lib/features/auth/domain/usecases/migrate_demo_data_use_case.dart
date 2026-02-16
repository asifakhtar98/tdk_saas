import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/data/services/demo_migration_service.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/migrate_demo_data_params.dart';

/// Use case to migrate demo data to production when a user
/// transitions from demo mode to authenticated production mode.
///
/// This use case:
/// 1. Validates that demo data exists
/// 2. Checks idempotency (cannot run if already migrated)
/// 3. Orchestrates UUID remapping for all entities
/// 4. Preserves referential integrity across all tables
/// 5. Triggers post-migration sync
@injectable
class MigrateDemoDataUseCase extends UseCase<Unit, MigrateDemoDataParams> {
  MigrateDemoDataUseCase(this._migrationService, this._errorReportingService);

  final DemoMigrationService _migrationService;
  final ErrorReportingService _errorReportingService;

  @override
  Future<Either<Failure, Unit>> call(MigrateDemoDataParams params) async {
    try {
      // Check if demo data exists
      final hasDemoData = await _migrationService.hasDemoData();
      if (!hasDemoData) {
        // Gracefully skip if no demo data - this is not a failure
        return const Right(unit);
      }

      // Perform the migration
      final migratedCount = await _migrationService.migrateDemoData(
        params.newOrganizationId,
      );

      _errorReportingService.addBreadcrumb(
        message: 'Demo data migration completed successfully',
        category: 'migration',
        data: {
          'migratedCount': migratedCount,
          'newOrganizationId': params.newOrganizationId,
        },
      );

      return const Right(unit);
    } on DemoMigrationException catch (e) {
      // Map specific exception types to failure types
      final failure = _mapExceptionToFailure(e);

      _errorReportingService.addBreadcrumb(
        message: 'Demo data migration failed',
        category: 'migration',
        data: {'error': e.message, 'cause': e.cause?.toString()},
      );

      return Left(failure);
    } on Exception catch (e, stackTrace) {
      // Report unexpected errors
      _errorReportingService.reportException(
        e,
        stackTrace,
        context: 'MigrateDemoDataUseCase',
      );

      return Left(
        DemoMigrationFailure(
          reason: DemoMigrationFailureReason.dataIntegrity,
          userFriendlyMessage: 'Failed to migrate demo data. Please try again.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Maps [DemoMigrationException] to appropriate [DemoMigrationFailure].
  DemoMigrationFailure _mapExceptionToFailure(DemoMigrationException e) {
    final message = e.message.toLowerCase();

    if (message.contains('no demo data')) {
      return DemoMigrationFailure(
        reason: DemoMigrationFailureReason.noData,
        userFriendlyMessage: 'No demo data found to migrate.',
        technicalDetails: e.message,
      );
    }

    if (message.contains('already in progress') ||
        message.contains('production data already exists')) {
      return DemoMigrationFailure(
        reason: DemoMigrationFailureReason.alreadyInProgress,
        userFriendlyMessage:
            'Migration has already been completed or is in progress.',
        technicalDetails: e.message,
      );
    }

    if (message.contains('referential integrity') ||
        message.contains('foreign key')) {
      return DemoMigrationFailure(
        reason: DemoMigrationFailureReason.dataIntegrity,
        userFriendlyMessage:
            'Data integrity error during migration. Please contact support.',
        technicalDetails: e.message,
      );
    }

    // Default to data integrity failure
    return DemoMigrationFailure(
      reason: DemoMigrationFailureReason.dataIntegrity,
      userFriendlyMessage: 'An error occurred during data migration.',
      technicalDetails: e.message,
    );
  }
}
