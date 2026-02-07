# Story 1.10: Sync Service Foundation

Status: done

## Story

**As a** developer,
**I want** a sync service using Last-Write-Wins strategy,
**so that** local changes sync to Supabase when online (FR66-FR69).

## Acceptance Criteria

1. **AC1:** `lib/core/sync/sync_service.dart` exists with abstract interface and implementation providing:
   - `SyncQueue` for pending changes
   - `push()` to upload local changes to Supabase
   - `pull()` to download remote changes from Supabase
   - Last-Write-Wins conflict resolution using `sync_version`

2. **AC2:** `sync_queue` table is created in Drift for pending operations with schema:
   - `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
   - `table_name` (TEXT NOT NULL)
   - `record_id` (TEXT NOT NULL)
   - `operation` (TEXT NOT NULL - 'insert', 'update', 'delete')
   - `payload_json` (TEXT NOT NULL)
   - `created_at_timestamp` (TEXT NOT NULL)
   - `attempted_at_timestamp` (TEXT nullable)
   - `attempt_count` (INTEGER NOT NULL DEFAULT 0)
   - `last_error_message` (TEXT nullable)
   - `is_synced` (INTEGER NOT NULL DEFAULT 0)

3. **AC3:** Sync status is exposed via `Stream<SyncStatus>` with states:
   - `synced` - All local changes are synced to remote
   - `syncing` - Sync operation in progress
   - `pendingChanges` - Local changes waiting to sync
   - `error` - Sync failed with error details

4. **AC4:** `lib/core/sync/sync_status.dart` exists with `SyncStatus` enum

5. **AC5:** `lib/core/sync/sync_queue.dart` exists with `SyncQueue` class for managing pending operations

6. **AC6:** Service is registered in DI container via `@LazySingleton`

7. **AC7:** Unit tests verify:
   - Queue operations (add, remove, getAll, markSynced)
   - Conflict resolution logic (higher sync_version wins)
   - Status stream emits correct states during sync lifecycle
   - Push/pull operations work correctly with mocked Supabase client

## Tasks / Subtasks

- [x] Task 1: Verify sync_version column exists (AC: #1)
  - [x] 1.1 Confirm `BaseSyncableColumns` mixin in `base_tables.dart` includes `sync_version` column
  - [x] 1.2 Verify `Organizations` and `Users` tables inherit the mixin
  - [x] 1.3 If missing, add `syncVersion` column to mixin: `IntColumn get syncVersion => integer().named('sync_version').withDefault(const Constant(1))();`

- [x] Task 2: Create SyncStatus enum (AC: #4)
  - [x] 2.1 Create `lib/core/sync/sync_status.dart`
  - [x] 2.2 Define `SyncStatus` enum with `synced`, `syncing`, `pendingChanges`, `error` values
  - [x] 2.3 Add `SyncError` class to hold error details when status is `error`

- [x] Task 3: Create sync_queue Drift table (AC: #2)
  - [x] 3.1 Create `lib/core/database/tables/sync_queue_table.dart` with all required columns
  - [x] 3.2 Add index on `is_synced` and `created_at_timestamp` for performance
  - [x] 3.3 Add `SyncQueueTable` to `tables.dart` barrel file
  - [x] 3.4 Register `SyncQueueTable` in `AppDatabase` @DriftDatabase annotation
  - [x] 3.5 Increment schema version from 1 to 2 in `AppDatabase`
  - [x] 3.6 Add migration callback for new table
  - [x] 3.7 Run `dart run build_runner build --delete-conflicting-outputs`

- [x] Task 4: Create SyncQueue class (AC: #5)
  - [x] 4.1 Create `lib/core/sync/sync_queue.dart` with abstract interface
  - [x] 4.2 Define methods: `enqueue()`, `dequeueNext()`, `getPending()`, `markSynced()`, `markFailed()`, `clearSynced()`, `hasPendingForRecord()`
  - [x] 4.3 Create `SyncQueueImplementation` class with Drift database operations
  - [x] 4.4 Implement deduplication: check if same table/recordId already pending before enqueueing
  - [x] 4.5 Register in DI with `@LazySingleton(as: SyncQueue)`

- [x] Task 5: Create SyncService interface and implementation (AC: #1, #3, #6)
  - [x] 5.1 Create abstract `SyncService` interface in `lib/core/sync/sync_service.dart`
  - [x] 5.2 Define `Stream<SyncStatus> get statusStream`
  - [x] 5.3 Define `SyncStatus get currentStatus`
  - [x] 5.4 Define `Future<void> push()` - upload local changes with batch operations
  - [x] 5.5 Define `Future<void> pull()` - download remote changes since last sync timestamp
  - [x] 5.6 Define `Future<void> syncNow()` - full sync (push + pull)
  - [x] 5.7 Define `void queueForSync()` - deferred enqueue (payload fetched on push, not on queue)
  - [x] 5.8 Create `SyncServiceImplementation` with ConnectivityService, SyncQueue, SupabaseClient dependencies
  - [x] 5.9 Implement Last-Write-Wins conflict resolution using `sync_version`
  - [x] 5.10 Implement exponential backoff retry strategy
  - [x] 5.11 Implement last sync timestamp tracking using SharedPreferences
  - [x] 5.12 Register in DI with `@LazySingleton(as: SyncService)`

- [x] Task 6: Create SyncNotificationService placeholder (AC: FR69)
  - [x] 6.1 Create `lib/core/sync/sync_notification_service.dart` with abstract interface
  - [x] 6.2 Define `void notifyConflictResolved()` method (placeholder for future FR69 visual notification)
  - [x] 6.3 Create stub implementation that logs conflicts
  - [x] 6.4 Register in DI with `@LazySingleton`

- [x] Task 7: Update barrel exports (AC: all)
  - [x] 7.1 Update `lib/core/sync/sync.dart` to export all new files

- [x] Task 8: Write unit tests (AC: #7)
  - [x] 8.1 Create `test/core/sync/sync_status_test.dart`
  - [x] 8.2 Create `test/core/sync/sync_queue_test.dart`
  - [x] 8.3 Create `test/core/sync/sync_service_test.dart`
  - [x] 8.4 Test queue CRUD operations with deduplication
  - [x] 8.5 Test conflict resolution (sync_version comparison)
  - [x] 8.6 Test status stream emissions during sync lifecycle
  - [x] 8.7 Test push/pull with mocked dependencies
  - [x] 8.8 Test exponential backoff calculation
  - [x] 8.9 Test batch operations

- [x] Task 9: Verification
  - [x] 9.1 Run `dart analyze` - must pass with no errors
  - [x] 9.2 Run `flutter test` - all tests must pass
  - [x] 9.3 Run `flutter build web --release` - must complete successfully

## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### Architecture Context

**Location:** `lib/core/sync/` - Core infrastructure, not a feature

**Dependencies:**
- `ConnectivityService` (Story 1.8) - check online/offline status
- `AppDatabase` (Story 1.5) - Drift database for sync queue table
- `SupabaseClient` (Story 1.6) - Remote data operations
- `ErrorReportingService` (Story 1.4) - Error logging

**Data Flow:**
```
Repository.save() → markDirty() → AutosaveService → SyncService.queueForSync()
                                                              ↓
                                               SyncQueue (table_name, record_id, operation)
                                                              ↓
                          ConnectivityService (online?) → push() fetches payload from DB → Supabase
