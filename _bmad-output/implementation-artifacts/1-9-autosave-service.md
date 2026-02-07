# Story 1.9: Autosave Service

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

**As a** developer,
**I want** an autosave service that persists dirty data every 5 seconds,
**so that** users never lose work even if they forget to save (FR65).

## Acceptance Criteria

1. **AC1:** Service located at `lib/core/sync/autosave_service.dart` with abstract interface and implementation
2. **AC2:** Periodic saving configured for every 5 seconds using `Timer.periodic`
3. **AC3:** Dirty tracking mechanism for modified entities (knows what needs saving)
4. **AC4:** Save on app pause/background via `WidgetsBindingObserver` lifecycle detection
5. **AC5:** Only modified data is saved (incremental save, not full database dump)
6. **AC6:** Autosave respects connectivity status (local save always, cloud sync when online)
7. **AC7:** Unit tests verify save timing, dirty tracking, and lifecycle behavior

## Tasks / Subtasks

- [x] **Task 1: Create sync directory structure** (AC: 1)
  - [x] Create `lib/core/sync/` directory
  - [x] Create `autosave_service.dart` file
  - [x] Create `autosave_status.dart` enum file
  - [x] Create `sync.dart` barrel file exporting both modules

- [x] **Task 2: Implement AutosaveStatus enum** (AC: 2, 3)
  - [x] Define enum at `lib/core/sync/autosave_status.dart`
  - [x] Include states: `idle`, `saving`, `saved`, `error`

- [x] **Task 3: Implement AutosaveService interface and implementation** (AC: 1, 2, 3, 5, 6)
  - [x] Define abstract `AutosaveService` interface with:
    - `Stream<AutosaveStatus> get statusStream`
    - `AutosaveStatus get currentStatus`
    - `DateTime? get lastSaveTime`
    - `int get dirtyEntityCount`
    - `void markDirty(String entityType, String entityId)`
    - `void clearDirty(String entityType, String entityId)`
    - `Future<void> saveNow()`
    - `void start()`
    - `void stop()`
    - `void dispose()`
  - [x] Implement `AutosaveServiceImplementation` with:
    - `@LazySingleton(as: AutosaveService)` annotation
    - Inject `AppDatabase` dependency
    - Inject `ConnectivityService` dependency
    - Inject `ErrorReportingService` for logging
    - 5-second `Timer.periodic` for autosave interval
    - Track dirty entities using `Map<String, Set<String>>` (entityType → entityIds)
    - Implement incremental save logic (only dirty entities)
    - Check connectivity before cloud sync attempt

- [x] **Task 4: Implement app lifecycle observer** (AC: 4)
  - [x] Implement `WidgetsBindingObserver` mixin on `AutosaveServiceImplementation`
  - [x] Trigger `saveNow()` on `AppLifecycleState.paused` and `AppLifecycleState.inactive`
  - [x] Register observer in service initialization
  - [x] Unregister observer on dispose

- [x] **Task 5: Update DI registration** (AC: 1)
  - [x] No additional module needed (using `@LazySingleton` auto-registration)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`
  - [x] Verify `AutosaveService` registered in `injection.config.dart`

- [x] **Task 6: Create test directory structure** (AC: 7)
  - [x] Create `test/core/sync/` directory
  - [x] Create `autosave_service_test.dart`
  - [x] Create `autosave_status_test.dart`

- [x] **Task 7: Implement unit tests** (AC: 7)
  - [x] Test periodic save timer fires at 5-second intervals
  - [x] Test dirty tracking correctly adds/removes entities
  - [x] Test `saveNow()` only persists dirty entities (not full DB)
  - [x] Test lifecycle observer triggers save on app pause
  - [x] Test connectivity awareness (local save without connectivity)
  - [x] Test status stream emits correct states during save cycle
  - [x] Test error handling and status updates on failure

- [x] **Task 8: Verification** (AC: All)
  - [x] Run `dart analyze` - zero errors (info-level lints in tests only)
  - [x] Run `flutter test` - all 160 tests pass
  - [x] Run `flutter build web --release` - builds successfully


## Dev Notes

### Project Location

**CRITICAL:** All code changes are in:
```
/Users/asak/Documents/dev/proj/personal/taekwondo_fix/tkd_brackets/
```

### Architecture Pattern - Service Implementation

Follow the established **abstract interface + implementation** pattern from `ConnectivityService`:

```dart
// lib/core/sync/autosave_service.dart

/// Abstract interface for autosave functionality.
abstract class AutosaveService {
  Stream<AutosaveStatus> get statusStream;
  AutosaveStatus get currentStatus;
  DateTime? get lastSaveTime;
  int get dirtyEntityCount;
  
  void markDirty(String entityType, String entityId);
  void clearDirty(String entityType, String entityId);
  Future<void> saveNow();
  void start();
  void stop();
  void dispose();
}

