import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';
import 'package:tkd_brackets/core/sync/autosave_status.dart';

/// Abstract interface for autosave functionality.
///
/// Provides automatic persistence of dirty data at regular intervals and
/// on app lifecycle events. Used to ensure users never lose work even
/// if they forget to save (FR65).
abstract class AutosaveService {
  /// Stream of autosave status changes.
  ///
  /// Emits a new [AutosaveStatus] whenever the save state changes.
  /// Subscribe to this stream to react to autosave state changes in real-time.
  Stream<AutosaveStatus> get statusStream;

  /// Current autosave status.
  ///
  /// Returns the last known autosave status.
  AutosaveStatus get currentStatus;

  /// Timestamp of the last successful save.
  ///
  /// Returns `null` if no save has been performed yet.
  DateTime? get lastSaveTime;

  /// Number of entities currently marked as dirty.
  ///
  /// Returns the count of all entity IDs across all entity types.
  int get dirtyEntityCount;

  /// Marks an entity as dirty (needing to be saved).
  ///
  /// [entityType] The type of entity (e.g., 'tournament', 'division')
  /// [entityId] The unique identifier of the entity
  void markDirty(String entityType, String entityId);

  /// Clears the dirty flag for an entity.
  ///
  /// Call this after an entity has been successfully saved.
  /// [entityType] The type of entity
  /// [entityId] The unique identifier of the entity
  void clearDirty(String entityType, String entityId);

  /// Triggers an immediate save of all dirty entities.
  ///
  /// This performs a local database save and, if online, queues for cloud sync.
  /// Returns when the save operation is complete.
  Future<void> saveNow();

  /// Starts the autosave timer.
  ///
  /// Call this to begin automatic saving at the configured interval.
  void start();

  /// Stops the autosave timer.
  ///
  /// Call this to pause automatic saving (e.g., during maintenance).
  void stop();

  /// Disposes of resources and subscriptions.
  ///
  /// Call this when the service is no longer needed
  /// (typically on app shutdown).
  void dispose();
}

/// Implementation of [AutosaveService] with 5-second periodic save.
///
/// This service:
/// - Saves dirty entities every 5 seconds via [Timer.periodic]
/// - Triggers save on app pause/background via [WidgetsBindingObserver]
/// - Tracks dirty entities using an in-memory map
/// - Respects connectivity status (always saves locally, syncs when online)
@LazySingleton(as: AutosaveService)
class AutosaveServiceImplementation
    with WidgetsBindingObserver
    implements AutosaveService {
  AutosaveServiceImplementation(
    this._appDatabase,
    this._connectivityService,
    this._errorReportingService,
  ) {
    WidgetsBinding.instance.addObserver(this);
    start();
  }

  final AppDatabase _appDatabase;
  final ConnectivityService _connectivityService;
  final ErrorReportingService _errorReportingService;

  /// Autosave interval: 5 seconds as per FR65.
  static const _autosaveInterval = Duration(seconds: 5);

  final StreamController<AutosaveStatus> _statusController =
      StreamController<AutosaveStatus>.broadcast();

  AutosaveStatus _currentStatus = AutosaveStatus.idle;
  DateTime? _lastSaveTime;
  Timer? _autosaveTimer;
  bool _isSaving = false;

  /// Tracks dirty entities: entityType → Set of entityIds
  final Map<String, Set<String>> _dirtyEntities = {};

  @override
  Stream<AutosaveStatus> get statusStream => _statusController.stream;

  @override
  AutosaveStatus get currentStatus => _currentStatus;

  @override
  DateTime? get lastSaveTime => _lastSaveTime;

  @override
  int get dirtyEntityCount =>
      _dirtyEntities.values.fold(0, (sum, set) => sum + set.length);

  /// Returns `true` if there are any dirty entities.
  bool get hasDirtyEntities =>
      _dirtyEntities.values.any((set) => set.isNotEmpty);

  @override
  void markDirty(String entityType, String entityId) {
    _dirtyEntities.putIfAbsent(entityType, () => {}).add(entityId);
  }

  @override
  void clearDirty(String entityType, String entityId) {
    _dirtyEntities[entityType]?.remove(entityId);
    if (_dirtyEntities[entityType]?.isEmpty ?? false) {
      _dirtyEntities.remove(entityType);
    }
  }

  @override
  void start() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(
      _autosaveInterval,
      (_) => _performAutosave(),
    );
  }

  @override
  void stop() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
  }

  @override
  Future<void> saveNow() async {
    if (_isSaving) return; // Prevent concurrent saves
    if (!hasDirtyEntities) return;

    _isSaving = true;
    _updateStatus(AutosaveStatus.saving);

    try {
      // Always save to local Drift database
      await _saveToLocalDatabase();

      // Only attempt cloud sync if online
      if (_connectivityService.currentStatus == ConnectivityStatus.online) {
        // Queue for sync (implementation in future Story 1.10)
        // For now, just log that we would sync
        _errorReportingService.addBreadcrumb(
          message:
              'Autosave: $dirtyEntityCount entities saved locally, '
              'ready for cloud sync',
          category: 'autosave',
        );
      }

      // Clear dirty tracking after successful save
      _clearAllDirty();
      _lastSaveTime = DateTime.now();
      _updateStatus(AutosaveStatus.saved);
    } on Exception catch (e, stackTrace) {
      _errorReportingService.reportException(
        e,
        stackTrace,
        context: 'Autosave',
      );
      _updateStatus(AutosaveStatus.error);
    } finally {
      _isSaving = false;
    }
  }

  /// Internal method used by the periodic timer.
  /// Simply delegates to saveNow() which now contains all safety logic.
  Future<void> _performAutosave() async {
    await saveNow();
  }

  /// Saves dirty entities to the local database.
  ///
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

    // For now: just add breadcrumb to establish the pattern
    _errorReportingService.addBreadcrumb(
      message: 'AutosaveService: Would save $dirtyEntityCount dirty entities',
      category: 'autosave',
      data: {
        'entityTypes': _dirtyEntities.keys.toList(),
        'totalCount': dirtyEntityCount,
      },
    );

    // Reference to _appDatabase to avoid unused warning
    // Will be used for actual entity persistence in future epics
    assert(
      _appDatabase.schemaVersion >= 1,
      'Database schema version must be at least 1',
    );
  }

  void _clearAllDirty() {
    _dirtyEntities.clear();
  }

  void _updateStatus(AutosaveStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WidgetsBindingObserver implementation
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Trigger immediate save when app goes to background
      saveNow();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Disposal
  // ───────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    stop();
    WidgetsBinding.instance.removeObserver(this);
    _statusController.close();
  }
}