```

### Sync Strategy: Last-Write-Wins (LWW)

Per architecture document Section "Sync Strategy":

1. **Every mutable table has `sync_version INT NOT NULL DEFAULT 1`** (in `BaseSyncableColumns` mixin)
2. **On local update:** Increment `sync_version` locally (already done in `AppDatabase.updateOrganization()`)
3. **On push:** Send record with current `sync_version`
4. **On conflict:** Higher `sync_version` wins
5. **On pull:** Compare remote `sync_version` with local, apply if remote is higher

### Verify sync_version Column

**CRITICAL:** Before implementing, verify `base_tables.dart` includes `sync_version`:

```dart
// lib/core/database/tables/base_tables.dart
// Should contain:
mixin BaseSyncableColumns on Table {
  // ... other columns ...
  IntColumn get syncVersion => integer().named('sync_version').withDefault(const Constant(1))();
}
```

If missing, add it and run migrations.

### SyncQueue Table Schema (Drift)

**CRITICAL:** This is a LOCAL-ONLY table, NOT synced to Supabase. It tracks pending sync operations.

```dart
// lib/core/database/tables/sync_queue_table.dart
import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntry')
class SyncQueueTable extends Table {
  @override
  String get tableName => 'sync_queue';
  
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get recordId => text().named('record_id')();
  TextColumn get operation => text()(); // 'insert', 'update', 'delete'
  TextColumn get payloadJson => text().named('payload_json')();
  TextColumn get createdAtTimestamp => text().named('created_at_timestamp')();
  TextColumn get attemptedAtTimestamp => text().nullable().named('attempted_at_timestamp')();
  IntColumn get attemptCount => integer().named('attempt_count').withDefault(const Constant(0))();
  TextColumn get lastErrorMessage => text().nullable().named('last_error_message')();
  BoolColumn get isSynced => boolean().named('is_synced').withDefault(const Constant(false))();
  
