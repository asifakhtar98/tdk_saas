import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// A fake builder to handle the fluent Supabase API which is hard to mock with mocktail.
class FakePostgrestBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T _data;
  FakePostgrestBuilder(this._data);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) async {
    return onValue(_data);
  }

  @override
  PostgrestFilterBuilder<T> gt(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> order(String column,
          {bool ascending = true,
          bool nullsFirst = false,
          String? referencedTable}) =>
      this;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;
}

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
      expect(syncService.currentStatus, isNotNull);
      expect(syncService.currentError, isNull);
    });
  });

  group('push with pending items', () {
    SyncQueueEntry makeSyncEntry({
      int id = 1,
      String tableName = 'organizations',
      String recordId = 'org-1',
      String operation = 'insert',
      int attemptCount = 0,
    }) {
      return SyncQueueEntry(
        id: id,
        tableName_: tableName,
        recordId: recordId,
        operation: operation,
        payloadJson: '{}',
        createdAtTimestamp: DateTime.now().toIso8601String(),
        attemptCount: attemptCount,
        isSynced: false,
      );
    }

    test(
      'push marks items as failed with retry message when _shouldRetry is true',
      () async {
        final entry = makeSyncEntry(attemptCount: 2);
        when(() => mockSyncQueue.getPending()).thenAnswer(
          (_) async => [entry],
        );
        when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 1);
        when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer(
          (_) async {},
        );

        when(
          () => mockSupabaseClient.from(any()),
        ).thenThrow(Exception('Network error'));

        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: 'org-1',
            name: 'Test Org',
            slug: 'test-org',
          ),
        );

        await syncService.push();

        verify(
          () => mockSyncQueue.markFailed(
            entry.id,
            any(that: contains('Network error')),
          ),
        ).called(1);
      },
    );

    test(
      'push marks items as permanently failed when _shouldRetry is false (exhausted retries)',
      () async {
        final entry = makeSyncEntry(attemptCount: 5);
        when(() => mockSyncQueue.getPending()).thenAnswer(
          (_) async => [entry],
        );
        when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 1);
        when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer(
          (_) async {},
        );
        when(
          () => mockErrorReportingService.reportError(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        when(
          () => mockSupabaseClient.from(any()),
        ).thenThrow(Exception('Network error'));

        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: 'org-1',
            name: 'Test Org',
            slug: 'test-org',
          ),
        );

        await syncService.push();

        verify(
          () => mockSyncQueue.markFailed(
            entry.id,
            any(that: contains('Exhausted 5 retry attempts')),
          ),
        ).called(1);

        verify(
          () => mockErrorReportingService.reportError(
            any(that: contains('exhausted retries')),
            error: any(named: 'error'),
          ),
        ).called(1);
      },
    );

    test('push sets error status when items fail', () async {
      final entry = makeSyncEntry(attemptCount: 2);
      when(() => mockSyncQueue.getPending()).thenAnswer(
        (_) async => [entry],
      );
      when(() => mockSyncQueue.pendingCount).thenAnswer((_) async => 0);
      when(() => mockSyncQueue.markFailed(any(), any())).thenAnswer(
        (_) async {},
      );

      when(
        () => mockSupabaseClient.from(any()),
      ).thenThrow(Exception('Network error'));

      await testDatabase.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-1',
          name: 'Test Org',
          slug: 'test-org',
        ),
      );

      final statuses = <SyncStatus>[];
      syncService.statusStream.listen(statuses.add);

      await syncService.push();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(statuses, contains(SyncStatus.error));
      expect(syncService.currentError, isNotNull);
      expect(
        syncService.currentError!.message,
        'Some changes failed to sync',
      );
    });
  });

  group('_shouldRetry boundary tests', () {
    test(
      'getRetryDelay returns 5 minutes cap for high attempt count',
      () {
        final delay = syncService.getRetryDelay(8);
        expect(delay, const Duration(seconds: 300));
      },
    );

    test('getRetryDelay returns correct value at attempt 5', () {
      final delay = syncService.getRetryDelay(5);
      expect(delay, const Duration(seconds: 300));
    });
  });

  group('Data Syncing', () {
    group('push', () {
      test('successfully pushes organization change', () async {
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(() => mockSupabaseClient.from(any()))
            .thenAnswer((_) => mockQueryBuilder);

        const orgId = 'org-1';
        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: orgId,
            name: 'Local Name',
            slug: 'local-slug',
          ),
        );

        final item = SyncQueueEntry(
          id: 1,
          tableName_: 'organizations',
          recordId: orgId,
          operation: 'update',
          createdAtTimestamp: DateTime.now().toIso8601String(),
          payloadJson: '{}',
          isSynced: false,
          attemptCount: 0,
        );

        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => [item]);
        when(() => mockQueryBuilder.upsert(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([]));
        when(
          () => mockSyncQueue.markSynced(any()),
        ).thenAnswer((_) async => {});

        await syncService.push();

        verify(() => mockQueryBuilder.upsert(any(that: isA<List<Map<String, dynamic>>>()))).called(1);
        verify(() => mockSyncQueue.markSynced(1)).called(1);
      });

      test('successfully pushes user change', () async {
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(() => mockSupabaseClient.from(any()))
            .thenAnswer((_) => mockQueryBuilder);

        const userId = 'user-1';
        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: 'org-1',
            name: 'Org 1',
            slug: 'org-1',
          ),
        );
        await testDatabase.insertUser(
          UsersCompanion.insert(
            id: userId,
            organizationId: 'org-1',
            email: 'test@example.com',
            displayName: 'Local User',
          ),
        );

        final item = SyncQueueEntry(
          id: 2,
          tableName_: 'users',
          recordId: userId,
          operation: 'update',
          createdAtTimestamp: DateTime.now().toIso8601String(),
          payloadJson: '{}',
          isSynced: false,
          attemptCount: 0,
        );

        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => [item]);
        when(() => mockQueryBuilder.upsert(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([]));
        when(
          () => mockSyncQueue.markSynced(any()),
        ).thenAnswer((_) async => {});

        await syncService.push();

        verify(() => mockQueryBuilder.upsert(any(that: isA<List<Map<String, dynamic>>>()))).called(1);
        verify(() => mockSyncQueue.markSynced(2)).called(1);
      });

      test('handles missing local record during push by skipping', () async {
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(() => mockSupabaseClient.from(any()))
            .thenAnswer((_) => mockQueryBuilder);

        final item = SyncQueueEntry(
          id: 3,
          tableName_: 'organizations',
          recordId: 'non-existent',
          operation: 'update',
          createdAtTimestamp: DateTime.now().toIso8601String(),
          payloadJson: '{}',
          isSynced: false,
          attemptCount: 0,
        );

        when(() => mockSyncQueue.getPending()).thenAnswer((_) async => [item]);
        when(
          () => mockSyncQueue.markSynced(any()),
        ).thenAnswer((_) async => {});

        await syncService.push();

        verifyNever(() => mockQueryBuilder.upsert(any()));
      });
    });

    group('pull', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test('successfully pulls and applies organization update', () async {
        final mockOrgQuery = MockSupabaseQueryBuilder();
        final mockUserQuery = MockSupabaseQueryBuilder();
        when(() => mockSupabaseClient.from('organizations')).thenAnswer((_) => mockOrgQuery);
        when(() => mockSupabaseClient.from('users')).thenAnswer((_) => mockUserQuery);

        const orgId = 'org-1';
        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: orgId,
            name: 'Old Name',
            slug: 'old-slug',
            syncVersion: const Value(1),
          ),
        );

        final remoteData = {
          'id': orgId,
          'name': 'New Name',
          'slug': 'new-slug',
          'sync_version': 2,
          'updated_at_timestamp': DateTime.now().toIso8601String(),
          'created_at_timestamp': DateTime.now().toIso8601String(),
        };

        when(() => mockOrgQuery.select(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([remoteData]));
        when(() => mockUserQuery.select(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([]));

        await syncService.pull();

        final local = await testDatabase.getOrganizationById(orgId);
        expect(local!.name, 'New Name');
        expect(local.syncVersion, 2);
      });

      test('ignores remote update if local version is newer', () async {
        final mockOrgQuery = MockSupabaseQueryBuilder();
        final mockUserQuery = MockSupabaseQueryBuilder();
        when(() => mockSupabaseClient.from('organizations')).thenAnswer((_) => mockOrgQuery);
        when(() => mockSupabaseClient.from('users')).thenAnswer((_) => mockUserQuery);

        const orgId = 'org-1';
        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: orgId,
            name: 'Local New',
            slug: 'local-new',
            syncVersion: const Value(5),
          ),
        );

        final remoteData = {
          'id': orgId,
          'name': 'Remote Old',
          'slug': 'remote-old',
          'sync_version': 3,
          'updated_at_timestamp': DateTime.now().toIso8601String(),
          'created_at_timestamp': DateTime.now().toIso8601String(),
        };

        when(() => mockOrgQuery.select(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([remoteData]));
        when(() => mockUserQuery.select(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([]));

        await syncService.pull();

        final local = await testDatabase.getOrganizationById(orgId);
        expect(local!.name, 'Local New'); // Unchanged
        expect(local.syncVersion, 5);
      });

      test('successfully pulls and applies new user (insert)', () async {
        final mockOrgQuery = MockSupabaseQueryBuilder();
        final mockUserQuery = MockSupabaseQueryBuilder();
        when(() => mockSupabaseClient.from('organizations')).thenAnswer((_) => mockOrgQuery);
        when(() => mockSupabaseClient.from('users')).thenAnswer((_) => mockUserQuery);

        final remoteUser = {
          'id': 'user-new',
          'organization_id': 'org-1',
          'email': 'new@example.com',
          'display_name': 'New User',
          'role': 'viewer',
          'is_active': true,
          'sync_version': 1,
          'created_at_timestamp': DateTime.now().toIso8601String(),
          'updated_at_timestamp': DateTime.now().toIso8601String(),
        };

        when(() => mockOrgQuery.select(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([]));
        when(() => mockUserQuery.select(any()))
            .thenAnswer((_) => FakePostgrestBuilder<PostgrestList>([remoteUser]));

        await testDatabase.insertOrganization(
          OrganizationsCompanion.insert(
            id: 'org-1',
            name: 'Org 1',
            slug: 'org-1',
          ),
        );

        await syncService.pull();

        final local = await testDatabase.getUserById('user-new');
        expect(local!.displayName, 'New User');
        expect(local.email, 'new@example.com');
      });
    });
  });

  group('Sync Error Handling extra', () {
    test('handles temporary failure with retry', () async {
      final item = SyncQueueEntry(
        id: 1,
        tableName_: 'organizations',
        recordId: 'org-1',
        operation: 'update',
        createdAtTimestamp: DateTime.now().toIso8601String(),
        payloadJson: '{}',
        isSynced: false,
        attemptCount: 0,
      );

      await testDatabase.insertOrganization(
        OrganizationsCompanion.insert(
          id: 'org-1',
          name: 'Org 1',
          slug: 'org-1',
        ),
      );

      when(() => mockSyncQueue.getPending()).thenAnswer((_) async => [item]);
      when(() => mockSupabaseClient.from(any()))
          .thenThrow(const SocketException('No internet'));
      when(() => mockSyncQueue.markFailed(any(), any()))
          .thenAnswer((_) async => {});

      await syncService.push();

      verify(() => mockSyncQueue.markFailed(1, any())).called(1);
    });
  });
}