/// Implementation of AutosaveService with 5-second periodic save.
@LazySingleton(as: AutosaveService)
class AutosaveServiceImplementation implements AutosaveService {
  AutosaveServiceImplementation(
    this._appDatabase,
    this._connectivityService,
    this._errorReportingService,
  );
  
  // ... implementation
}
```

### Dirty Tracking Strategy

Use a lightweight in-memory tracking structure:

```dart
// entityType → Set of entityIds
final Map<String, Set<String>> _dirtyEntities = {};

void markDirty(String entityType, String entityId) {
  _dirtyEntities.putIfAbsent(entityType, () => {}).add(entityId);
}

void clearDirty(String entityType, String entityId) {
  _dirtyEntities[entityType]?.remove(entityId);
  if (_dirtyEntities[entityType]?.isEmpty ?? false) {
    _dirtyEntities.remove(entityType);
  }
}

bool get hasDirtyEntities => _dirtyEntities.values.any((set) => set.isNotEmpty);

int get dirtyEntityCount => 
    _dirtyEntities.values.fold(0, (sum, set) => sum + set.length);
```

### Timer Pattern

```dart
Timer? _autosaveTimer;
static const _autosaveInterval = Duration(seconds: 5);
bool _isSaving = false; // Guard against concurrent saves

void start() {
  _autosaveTimer?.cancel();
  _autosaveTimer = Timer.periodic(_autosaveInterval, (_) => _performAutosave());
}

void stop() {
  _autosaveTimer?.cancel();
  _autosaveTimer = null;
}

Future<void> _performAutosave() async {
  if (_isSaving) return; // Prevent concurrent saves
  if (!hasDirtyEntities) return;
  
  _isSaving = true;
  _updateStatus(AutosaveStatus.saving);
  try {
    await saveNow();
    _lastSaveTime = DateTime.now();
    _updateStatus(AutosaveStatus.saved);
  } catch (e, stackTrace) {
    _errorReportingService.logException(e, stackTrace);
    _updateStatus(AutosaveStatus.error);
  } finally {
    _isSaving = false;
  }
}
```

### Lifecycle Observer Pattern

```dart
class _AutosaveLifecycleObserver extends WidgetsBindingObserver {
  _AutosaveLifecycleObserver(this._autosaveService);
  final AutosaveServiceImplementation _autosaveService;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      _autosaveService.saveNow();
    }
  }
}
```

**Registration:**
```dart
late final _AutosaveLifecycleObserver _lifecycleObserver;

AutosaveServiceImplementation(...) {
  _lifecycleObserver = _AutosaveLifecycleObserver(this);
  WidgetsBinding.instance.addObserver(_lifecycleObserver);
  start(); // Start timer on construction
}

@override
void dispose() {
  stop();
  WidgetsBinding.instance.removeObserver(_lifecycleObserver);
  _statusController.close();
}
```

### Connectivity Awareness

The autosave should **always save locally** but only attempt cloud sync when online:

```dart
Future<void> saveNow() async {
  if (!hasDirtyEntities) return;
  
  // Always save to local Drift database
  await _saveToLocalDatabase();
  
  // Only attempt cloud sync if online
  if (_connectivityService.currentStatus == ConnectivityStatus.online) {
    // Queue for sync (implementation in future Story 1.10)
    // For now, just log that we would sync
    _errorReportingService.logMessage(
      'Autosave: ${dirtyEntityCount} entities saved locally, ready for cloud sync',
    );
  }
  
  // Clear dirty tracking after successful save
  _clearAllDirty();
}
```

### Local Database Save Implementation

**IMPORTANT:** For MVP, `_saveToLocalDatabase()` is a **placeholder/infrastructure stub**. The actual entity-specific save logic will be integrated as features are built in later epics.

```dart
/// For MVP, this is a placeholder. Actual entity-specific save logic 
/// will be added as features are implemented in later epics.
/// 
/// Future implementation will:
/// 1. Iterate _dirtyEntities by entityType
/// 2. Call appropriate DAO methods for each type
/// 3. Handle partial failures gracefully
Future<void> _saveToLocalDatabase() async {
  // In future: iterate _dirtyEntities and call appropriate DAO methods
  // Example future implementation:
  // for (final entry in _dirtyEntities.entries) {
  //   final entityType = entry.key;
  //   final entityIds = entry.value;
  //   switch (entityType) {
  //     case 'tournament': await _saveTournaments(entityIds);
  //     case 'division': await _saveDivisions(entityIds);
  //     // etc.
  //   }
  // }
  
  // For now: just log to establish the pattern
  _errorReportingService.logMessage(
    'AutosaveService: Would save ${dirtyEntityCount} dirty entities',
  );
}