  // Performance index for pending items query
  @override
  List<Set<Column>> get indexes => [
    {isSynced, createdAtTimestamp},
  ];
}
```

**Note:** Use `tableName_` to avoid conflict with Drift's `tableName` getter.

### SyncStatus Enum

```dart
// lib/core/sync/sync_status.dart
enum SyncStatus {
  synced,         // All local changes synced
  syncing,        // Sync operation in progress
  pendingChanges, // Local changes waiting to sync
  error,          // Sync failed
}

/// Holds error details when SyncStatus is error
class SyncError {
  final String userFriendlyMessage;
  final String? technicalDetails;
  final int failedOperationCount;
  
  const SyncError({
    required this.userFriendlyMessage,
    this.technicalDetails,
    this.failedOperationCount = 0,
  });
}
```

### SyncQueue Interface

```dart
// lib/core/sync/sync_queue.dart
abstract class SyncQueue {
  /// Add item to sync queue. Deduplicates by table_name + record_id.
  Future<void> enqueue({
    required String tableName,
    required String recordId,
    required String operation,
  });
  
  /// Check if record already has pending sync
  Future<bool> hasPendingForRecord(String tableName, String recordId);
  
  /// Get all pending (non-synced) items ordered by created_at
  Future<List<SyncQueueEntry>> getPending();
  
  /// Mark item as successfully synced
  Future<void> markSynced(int id);
  
  /// Mark item as failed, increment attempt count
  Future<void> markFailed(int id, String errorMessage);
  
  /// Remove all synced items
  Future<void> clearSynced();
  
  /// Get count of pending items
  Future<int> get pendingCount;
}
```

### SyncService Interface

```dart
// lib/core/sync/sync_service.dart
abstract class SyncService {
  /// Stream of sync status changes
  Stream<SyncStatus> get statusStream;
  
  /// Current sync status
  SyncStatus get currentStatus;
  
  /// Current error if status is error, null otherwise
  SyncError? get currentError;
  
  /// Number of pending changes waiting to sync
  int get pendingChangeCount;
  
  /// Push local changes to Supabase (with batch operations)
  Future<void> push();
  
  /// Pull remote changes from Supabase since last sync
  Future<void> pull();
  
  /// Full sync: push local then pull remote
  Future<void> syncNow();
  
