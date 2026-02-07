import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/sync/sync_queue.dart';

void main() {
  late AppDatabase database;
  late SyncQueueImplementation syncQueue;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncQueue = SyncQueueImplementation(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncQueue', () {
    group('enqueue', () {
      test('adds item to sync queue', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        expect(pending.length, 1);
        expect(pending.first.tableName_, 'organizations');
        expect(pending.first.recordId, 'org-123');
        expect(pending.first.operation, 'insert');
        expect(pending.first.isSynced, false);
      });

      test('deduplicates by table_name + record_id', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'update',
        );

        final pending = await syncQueue.getPending();
        expect(pending.length, 1);
        expect(pending.first.operation, 'update');
      });

      test('allows different records for same table', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-2',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        expect(pending.length, 2);
      });

      test('allows same record for different tables', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'id-123',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'users',
          recordId: 'id-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        expect(pending.length, 2);
      });

      test('resets attempt count when updating existing entry', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        // Simulate failure
        final pending = await syncQueue.getPending();
        await syncQueue.markFailed(pending.first.id, 'Test error');

        // Enqueue again
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'update',
        );

        final updated = await syncQueue.getPending();
        expect(updated.first.attemptCount, 0);
        expect(updated.first.lastErrorMessage, isNull);
      });
    });

    group('hasPendingForRecord', () {
      test('returns true when pending entry exists', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final hasPending = await syncQueue.hasPendingForRecord(
          'organizations',
          'org-123',
        );
        expect(hasPending, true);
      });

      test('returns false when no pending entry exists', () async {
        final hasPending = await syncQueue.hasPendingForRecord(
          'organizations',
          'non-existent',
        );
        expect(hasPending, false);
      });

      test('returns false for synced entries', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        await syncQueue.markSynced(pending.first.id);

        final hasPending = await syncQueue.hasPendingForRecord(
          'organizations',
          'org-123',
        );
        expect(hasPending, false);
      });
    });

    group('getPending', () {
      test('returns entries ordered by created_at', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await syncQueue.enqueue(
          tableName: 'users',
          recordId: 'user-1',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        expect(pending.length, 2);
        expect(pending.first.tableName_, 'organizations');
        expect(pending.last.tableName_, 'users');
      });

      test('excludes synced entries', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-2',
          operation: 'insert',
        );

        final initial = await syncQueue.getPending();
        await syncQueue.markSynced(initial.first.id);

        final remaining = await syncQueue.getPending();
        expect(remaining.length, 1);
        expect(remaining.first.recordId, 'org-2');
      });
    });

    group('markSynced', () {
      test('sets isSynced to true', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        await syncQueue.markSynced(pending.first.id);

        final count = await syncQueue.pendingCount;
        expect(count, 0);
      });
    });

    group('markFailed', () {
      test('increments attempt count', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        expect(pending.first.attemptCount, 0);

        await syncQueue.markFailed(pending.first.id, 'Connection error');

        final updated = await syncQueue.getPending();
        expect(updated.first.attemptCount, 1);
      });

      test('sets error message', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        await syncQueue.markFailed(pending.first.id, 'Test error message');

        final updated = await syncQueue.getPending();
        expect(updated.first.lastErrorMessage, 'Test error message');
      });

      test('sets attempted timestamp', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-123',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        expect(pending.first.attemptedAtTimestamp, isNull);

        await syncQueue.markFailed(pending.first.id, 'Error');

        final updated = await syncQueue.getPending();
        expect(updated.first.attemptedAtTimestamp, isNotNull);
      });
    });

    group('clearSynced', () {
      test('removes synced entries', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-2',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        await syncQueue.markSynced(pending.first.id);

        await syncQueue.clearSynced();

        // Verify only pending item remains
        final remaining = await syncQueue.getPending();
        expect(remaining.length, 1);
        expect(remaining.first.recordId, 'org-2');
      });

      test('does not remove pending entries', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );

        await syncQueue.clearSynced();

        final count = await syncQueue.pendingCount;
        expect(count, 1);
      });
    });

    group('pendingCount', () {
      test('returns zero when empty', () async {
        final count = await syncQueue.pendingCount;
        expect(count, 0);
      });

      test('returns correct count', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'users',
          recordId: 'user-1',
          operation: 'insert',
        );

        final count = await syncQueue.pendingCount;
        expect(count, 2);
      });

      test('excludes synced items from count', () async {
        await syncQueue.enqueue(
          tableName: 'organizations',
          recordId: 'org-1',
          operation: 'insert',
        );
        await syncQueue.enqueue(
          tableName: 'users',
          recordId: 'user-1',
          operation: 'insert',
        );

        final pending = await syncQueue.getPending();
        await syncQueue.markSynced(pending.first.id);

        final count = await syncQueue.pendingCount;
        expect(count, 1);
      });
    });
  });
}
