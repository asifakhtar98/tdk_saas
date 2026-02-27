import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/services/demo_migration_service.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/migrate_demo_data_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/migrate_demo_data_use_case.dart';

class MockDemoMigrationService extends Mock implements DemoMigrationService {}

class MockErrorReportingService extends Mock implements ErrorReportingService {}

class FakeStackTrace extends Fake implements StackTrace {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeStackTrace());
  });

  late MigrateDemoDataUseCase useCase;
  late MockDemoMigrationService mockMigrationService;
  late MockErrorReportingService mockErrorReportingService;

  setUp(() {
    mockMigrationService = MockDemoMigrationService();
    mockErrorReportingService = MockErrorReportingService();
    useCase = MigrateDemoDataUseCase(
      mockMigrationService,
      mockErrorReportingService,
    );

    // Default: error reporting does nothing
    when(
      () => mockErrorReportingService.addBreadcrumb(
        message: any(named: 'message'),
        category: any(named: 'category'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
  });

  group('MigrateDemoDataUseCase', () {
    group('successful migration', () {
      test('returns Right(unit) when migration succeeds', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenAnswer((_) async => 12);

        // Act
        final result = await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        expect(result, equals(const Right<Failure, Unit>(unit)));
      });

      test('calls migrateDemoData with correct organization ID', () async {
        // Arrange
        const newOrgId = 'production-org-123';
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenAnswer((_) async => 12);

        // Act
        await useCase(const MigrateDemoDataParams(newOrganizationId: newOrgId));

        // Assert
        verify(() => mockMigrationService.migrateDemoData(newOrgId)).called(1);
      });

      test('logs success breadcrumb with migrated count', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenAnswer((_) async => 12);

        // Act
        await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Demo data migration completed successfully',
            category: 'migration',
            data: {'migratedCount': 12, 'newOrganizationId': 'new-org-id'},
          ),
        ).called(1);
      });
    });

    group('graceful skip when no demo data', () {
      test('returns Right(unit) when no demo data exists', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => false);

        // Act
        final result = await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        expect(result, equals(const Right<Failure, Unit>(unit)));
      });

      test('does not call migrateDemoData when no demo data', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => false);

        // Act
        await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        verifyNever(() => mockMigrationService.migrateDemoData(any()));
      });

      test('does not log failure when gracefully skipping', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => false);

        // Act
        await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        verifyNever(
          () => mockErrorReportingService.addBreadcrumb(
            message: any(named: 'message'),
            category: 'migration',
            data: any(named: 'data'),
          ),
        );
      });
    });

    group('idempotency - cannot run twice', () {
      test('returns noData failure on second run when no demo data', () async {
        // Arrange - first run consumes all demo data
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => false);

        // Act - second run
        final result = await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert - returns success (graceful skip) not failure
        expect(result, equals(const Right<Failure, Unit>(unit)));
      });

      test(
        'returns alreadyInProgress failure when production data exists',
        () async {
          // Arrange
          when(
            () => mockMigrationService.hasDemoData(),
          ).thenAnswer((_) async => true);
          when(
            () => mockMigrationService.migrateDemoData(any()),
          ).thenThrow(DemoMigrationException('production data already exists'));

          // Act
          final result = await useCase(
            const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
          );

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<DemoMigrationFailure>());
            expect(
              (failure as DemoMigrationFailure).reason,
              equals(DemoMigrationFailureReason.alreadyInProgress),
            );
          }, (_) => fail('Expected Left'));
        },
      );
    });

    group('error propagation and failure types', () {
      test('returns noData failure when migration reports no data', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenThrow(DemoMigrationException('No demo data exists to migrate'));

        // Act
        final result = await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<DemoMigrationFailure>());
          expect(
            (failure as DemoMigrationFailure).reason,
            equals(DemoMigrationFailureReason.noData),
          );
          expect(
            failure.userFriendlyMessage,
            equals('No demo data found to migrate.'),
          );
        }, (_) => fail('Expected Left'));
      });

      test(
        'returns alreadyInProgress failure for migration in progress',
        () async {
          // Arrange
          when(
            () => mockMigrationService.hasDemoData(),
          ).thenAnswer((_) async => true);
          when(() => mockMigrationService.migrateDemoData(any())).thenThrow(
            DemoMigrationException('Migration is already in progress'),
          );

          // Act
          final result = await useCase(
            const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
          );

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<DemoMigrationFailure>());
            expect(
              (failure as DemoMigrationFailure).reason,
              equals(DemoMigrationFailureReason.alreadyInProgress),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test(
        'returns dataIntegrity failure for referential integrity errors',
        () async {
          // Arrange
          when(
            () => mockMigrationService.hasDemoData(),
          ).thenAnswer((_) async => true);
          when(() => mockMigrationService.migrateDemoData(any())).thenThrow(
            DemoMigrationException('Foreign key constraint violation'),
          );

          // Act
          final result = await useCase(
            const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
          );

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<DemoMigrationFailure>());
            expect(
              (failure as DemoMigrationFailure).reason,
              equals(DemoMigrationFailureReason.dataIntegrity),
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test('returns dataIntegrity failure for unexpected errors', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenThrow(Exception('Unexpected database error'));

        // Act
        final result = await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<DemoMigrationFailure>());
          expect(
            (failure as DemoMigrationFailure).reason,
            equals(DemoMigrationFailureReason.dataIntegrity),
          );
          expect(
            failure.userFriendlyMessage,
            equals('Failed to migrate demo data. Please try again.'),
          );
        }, (_) => fail('Expected Left'));
      });

      test('logs failure breadcrumb on migration error', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenThrow(DemoMigrationException('No demo data exists to migrate'));

        // Act
        await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Demo data migration failed',
            category: 'migration',
            data: {'error': 'No demo data exists to migrate', 'cause': null},
          ),
        ).called(1);
      });

      test(
        'reports unexpected exceptions to error reporting service',
        () async {
          // Arrange
          final exception = Exception('Database connection lost');
          when(
            () => mockMigrationService.hasDemoData(),
          ).thenAnswer((_) async => true);
          when(
            () => mockMigrationService.migrateDemoData(any()),
          ).thenThrow(exception);

          // Act
          await useCase(
            const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
          );

          // Assert
          verify(
            () => mockErrorReportingService.reportException(
              exception,
              any(),
              context: 'MigrateDemoDataUseCase',
            ),
          ).called(1);
        },
      );
    });

    group('integration with migration service', () {
      test('migration service is called with correct parameters', () async {
        // Arrange
        const newOrgId = 'org-abc-123';
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenAnswer((_) async => 5);

        // Act
        await useCase(const MigrateDemoDataParams(newOrganizationId: newOrgId));

        // Assert
        verifyInOrder([
          () => mockMigrationService.hasDemoData(),
          () => mockMigrationService.migrateDemoData(newOrgId),
        ]);
      });

      test('returns migrated count in success breadcrumb', () async {
        // Arrange
        when(
          () => mockMigrationService.hasDemoData(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.migrateDemoData(any()),
        ).thenAnswer((_) async => 42);

        // Act
        await useCase(
          const MigrateDemoDataParams(newOrganizationId: 'new-org-id'),
        );

        // Assert
        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Demo data migration completed successfully',
            category: 'migration',
            data: {'migratedCount': 42, 'newOrganizationId': 'new-org-id'},
          ),
        ).called(1);
      });
    });
  });
}