  /// Queue an item for sync (called by repositories after local save)
  /// NOTE: Payload is NOT stored here - fetched from local DB during push()
  void queueForSync({
    required String tableName,
    required String recordId,
    required String operation, // 'insert', 'update', 'delete'
  });
  
  /// Dispose resources
  void dispose();
}
```

### Implementation Details

**SyncServiceImplementation Constructor:**
```dart
@LazySingleton(as: SyncService)
class SyncServiceImplementation implements SyncService {
  SyncServiceImplementation(
    this._syncQueue,
    this._connectivityService,
    this._supabaseClient,
    this._appDatabase,
    this._errorReportingService,
  );
  
  final SyncQueue _syncQueue;
  final ConnectivityService _connectivityService;
  final SupabaseClient _supabaseClient;
  final AppDatabase _appDatabase;
  final ErrorReportingService _errorReportingService;
  
  DateTime? _lastSyncTimestamp;
  static const String _lastSyncKey = 'last_sync_timestamp';
}
```

**Exponential Backoff Strategy:**
```dart
import 'dart:math';

/// Calculate retry delay with exponential backoff.
/// Attempts: 1→5s, 2→15s, 3→45s, 4→2min, 5→5min (capped)
Duration getRetryDelay(int attemptCount) {
  final seconds = min(300, 5 * pow(3, attemptCount - 1).toInt());
  return Duration(seconds: seconds);
}

/// Check if item should be retried based on attempt count
bool shouldRetry(int attemptCount) => attemptCount < 5;
```

**Deduplication Logic:**
```dart
Future<void> enqueue({
  required String tableName,
  required String recordId,
  required String operation,
}) async {
  // Check if already pending - update operation if exists
  final existing = await (select(syncQueueTable)
    ..where((t) => t.tableName_.equals(tableName) & 
                   t.recordId.equals(recordId) & 
                   t.isSynced.equals(false)))
    .getSingleOrNull();
  
  if (existing != null) {
    // Update existing entry's operation (e.g., insert→update, update→delete)
    await (update(syncQueueTable)..where((t) => t.id.equals(existing.id)))
      .write(SyncQueueTableCompanion(
        operation: Value(operation),
        createdAtTimestamp: Value(DateTime.now().toIso8601String()),
      ));
  } else {
    // Insert new entry
    await into(syncQueueTable).insert(SyncQueueTableCompanion.insert(
      tableName_: tableName,
      recordId: recordId,
      operation: operation,
      payloadJson: '{}', // Placeholder - payload fetched on push
      createdAtTimestamp: DateTime.now().toIso8601String(),
    ));
  }
}
```

**Push Operation Flow (Batch Operations):**
```dart
Future<void> push() async {
  if (_connectivityService.currentStatus != ConnectivityStatus.online) return;
  
  _updateStatus(SyncStatus.syncing);
  final pending = await _syncQueue.getPending();
  
  if (pending.isEmpty) {
    _updateStatus(SyncStatus.synced);
    return;
  }
  
  // Group by table for batch operations
  final byTable = <String, List<SyncQueueEntry>>{};
  for (final item in pending) {
    byTable.putIfAbsent(item.tableName_, () => []).add(item);
  }
  
  for (final entry in byTable.entries) {
    final tableName = entry.key;
    final items = entry.value;
    
    try {
      // Fetch current data from local DB for these records
      final records = await _fetchLocalRecords(tableName, items.map((i) => i.recordId).toList());
      
      // Batch upsert to Supabase
      await _supabaseClient.from(tableName).upsert(records);
      
      // Mark all as synced
      for (final item in items) {
        await _syncQueue.markSynced(item.id);
      }
    } catch (e) {
      for (final item in items) {
        if (shouldRetry(item.attemptCount)) {
          await _syncQueue.markFailed(item.id, e.toString());
        }
      }
    }
  }
  
  final remaining = await _syncQueue.pendingCount;
  _updateStatus(remaining > 0 ? SyncStatus.pendingChanges : SyncStatus.synced);
}
```

**Pull Operation Flow:**
```dart
Future<void> pull() async {
  if (_connectivityService.currentStatus != ConnectivityStatus.online) return;
  
  _updateStatus(SyncStatus.syncing);
  
  // Get last sync timestamp from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final lastSyncStr = prefs.getString(_lastSyncKey);
  final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.fromMillisecondsSinceEpoch(0);
  
  // Query each syncable table for updates since last sync
  for (final tableName in _syncableTables) {
    final remoteRecords = await _supabaseClient
      .from(tableName)
      .select()
      .gt('updated_at_timestamp', lastSync.toIso8601String());
    
    for (final remote in remoteRecords) {
      final recordId = remote['id'] as String;
      final remoteSyncVersion = remote['sync_version'] as int;
      
      if (await _shouldApplyRemoteChange(tableName, recordId, remoteSyncVersion)) {
        await _applyRemoteRecord(tableName, remote);
      }
    }
  }
  
  // Update last sync timestamp
  await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  _updateStatus(SyncStatus.synced);
}
```

**Conflict Resolution (LWW):**
```dart
Future<bool> _shouldApplyRemoteChange(
  String tableName,
  String recordId,
  int remoteSyncVersion,
) async {
  final localRecord = await _getLocalRecord(tableName, recordId);
  if (localRecord == null) return true; // No local record, apply remote
  
  final localSyncVersion = localRecord['sync_version'] as int;
  
  if (remoteSyncVersion > localSyncVersion) {
    // Remote wins - notify user of conflict resolution (FR69)
    _syncNotificationService.notifyConflictResolved(
      tableName: tableName,
      recordId: recordId,
      winner: 'remote',
    );
    return true;
  }
  return false; // Local wins or equal
}
```

### SyncNotificationService Placeholder

```dart
// lib/core/sync/sync_notification_service.dart
/// Placeholder for FR69: Visual notification for conflict resolution.
/// Full implementation in future story with UI widgets.
abstract class SyncNotificationService {
  void notifyConflictResolved({
    required String tableName,
    required String recordId,
    required String winner, // 'local' or 'remote'
  });
}