void _clearAllDirty() {
  _dirtyEntities.clear();
}
```

### AutosaveStatus Enum

Create at `lib/core/sync/autosave_status.dart`:

```dart
/// Represents the current state of the autosave service.
enum AutosaveStatus {
  /// Service is running but no save in progress.
  idle,
  
  /// Currently saving dirty entities.
  saving,
  
  /// Last save completed successfully.
  saved,
  
  /// Last save encountered an error.
  error,
}
```

### Project Structure Notes

**New files to create:**
```
lib/core/sync/
├── autosave_service.dart     # Abstract + Implementation
└── autosave_status.dart      # Enum

test/core/sync/
├── autosave_service_test.dart
└── autosave_status_test.dart
```

**Naming conventions (from architecture.md):**
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Enums: `PascalCase` with `camelCase` values
- Use full words, not abbreviations

### Dependencies (Already Available)

1. **AppDatabase** - `lib/core/database/app_database.dart` - `@lazySingleton`
2. **ConnectivityService** - `lib/core/network/connectivity_service.dart` - `@LazySingleton(as: ConnectivityService)`
3. **ErrorReportingService** - `lib/core/services/error_reporting_service.dart` - `@lazySingleton`

### Testing Pattern

Follow the pattern from `connectivity_service_test.dart`:

```dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';
import 'package:tkd_brackets/core/services/error_reporting_service.dart';
import 'package:tkd_brackets/core/sync/autosave_service.dart';
import 'package:tkd_brackets/core/sync/autosave_status.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockErrorReportingService extends Mock implements ErrorReportingService {}

void main() {
  late MockAppDatabase mockDatabase;
  late MockConnectivityService mockConnectivity;
  late MockErrorReportingService mockErrorReporting;
  
  setUp(() {
    mockDatabase = MockAppDatabase();
    mockConnectivity = MockConnectivityService();
    mockErrorReporting = MockErrorReportingService();
    
    when(() => mockConnectivity.currentStatus)
        .thenReturn(ConnectivityStatus.online);
  });
  
  group('AutosaveServiceImplementation', () {
    test('should start with idle status', () {
      // Test idle initial state
    });
    
    test('should track dirty entities correctly', () {
      // Test markDirty and clearDirty
    });
    
    test('should only save when dirty entities exist', () async {
      // Test saveNow with no dirty entities does nothing
    });
    
    test('should update status during save cycle', () async {
      // Test idle → saving → saved transitions
    });
    
    test('should respect 5-second autosave interval', () async {
      // Use fake timers to verify interval
    });
    
    test('should save on lifecycle pause', () {
      // Test lifecycle observer triggers save
    });
  });
}
```

**Important:** Use `TestWidgetsFlutterBinding.ensureInitialized()` in tests that interact with `WidgetsBinding`.

### Potential Pitfalls

1. **Timer cleanup:** Ensure timer is cancelled in `dispose()` to prevent memory leaks
2. **WidgetsBinding in tests:** Must call `TestWidgetsFlutterBinding.ensureInitialized()` before tests
3. **Concurrent saves:** Guard against multiple simultaneous save operations
4. **Empty dirty set:** Check `hasDirtyEntities` before attempting save
5. **Dispose ordering:** Cancel timer before closing stream controller

### Integration with Future Stories

This story creates the foundation that Story 1.10 (Sync Service Foundation) will build upon:
- `AutosaveService.saveNow()` will eventually call `SyncService.queueForSync()`
- The dirty tracking pattern will be extended for sync queue management
- For now, just log sync intent without actual cloud sync implementation

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.9: Autosave Service]
- [Source: _bmad-output/planning-artifacts/architecture.md#Sync Layer Pattern (lines 282-314)]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project Directory Structure (lines 1013-1017)]
- [Source: _bmad-output/planning-artifacts/prd.md#FR65 - Autosave every 5 seconds]
- [Source: tkd_brackets/lib/core/network/connectivity_service.dart - Service pattern reference]
- [Source: tkd_brackets/test/core/network/connectivity_service_test.dart - Test pattern reference]

---

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

- **2026-02-07 Code Review:** Fixed HIGH-severity lifecycle save logic flaw by centralizing concurrency guard, status updates, and error handling into `saveNow()`. Previously, saves triggered by `didChangeAppLifecycleState` bypassed all safety logic. Updated File List documentation (MEDIUM fix).

### File List

- `lib/core/sync/autosave_service.dart` - Abstract interface and implementation
- `lib/core/sync/autosave_status.dart` - AutosaveStatus enum
- `lib/core/sync/sync.dart` - Barrel file for sync exports
- `test/core/sync/autosave_service_test.dart` - Unit tests for AutosaveServiceImplementation
- `test/core/sync/autosave_status_test.dart` - Unit tests for AutosaveStatus enum
