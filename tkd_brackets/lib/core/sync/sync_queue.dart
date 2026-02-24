import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:tkd_brackets/core/database/app_database.dart';

/// Abstract interface for managing the sync queue.
///
/// The sync queue stores pending operations (insert, update, delete) that
/// need to be synced to Supabase when connectivity is available.
abstract class SyncQueue {
  /// Adds an item to the sync queue.
  ///
  /// Automatically deduplicates by tableName + recordId.
  /// If an entry already exists for the same record, updates the operation.
  ///
  /// [tableName] The database table name (e.g., 'organizations')
  /// [recordId] The UUID of the record
  /// [operation] The operation type: 'insert', 'update', or 'delete'
  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
  });

  /// Checks if a record already has a pending sync operation.
  ///
  /// Returns `true` if an unsynced entry exists for the given record.
  Future<bool> hasPendingForRecord(String tableName, String recordId);

  /// Gets all pending (non-synced) items ordered by creation time.
  ///
  /// Returns entries where `isSynced` is `false`, ordered oldest first.
  Future<List<SyncQueueEntry>> getPending();

  /// Marks an item as successfully synced.
  ///
  /// Sets `isSynced` to `true` for the given entry ID.
  Future<void> markSynced(int id);

  /// Marks an item as failed, incrementing the attempt count.
  ///
  /// Updates `attemptCount`, `attemptedAtTimestamp`, and `lastErrorMessage`.
  Future<void> markFailed(int id, String errorMessage);

  /// Removes all synced items from the queue.
  ///
  /// Call this periodically to clean up successfully synced entries.
  Future<void> clearSynced();

  /// Returns the count of pending (unsynced) items.
  Future<int> get pendingCount;
}

/// Implementation of [SyncQueue] using Drift database operations.
///
/// Provides deduplication to prevent duplicate sync operations for
/// the same record. When a record is enqueued multiple times,
/// the operation is updated rather than creating duplicate entries.
@LazySingleton(as: SyncQueue)
class SyncQueueImplementation implements SyncQueue {
  SyncQueueImplementation(this._db);

  final AppDatabase _db;

  @override
  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
  }) async {
    // Check for existing pending entry for this record
    final existing =
        await (_db.select(_db.syncQueueTable)..where(
              (t) =>
                  t.tableName_.equals(tableName) &
                  t.recordId.equals(recordId) &
                  t.isSynced.equals(false),
            ))
            .getSingleOrNull();

    if (existing != null) {
      // Update existing entry's operation and timestamp
      await (_db.update(
        _db.syncQueueTable,
      )..where((t) => t.id.equals(existing.id))).write(
        SyncQueueTableCompanion(
          operation: Value(operation),
          createdAtTimestamp: Value(DateTime.now().toIso8601String()),
          // Reset attempt count since this is a new change
          attemptCount: const Value(0),
          lastErrorMessage: const Value(null),
          attemptedAtTimestamp: const Value(null),
        ),
      );
    } else {
      // Insert new entry with minimal payload
      // (actual data is fetched from local DB on push)
      await _db
          .into(_db.syncQueueTable)
          .insert(
            SyncQueueTableCompanion.insert(
              tableName_: tableName,
              recordId: recordId,
              operation: operation,
              payloadJson: '{}',
              createdAtTimestamp: DateTime.now().toIso8601String(),
            ),
          );
    }
  }

  @override
  Future<bool> hasPendingForRecord(String tableName, String recordId) async {
    final result =
        await (_db.select(_db.syncQueueTable)
              ..where(
                (t) =>
                    t.tableName_.equals(tableName) &
                    t.recordId.equals(recordId) &
                    t.isSynced.equals(false),
              )
              ..limit(1))
            .get();
    return result.isNotEmpty;
  }

  @override
  Future<List<SyncQueueEntry>> getPending() async {
    return (_db.select(_db.syncQueueTable)
          ..where((t) => t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAtTimestamp)]))
        .get();
  }

  @override
  Future<void> markSynced(int id) async {
    await (_db.update(_db.syncQueueTable)..where((t) => t.id.equals(id))).write(
      const SyncQueueTableCompanion(isSynced: Value(true)),
    );
  }

  @override
  Future<void> markFailed(int id, String errorMessage) async {
    // First get current attempt count
    final entry = await (_db.select(
      _db.syncQueueTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (entry != null) {
      await (_db.update(
        _db.syncQueueTable,
      )..where((t) => t.id.equals(id))).write(
        SyncQueueTableCompanion(
          attemptCount: Value(entry.attemptCount + 1),
          attemptedAtTimestamp: Value(DateTime.now().toIso8601String()),
          lastErrorMessage: Value(errorMessage),
        ),
      );
    }
  }

  @override
  Future<void> clearSynced() async {
    await (_db.delete(
      _db.syncQueueTable,
    )..where((t) => t.isSynced.equals(true))).go();
  }

  @override
  Future<int> get pendingCount async {
    final result = await (_db.select(
      _db.syncQueueTable,
    )..where((t) => t.isSynced.equals(false))).get();
    return result.length;
  }
}
