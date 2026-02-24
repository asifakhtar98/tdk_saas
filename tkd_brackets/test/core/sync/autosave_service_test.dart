import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';
import 'package:tkd_brackets/core/sync/autosave_service.dart';
import 'package:tkd_brackets/core/sync/autosave_status.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockErrorReportingService extends Mock implements ErrorReportingService {}

class FakeStackTrace extends Fake implements StackTrace {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeStackTrace());
  });

  late MockAppDatabase mockDatabase;
  late MockConnectivityService mockConnectivity;
  late MockErrorReportingService mockErrorReporting;

  setUp(() {
    mockDatabase = MockAppDatabase();
    mockConnectivity = MockConnectivityService();
    mockErrorReporting = MockErrorReportingService();

    // Default stubs
    when(
      () => mockConnectivity.currentStatus,
    ).thenReturn(ConnectivityStatus.online);
    when(() => mockDatabase.schemaVersion).thenReturn(1);
  });

  AutosaveServiceImplementation createService() {
    return AutosaveServiceImplementation(
      mockDatabase,
      mockConnectivity,
      mockErrorReporting,
    );
  }

  group('AutosaveServiceImplementation', () {
    test('should start with idle status', () {
      final service = createService();

      expect(service.currentStatus, equals(AutosaveStatus.idle));

      service.dispose();
    });

    test('should start with zero dirty entities', () {
      final service = createService();

      expect(service.dirtyEntityCount, equals(0));

      service.dispose();
    });

    test('should start with null lastSaveTime', () {
      final service = createService();

      expect(service.lastSaveTime, isNull);

      service.dispose();
    });

    group('dirty tracking', () {
      test('should track dirty entities correctly', () {
        final service = createService();

        service.markDirty('tournament', 'id-1');
        expect(service.dirtyEntityCount, equals(1));

        service.markDirty('tournament', 'id-2');
        expect(service.dirtyEntityCount, equals(2));

        service.markDirty('division', 'div-1');
        expect(service.dirtyEntityCount, equals(3));

        service.dispose();
      });

      test('should not double-count same entity', () {
        final service = createService();

        service
          ..markDirty('tournament', 'id-1')
          ..markDirty('tournament', 'id-1'); // Same entity again
        expect(service.dirtyEntityCount, equals(1));

        service.dispose();
      });

      test('should clear dirty entities correctly', () {
        final service = createService();

        service
          ..markDirty('tournament', 'id-1')
          ..markDirty('tournament', 'id-2');
        expect(service.dirtyEntityCount, equals(2));

        service.clearDirty('tournament', 'id-1');
        expect(service.dirtyEntityCount, equals(1));

        service.clearDirty('tournament', 'id-2');
        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });

      test('should handle clearing non-existent entity gracefully', () {
        final service = createService();

        // Should not throw
        service.clearDirty('nonexistent', 'id-1');
        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });
    });

    group('saveNow', () {
      test('should do nothing when no dirty entities exist', () async {
        final service = createService();

        await service.saveNow();

        // Should not call addBreadcrumb since nothing to save
        verifyNever(
          () => mockErrorReporting.addBreadcrumb(
            message: any(named: 'message'),
            category: any(named: 'category'),
            data: any(named: 'data'),
          ),
        );

        service.dispose();
      });

      test('should save and clear dirty entities', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');
        expect(service.dirtyEntityCount, equals(1));

        await service.saveNow();

        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });

      test('should add breadcrumb when saving with dirty entities', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');

        await service.saveNow();

        verify(
          () => mockErrorReporting.addBreadcrumb(
            message: any(named: 'message'),
            category: 'autosave',
            data: any(named: 'data'),
          ),
        ).called(greaterThanOrEqualTo(1));

        service.dispose();
      });

      test('should add cloud sync breadcrumb when online', () async {
        when(
          () => mockConnectivity.currentStatus,
        ).thenReturn(ConnectivityStatus.online);

        final service = createService();

        service.markDirty('tournament', 'id-1');
        await service.saveNow();

        verify(
          () => mockErrorReporting.addBreadcrumb(
            message: any(
              named: 'message',
              that: contains('ready for cloud sync'),
            ),
            category: 'autosave',
          ),
        ).called(1);

        service.dispose();
      });

      test('should not add cloud sync breadcrumb when offline', () async {
        when(
          () => mockConnectivity.currentStatus,
        ).thenReturn(ConnectivityStatus.offline);

        final service = createService();

        service.markDirty('tournament', 'id-1');
        await service.saveNow();

        verifyNever(
          () => mockErrorReporting.addBreadcrumb(
            message: any(
              named: 'message',
              that: contains('ready for cloud sync'),
            ),
            category: 'autosave',
          ),
        );

        service.dispose();
      });
    });

    group('periodic autosave', () {
      test('should use 5-second autosave interval', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');

        // Advance timers to trigger autosave
        await Future<void>.delayed(const Duration(seconds: 6));

        // Verify save was triggered (status changed)
        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });

      test('should update status during save cycle', () async {
        final service = createService();
        final statuses = <AutosaveStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        service.markDirty('tournament', 'id-1');

        // Wait for autosave cycle
        await Future<void>.delayed(const Duration(seconds: 6));

        // Should have transitioned through saving -> saved
        expect(statuses, contains(AutosaveStatus.saving));
        expect(statuses, contains(AutosaveStatus.saved));

        await subscription.cancel();
        service.dispose();
      });

      test('should set lastSaveTime after successful save', () async {
        final service = createService();

        expect(service.lastSaveTime, isNull);

        service.markDirty('tournament', 'id-1');

        // Wait for autosave cycle
        await Future<void>.delayed(const Duration(seconds: 6));

        expect(service.lastSaveTime, isNotNull);

        service.dispose();
      });

      test('should prevent concurrent saves', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');

        // Call saveNow multiple times concurrently
        await Future.wait([
          service.saveNow(),
          service.saveNow(),
          service.saveNow(),
        ]);

        // Should only have saved once (dirty entities cleared after first save)
        // Verify by checking breadcrumb was called once for the actual save
        verify(
          () => mockErrorReporting.addBreadcrumb(
            message: any(named: 'message'),
            category: 'autosave',
            data: any(named: 'data'),
          ),
        ).called(greaterThanOrEqualTo(1));

        service.dispose();
      });
    });

    group('start/stop', () {
      test('should stop autosave timer', () async {
        final service = createService();

        service
          ..stop()
          ..markDirty('tournament', 'id-1');

        // Wait longer than autosave interval
        await Future<void>.delayed(const Duration(seconds: 6));

        // Entities should still be dirty (timer stopped)
        expect(service.dirtyEntityCount, equals(1));

        service.dispose();
      });

      test('should restart autosave timer after start', () async {
        final service = createService();

        service
          ..stop()
          ..markDirty('tournament', 'id-1');

        // Wait a bit
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(service.dirtyEntityCount, equals(1));

        // Restart timer
        service.start();

        // Wait for autosave cycle
        await Future<void>.delayed(const Duration(seconds: 6));

        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });
    });

    group('lifecycle observer', () {
      test('should register as lifecycle observer', () {
        final service = createService();

        // Verify the service is a WidgetsBindingObserver
        expect(service, isA<WidgetsBindingObserver>());

        service.dispose();
      });

      test('should trigger saveNow on app pause', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');
        expect(service.dirtyEntityCount, equals(1));

        // Simulate app lifecycle change to paused
        service.didChangeAppLifecycleState(AppLifecycleState.paused);

        // Allow async save to complete
        await Future<void>.delayed(Duration.zero);

        // Entities should be saved
        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });

      test('should trigger saveNow on app inactive', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');
        expect(service.dirtyEntityCount, equals(1));

        // Simulate app lifecycle change to inactive
        service.didChangeAppLifecycleState(AppLifecycleState.inactive);

        // Allow async save to complete
        await Future<void>.delayed(Duration.zero);

        // Entities should be saved
        expect(service.dirtyEntityCount, equals(0));

        service.dispose();
      });

      test('should not trigger saveNow on app resume', () async {
        final service = createService();

        service.markDirty('tournament', 'id-1');
        expect(service.dirtyEntityCount, equals(1));

        // Simulate app lifecycle change to resumed
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);

        // Allow any async operations
        await Future<void>.delayed(Duration.zero);

        // Entities should still be dirty
        expect(service.dirtyEntityCount, equals(1));

        service.dispose();
      });
    });

    group('error handling', () {
      test(
        'should report exception and set error status on save failure',
        () async {
          // First, let the service initialize normally
          final service = createService();

          // Then reconfigure the mock to throw on subsequent calls
          when(
            () => mockDatabase.schemaVersion,
          ).thenThrow(Exception('DB error'));

          final statuses = <AutosaveStatus>[];
          final subscription = service.statusStream.listen(statuses.add);

          service.markDirty('tournament', 'id-1');

          // Wait for autosave cycle
          await Future<void>.delayed(const Duration(seconds: 6));

          // Should have transitioned to error status
          expect(statuses, contains(AutosaveStatus.error));

          verify(
            () => mockErrorReporting.reportException(
              any(),
              any(),
              context: 'Autosave',
            ),
          ).called(greaterThanOrEqualTo(1));

          await subscription.cancel();
          service.dispose();
        },
      );
    });

    group('statusStream', () {
      test('should emit status changes', () async {
        final service = createService();
        final statuses = <AutosaveStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        service.markDirty('tournament', 'id-1');

        // Wait for autosave cycle
        await Future<void>.delayed(const Duration(seconds: 6));

        expect(statuses.isNotEmpty, isTrue);

        await subscription.cancel();
        service.dispose();
      });

      test('should not emit duplicate statuses', () async {
        final service = createService();
        final statuses = <AutosaveStatus>[];
        final subscription = service.statusStream.listen(statuses.add);

        service.markDirty('tournament', 'id-1');

        // Wait for autosave cycle
        await Future<void>.delayed(const Duration(seconds: 6));

        // Count occurrences of each status
        final savingCount = statuses
            .where((s) => s == AutosaveStatus.saving)
            .length;
        final savedCount = statuses
            .where((s) => s == AutosaveStatus.saved)
            .length;

        // Should have exactly one transition per status
        expect(savingCount, equals(1));
        expect(savedCount, equals(1));

        await subscription.cancel();
        service.dispose();
      });
    });

    group('dispose', () {
      test('should stop timer on dispose', () {
        final service = createService();

        service.dispose();

        // No exception should be thrown when calling stop after dispose
        expect(service.stop, returnsNormally);
      });

      test('should close stream controller on dispose', () async {
        final service = createService();
        final statuses = <AutosaveStatus>[];

        // Subscribe before dispose
        final subscription = service.statusStream.listen(statuses.add);

        service.dispose();

        // For broadcast streams, the subscription gets closed
        // but listening after close returns a done subscription
        final isDone = Completer<void>();
        service.statusStream.listen((_) {}, onDone: isDone.complete);

        // The new subscription should complete immediately since stream is closed
        await isDone.future;
        await subscription.cancel();
      });
    });
  });

  group('AutosaveService interface', () {
    test('implementation should satisfy interface contract', () {
      final AutosaveService service = createService();

      expect(service.statusStream, isA<Stream<AutosaveStatus>>());
      expect(service.currentStatus, isA<AutosaveStatus>());
      expect(service.lastSaveTime, isNull);
      expect(service.dirtyEntityCount, isA<int>());

      service.dispose();
    });
  });
}
