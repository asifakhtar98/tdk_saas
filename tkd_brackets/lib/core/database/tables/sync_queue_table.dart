import 'package:drift/drift.dart';

/// Table for tracking pending sync operations.
///
/// This is a LOCAL-ONLY table used to queue changes that need to be
/// synced to Supabase. It is NOT synced to the remote database.
///
/// Each entry represents a single operation (insert/update/delete)
/// that needs to be pushed to the server when connectivity is available.
@DataClassName('SyncQueueEntry')
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';

  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Name of the table containing the record (e.g., 'organizations', 'users').
  TextColumn get tableName_ => text().named('table_name')();

  /// UUID of the record to sync.
  TextColumn get recordId => text().named('record_id')();

  /// Operation type: 'insert', 'update', or 'delete'.
  TextColumn get operation => text()();

  /// JSON payload of the record data (for insert/update).
  /// For deletes, this may be empty or contain minimal identifiers.
  TextColumn get payloadJson => text().named('payload_json')();

  /// When this entry was created (ISO 8601 string).
  TextColumn get createdAtTimestamp => text().named('created_at_timestamp')();

  /// When sync was last attempted (ISO 8601 string, nullable).
  TextColumn get attemptedAtTimestamp =>
      text().nullable().named('attempted_at_timestamp')();

  /// Number of sync attempts made.
  IntColumn get attemptCount =>
      integer().named('attempt_count').withDefault(const Constant(0))();

  /// Error message from last failed attempt (nullable).
  TextColumn get lastErrorMessage =>
      text().nullable().named('last_error_message')();

  /// Whether this entry has been successfully synced.
  BoolColumn get isSynced =>
      boolean().named('is_synced').withDefault(const Constant(false))();

  // NOTE: Index on (is_synced, created_at_timestamp) should be created
  // via migration for production performance. Example:
  // await customStatement(
  //   'CREATE INDEX IF NOT EXISTS idx_sync_queue_pending '
  //   'ON sync_queue(is_synced, created_at_timestamp)'
  // );
}