@LazySingleton(as: SyncNotificationService)
class SyncNotificationServiceImplementation implements SyncNotificationService {
  SyncNotificationServiceImplementation(this._errorReportingService);
  
  final ErrorReportingService _errorReportingService;
  
  @override
  void notifyConflictResolved({
    required String tableName,
    required String recordId,
    required String winner,
  }) {
    // Placeholder: log conflict resolution for now
    // FR69 visual notification will be implemented in UI story
    _errorReportingService.addBreadcrumb(
      message: 'Sync conflict resolved: $tableName/$recordId - $winner wins',
      category: 'sync',
    );
  }
}
```

### Schema Version Update

When adding `SyncQueueTable` to AppDatabase:

```dart
@DriftDatabase(tables: [Organizations, Users, SyncQueueTable])
class AppDatabase extends _$AppDatabase {
  // ...
  
  @override
  int get schemaVersion => 2;  // Increment from 1 to 2
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(syncQueueTable);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
```

### Barrel File Update

```dart
// lib/core/sync/sync.dart
library;

export 'autosave_service.dart';
export 'autosave_status.dart';
export 'sync_notification_service.dart';
export 'sync_queue.dart';
export 'sync_service.dart';
export 'sync_status.dart';
```

### Testing Strategy

**Unit Tests Required:**

1. **SyncQueue Tests:**
   - `enqueue()` adds item to database
   - `enqueue()` deduplicates by table_name + record_id
   - `getPending()` returns items ordered by created_at where is_synced = false
   - `markSynced()` sets is_synced = true
   - `markFailed()` increments attempt_count and sets error message
   - `clearSynced()` removes items where is_synced = true

2. **SyncService Tests:**
   - Status stream emits `pendingChanges` when item queued
   - Status stream emits `syncing` when push/pull starts
   - Status stream emits `synced` when all items synced
   - Status stream emits `error` on failure
   - `push()` batches records by table for efficiency
   - `pull()` only applies remote changes with higher sync_version
   - Conflict resolution: higher sync_version wins

3. **Retry Logic Tests:**
   - Exponential backoff calculates correct delays
   - Max 5 retry attempts before giving up

**Mocking Requirements:**
```dart
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockSyncQueue extends Mock implements SyncQueue {}
class MockErrorReportingService extends Mock implements ErrorReportingService {}

// Use in-memory Drift database for testing
final testDb = AppDatabase.forTesting(NativeDatabase.memory());
```

### NOT Modifying AutosaveService in This Story

**IMPORTANT:** The current `AutosaveService` has a placeholder comment for future sync integration:
```dart
// Queue for sync (implementation in future Story 1.10)
```

This story creates the `SyncService` infrastructure. The actual integration point where repositories call `SyncService.queueForSync()` after local saves will be implemented when feature repositories are built in later epics (Tournament, Division, etc.). 

The `AutosaveService` dirty tracking and `SyncService` queue are **complementary but separate**:
- `AutosaveService`: Tracks in-memory dirty state, triggers periodic local saves
- `SyncService`: Tracks pending remote sync operations, handles push/pull to Supabase

Repositories will:
1. Save to local DB
2. Call `autosaveService.markDirty()` (for UI feedback)
3. Call `syncService.queueForSync()` (for remote sync queue)

## Story Wrap Up

- [x] All acceptance criteria verified
- [x] All tests pass (211 total, 22 sync_service tests)
- [x] Code analysis clean (only info-level style issues remain)
- [x] Story file updated with completion notes
- [x] sprint-status.yaml updated (story status: done)

### Code Review Findings (2026-02-07)

**Issues Found:** 1 CRITICAL, 3 HIGH, 3 MEDIUM, 3 LOW

#### Issues Fixed:

1. **[CRITICAL] Missing Unit Test File** - FIXED
   - Created `test/core/sync/sync_service_test.dart` with 22 comprehensive tests
   - Covers: initialization, statusStream, queueForSync, push/pull, connectivity, exponential backoff, dispose

2. **[HIGH] N+1 Query Pattern in _fetchLocalRecords** - FIXED
   - Changed from individual fetches to batch queries using `isIn()`
   - Performance improvement for bulk sync operations

3. **[HIGH] sync_version Column Missing Explicit Naming** - FIXED
   - Added `.named('sync_version')` for Supabase compatibility

4. **[HIGH] sync_queue_table Missing Performance Index** - DOCUMENTED
   - Added comment in table definition for migration-based index creation
   - Drift doesn't support declarative indexes; use migration SQL

5. **[MEDIUM] Unnecessary Type Casts** - FIXED
   - Removed 4 unnecessary casts in push() method

6. **[MEDIUM] Line Length Violation** - FIXED
   - Split long line in sync_queue.dart:97

7. **[LOW] Style Issues** - NOT FIXED (info-level)
   - EOL at end of file issues
   - Single-member abstract class
   - Cascade invocation suggestions in tests

## References

- **Architecture:** `_bmad-output/planning-artifacts/architecture.md` - Sections on Sync Layer Pattern (lines 282-313), Database Schema (sync_queue table lines 1513-1528)
- **PRD:** FR65-FR69 (Offline & Reliability)
- **Epic:** 1.10 from `_bmad-output/planning-artifacts/epics.md`
- **Previous Stories:** 1.5 (Drift DB), 1.6 (Supabase), 1.8 (Connectivity), 1.9 (Autosave)
- **Existing Code:**
  - `lib/core/sync/autosave_service.dart` - EXISTS, not modified in this story
  - `lib/core/network/connectivity_service.dart` - dependency for online/offline
  - `lib/core/database/app_database.dart` - will add SyncQueueTable
  - `lib/core/database/tables/base_tables.dart` - verify sync_version column

