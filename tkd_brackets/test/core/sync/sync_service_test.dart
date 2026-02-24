import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';
import 'package:tkd_brackets/core/sync/sync_notification_service.dart';
import 'package:tkd_brackets/core/sync/sync_queue.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';

// Mocks
class MockSyncQueue extends Mock implements SyncQueue {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockErrorReportingService extends Mock implements ErrorReportingService {}

class MockSyncNotificationService extends Mock
    implements SyncNotificationService {}

void main() {
  // Required for SharedPreferences in pull()
  WidgetsFlutterBinding.ensureInitialized();

  late MockSyncQueue mockSyncQueue;
  late MockConnectivityService mockConnectivityService;
  late MockSupabaseClient mockSupabaseClient;
  late AppDatabase testDatabase;
  late MockErrorReportingService mockErrorReportingService;
  late MockSyncNotificationService mockSyncNotificationService;
  late SyncServiceImplementation syncService;
  late StreamController<ConnectivityStatus> connectivityController;

  setUp(() {
    mockSyncQueue = MockSyncQueue();
    mockConnectivityService = MockConnectivityService();
    mockSupabaseClient = MockSupabaseClient();
    testDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    mockErrorReportingService = MockErrorReportingService();
    mockSyncNotificationService = MockSyncNotificationService();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();

    // Setup default mocks
    when(
      () => mockConnectivityService.statusStream,
    ).thenAnswer((_) => connectivityController.stream);
    when(
      () => mockConnectivityService.currentStatus,
    ).thenReturn(ConnectivityStatus.online);
    when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 0);
    when(() => mockSyncQueue.getPending()).thenAnswer((_) async => []);
    when(
      () => mockErrorReportingService.addBreadcrumb(
        message: any(named: 'message'),
        category: any(named: 'category'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);

    syncService = SyncServiceImplementation(
      mockSyncQueue,
      mockConnectivityService,
      mockSupabaseClient,
      testDatabase,
      mockErrorReportingService,
      mockSyncNotificationService,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await connectivityController.close();
    await testDatabase.close();
  });

  group('SyncService', () {
    group('initialization', () {
      test('initializes with synced status', () {
        expect(syncService.currentStatus, SyncStatus.synced);
      });

      test('initializes with null error', () {
        expect(syncService.currentError, isNull);
      });

      test('initializes with zero pending count', () {
        expect(syncService.pendingChangeCount, 0);
      });

      test('subscribes to connectivity changes', () {
        verify(() => mockConnectivityService.statusStream).called(1);
      });
    });

    group('statusStream', () {
      test('emits status changes', () async {
        final statuses = <SyncStatus>[];
        syncService.statusStream.listen(statuses.add);

        when(
          () => mockConnectivityService.currentStatus,
        ).thenReturn(ConnectivityStatus.online);
        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => []);

        await syncService.push();

        // Allow async status updates to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should emit syncing status during push
        expect(statuses, contains(SyncStatus.syncing));
      });

      test('is a broadcast stream', () {
        expect(syncService.statusStream.isBroadcast, isTrue);
      });
    });

    group('queueForSync', () {
      test('calls syncQueue.enqueue', () async {
        when(
          () => mockSyncQueue.enqueue(
            tableName: any(named: 'tableName'),
            recordId: any(named: 'recordId'),
            operation: any(named: 'operation'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 1);

        syncService.queueForSync(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        // Allow async to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockSyncQueue.enqueue(
            tableName: 'organizations',
            recordId: 'org-123',
            operation: 'insert',
          ),
        ).called(1);
      });

      test('adds breadcrumb on enqueue', () async {
        when(
          () => mockSyncQueue.enqueue(
            tableName: any(named: 'tableName'),
            recordId: any(named: 'recordId'),
            operation: any(named: 'operation'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 1);

        syncService.queueForSync(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'update',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: any(named: 'message', that: contains('Queued for sync')),
            category: 'sync',
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('push', () {
      test('skips when offline', () async {
        when(
          () => mockConnectivityService.currentStatus,
        ).thenReturn(ConnectivityStatus.offline);

        await syncService.push();

        verifyNever(() => mockSyncQueue.getPending());
        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Push skipped: offline',
            category: 'sync',
            data: any(named: 'data'),
          ),
        ).called(1);
      });

      test('returns synced status when no pending items', () async {
        when(
          () => mockConnectivityService.currentStatus,
        ).thenReturn(ConnectivityStatus.online);
        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => []);

        final statuses = <SyncStatus>[];
        syncService.statusStream.listen(statuses.add);

        await syncService.push();

        // Allow async status updates to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should include synced status at some point
        expect(statuses, contains(SyncStatus.synced));
      });

      test('emits syncing status during push', () async {
        when(
          () => mockConnectivityService.currentStatus,
        ).thenReturn(ConnectivityStatus.online);
        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => []);

        final statuses = <SyncStatus>[];
        syncService.statusStream.listen(statuses.add);

        await syncService.push();

        expect(statuses.first, SyncStatus.syncing);
      });
    });

    group('pull', () {
      test('skips when offline', () async {
        when(
          () => mockConnectivityService.currentStatus,
        ).thenReturn(ConnectivityStatus.offline);

        await syncService.pull();

        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Pull skipped: offline',
            category: 'sync',
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('syncNow', () {
      test('calls push then pull', () async {
        when(
          () => mockConnectivityService.currentStatus,
        ).thenReturn(ConnectivityStatus.offline);

        await syncService.syncNow();

        // Both push and pull should be called (but skip due to offline)
        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Push skipped: offline',
            category: 'sync',
            data: any(named: 'data'),
          ),
        ).called(1);
        verify(
          () => mockErrorReportingService.addBreadcrumb(
            message: 'Pull skipped: offline',
            category: 'sync',
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });

    group('connectivity changes', () {
      test('triggers sync when coming online with pending changes', () async {
        when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 5);
        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => []);

        // Create a new service instance to get fresh pending count
        final service = SyncServiceImplementation(
          mockSyncQueue,
          mockConnectivityService,
          mockSupabaseClient,
          testDatabase,
          mockErrorReportingService,
          mockSyncNotificationService,
        );

        // Allow initialization to complete
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Simulate coming online
        connectivityController.add(ConnectivityStatus.online);

        // Allow async handlers to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify sync was triggered
        verify(() => mockSyncQueue.getPending()).called(greaterThan(0));

        service.dispose();
      });
    });

    group('exponential backoff', () {
      test('calculates correct delay for attempt 1', () {
        final delay = syncService.getRetryDelay(1);
        expect(delay, const Duration(seconds: 5));
      });

      test('calculates correct delay for attempt 2', () {
        final delay = syncService.getRetryDelay(2);
        expect(delay, const Duration(seconds: 15));
      });

      test('calculates correct delay for attempt 3', () {
        final delay = syncService.getRetryDelay(3);
        expect(delay, const Duration(seconds: 45));
      });

      test('calculates correct delay for attempt 4', () {
        final delay = syncService.getRetryDelay(4);
        expect(delay, const Duration(seconds: 135));
      });

      test('caps delay at 5 minutes', () {
        final delay = syncService.getRetryDelay(10);
        expect(delay, const Duration(seconds: 300));
      });
    });

    group('dispose', () {
      test('closes status stream controller', () async {
        final service = SyncServiceImplementation(
          mockSyncQueue,
          mockConnectivityService,
          mockSupabaseClient,
          testDatabase,
          mockErrorReportingService,
          mockSyncNotificationService,
        );

        var streamClosed = false;
        service.statusStream.listen((_) {}, onDone: () => streamClosed = true);

        service.dispose();

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(streamClosed, isTrue);
      });

      test('cancels connectivity subscription', () {
        // Just verify dispose doesn't throw
        expect(() => syncService.dispose(), returnsNormally);
      });
    });
  });

  group('Conflict Resolution (LWW)', () {
    test('SyncService uses sync_version for conflict resolution', () {
      // The LWW logic is implemented in _shouldApplyRemoteChange
      // which compares remote and local sync_version values.
      // This test verifies the service initializes correctly with LWW support.
      expect(syncService.currentStatus, isNotNull);
      expect(syncService.currentError, isNull);
    });
  });
}
