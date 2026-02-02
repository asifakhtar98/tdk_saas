import 'package:drift/drift.dart';

/// Mixin providing soft delete and sync-related columns.
///
/// All tables that need to sync with Supabase should include this mixin.
/// The sync_version is incremented on every update for LWW conflict resolution.
mixin BaseSyncMixin on Table {
  /// For Last-Write-Wins sync conflict resolution.
  /// Increment on every local update.
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  /// Soft delete flag. Never physically delete synced data.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// When the record was soft deleted. Null if not deleted.
  DateTimeColumn get deletedAtTimestamp => dateTime().nullable()();

  /// True for demo mode data that needs special handling on signup.
  BoolColumn get isDemoData => boolean().withDefault(const Constant(false))();
}

/// Mixin providing audit timestamp columns.
///
/// All tables should include this mixin for tracking record lifecycle.
mixin BaseAuditMixin on Table {
  /// When the record was created. Set once on insert.
  DateTimeColumn get createdAtTimestamp =>
      dateTime().withDefault(currentDateAndTime)();

  /// When the record was last updated. Updated on every modification.
  DateTimeColumn get updatedAtTimestamp =>
      dateTime().withDefault(currentDateAndTime)();
}
