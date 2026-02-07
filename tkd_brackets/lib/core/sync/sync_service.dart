import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/network/connectivity_status.dart';
import 'package:tkd_brackets/core/sync/sync_notification_service.dart';
import 'package:tkd_brackets/core/sync/sync_queue.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';

/// Abstract interface for synchronization with Supabase.
///
/// Provides bidirectional sync using Last-Write-Wins (LWW) conflict resolution.
/// Push sends local changes to remote; pull fetches remote changes to local.
abstract class SyncService {
  /// Stream of sync status changes.
  ///
  /// Emits a new [SyncStatus] whenever the sync state changes.
  /// Subscribe to react to sync state changes in real-time (e.g., for UI).
  Stream<SyncStatus> get statusStream;

  /// Current sync status.
  ///
  /// Returns the last known sync status.
  SyncStatus get currentStatus;

  /// Current error if status is [SyncStatus.error], null otherwise.
  SyncError? get currentError;

  /// Number of pending changes waiting to sync.
  int get pendingChangeCount;

  /// Pushes local changes to Supabase.
  ///
  /// Processes the sync queue and uploads pending operations in batches.
  /// Uses LWW conflict resolution based on sync_version.
  Future<void> push();

  /// Pulls remote changes from Supabase.
  ///
  /// Fetches changes since the last sync timestamp and applies them locally
  /// using LWW conflict resolution.
  Future<void> pull();

  /// Performs a full sync: push local changes, then pull remote changes.
  Future<void> syncNow();

  /// Queues an item for sync (called by repositories after local save).
  ///
  /// NOTE: The actual payload is NOT stored here - it's fetched from the
  /// local database during [push] to ensure the latest data is synced.
  ///
  /// [tableName] The database table name (e.g., 'organizations')
  /// [recordId] The UUID of the record
  /// [operation] The operation type: 'insert', 'update', or 'delete'
  void queueForSync({
    required String tableName,
    required String recordId,
    required String operation,
  });

  /// Disposes of resources and subscriptions.
  void dispose();
}

/// Implementation of [SyncService] using LWW conflict resolution.
///
/// This service:
/// - Manages the sync queue for pending operations
/// - Batches operations by table for efficiency
/// - Implements exponential backoff retry strategy
/// - Uses sync_version for LWW conflict resolution
/// - Tracks last sync timestamp for incremental pulls
@LazySingleton(as: SyncService)
class SyncServiceImplementation implements SyncService {
  SyncServiceImplementation(
    this._syncQueue,
    this._connectivityService,
    this._supabaseClient,
    this._appDatabase,
    this._errorReportingService,
    this._syncNotificationService,
  ) {
    _initialize();
  }

  final SyncQueue _syncQueue;
  final ConnectivityService _connectivityService;
  final SupabaseClient _supabaseClient;
  final AppDatabase _appDatabase;
  final ErrorReportingService _errorReportingService;
  final SyncNotificationService _syncNotificationService;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = SyncStatus.synced;
  SyncError? _currentError;
  int _pendingChangeCount = 0;

  /// SharedPreferences key for last sync timestamp.
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Maximum number of retry attempts before giving up.
  static const int _maxRetryAttempts = 5;

  /// Tables that support syncing to Supabase.
  static const List<String> _syncableTables = ['organizations', 'users'];

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  SyncStatus get currentStatus => _currentStatus;

  @override
  SyncError? get currentError => _currentError;

  @override
  int get pendingChangeCount => _pendingChangeCount;

  void _initialize() {
    // Listen for connectivity changes to trigger sync when coming online
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _handleConnectivityChange,
    );

    // Update initial pending count
    _updatePendingCount();
  }

  void _handleConnectivityChange(ConnectivityStatus status) {
    if (status == ConnectivityStatus.online && _pendingChangeCount > 0) {
      // Trigger sync when coming back online with pending changes
      syncNow();
    }
  }

  Future<void> _updatePendingCount() async {
    _pendingChangeCount = await _syncQueue.pendingCount;
    if (_pendingChangeCount > 0 && _currentStatus == SyncStatus.synced) {
      _updateStatus(SyncStatus.pendingChanges);
    }
  }

  void _updateStatus(SyncStatus status, {SyncError? error}) {
    if (_currentStatus != status || _currentError != error) {
      _currentStatus = status;
      _currentError = error;
      _statusController.add(status);
    }
  }

  @override
  void queueForSync({
    required String tableName,
    required String recordId,
    required String operation,
  }) {
    // Fire and forget - let it run async
    _enqueueAndUpdateStatus(tableName, recordId, operation);
  }

  Future<void> _enqueueAndUpdateStatus(
    String tableName,
    String recordId,
    String operation,
  ) async {
    await _syncQueue.enqueue(
      tableName: tableName,
      recordId: recordId,
      operation: operation,
    );
    await _updatePendingCount();

    _errorReportingService.addBreadcrumb(
      message: 'Queued for sync: $operation on $tableName/$recordId',
      category: 'sync',
    );
  }

  @override
  Future<void> push() async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      _errorReportingService.addBreadcrumb(
        message: 'Push skipped: offline',
        category: 'sync',
      );
      return;
    }

    _updateStatus(SyncStatus.syncing);
    final pending = await _syncQueue.getPending();

    if (pending.isEmpty) {
      _updateStatus(SyncStatus.synced);
      return;
    }

    _errorReportingService.addBreadcrumb(
      message: 'Starting push: ${pending.length} items',
      category: 'sync',
    );

    // Group by table for batch operations
    final byTable = <String, List<SyncQueueEntry>>{};
    for (final item in pending) {
      byTable.putIfAbsent(item.tableName_, () => []).add(item);
    }

    var hasErrors = false;
    var failedCount = 0;

    for (final entry in byTable.entries) {
      final tableName = entry.key;
      final items = entry.value;

      try {
        // Fetch current data from local DB for these records
        final records = await _fetchLocalRecords(
          tableName,
          items.map((i) => i.recordId).toList(),
        );

        if (records.isNotEmpty) {
          // Batch upsert to Supabase
          await _supabaseClient.from(tableName).upsert(records);

          // Mark all as synced
          for (final item in items) {
            await _syncQueue.markSynced(item.id);
          }

          _errorReportingService.addBreadcrumb(
            message: 'Pushed ${records.length} records to $tableName',
            category: 'sync',
          );
        }
      } on Exception catch (e) {
        hasErrors = true;
        for (final item in items) {
          if (_shouldRetry(item.attemptCount)) {
            await _syncQueue.markFailed(item.id, e.toString());
            failedCount++;
          }
        }

        _errorReportingService.addBreadcrumb(
          message: 'Push failed for $tableName: $e',
          category: 'sync',
          data: {'error': e.toString()},
        );
      }
    }

    await _updatePendingCount();

    if (hasErrors) {
      _updateStatus(
        SyncStatus.error,
        error: SyncError(
          message: 'Some changes failed to sync',
          technicalDetails: '$failedCount operations failed',
          failedOperationCount: failedCount,
        ),
      );
    } else if (_pendingChangeCount > 0) {
      _updateStatus(SyncStatus.pendingChanges);
    } else {
      _updateStatus(SyncStatus.synced);
    }
  }

  @override
  Future<void> pull() async {
    if (_connectivityService.currentStatus != ConnectivityStatus.online) {
      _errorReportingService.addBreadcrumb(
        message: 'Pull skipped: offline',
        category: 'sync',
      );
      return;
    }

    _updateStatus(SyncStatus.syncing);

    try {
      // Get last sync timestamp from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      _errorReportingService.addBreadcrumb(
        message: 'Starting pull since: $lastSync',
        category: 'sync',
      );

      var totalApplied = 0;

      // Query each syncable table for updates since last sync
      for (final tableName in _syncableTables) {
        final remoteRecords = await _supabaseClient
            .from(tableName)
            .select()
            .gt('updated_at_timestamp', lastSync.toIso8601String());

        for (final remote in remoteRecords) {
          final recordId = remote['id'] as String;
          final remoteSyncVersion = remote['sync_version'] as int;

          if (await _shouldApplyRemoteChange(
              tableName, recordId, remoteSyncVersion)) {
            await _applyRemoteRecord(tableName, remote);
            totalApplied++;
          }
        }
      }

      // Update last sync timestamp
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      _errorReportingService.addBreadcrumb(
        message: 'Pull complete: $totalApplied records applied',
        category: 'sync',
      );

      // Update status based on pending count
      await _updatePendingCount();
      if (_pendingChangeCount > 0) {
        _updateStatus(SyncStatus.pendingChanges);
      } else {
        _updateStatus(SyncStatus.synced);
      }
    } on Exception catch (e, stackTrace) {
      _errorReportingService.reportException(e, stackTrace, context: 'Pull');
      _updateStatus(
        SyncStatus.error,
        error: SyncError(
          message: 'Failed to sync from server',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> syncNow() async {
    await push();
    await pull();
  }

  /// Checks if a retry should be attempted based on attempt count.
  bool _shouldRetry(int attemptCount) => attemptCount < _maxRetryAttempts;

  /// Calculates retry delay with exponential backoff.
  ///
  /// Attempts: 1→5s, 2→15s, 3→45s, 4→2min, 5→5min (capped)
  Duration getRetryDelay(int attemptCount) {
    final seconds = min(300, 5 * pow(3, attemptCount - 1).toInt());
    return Duration(seconds: seconds);
  }

  /// Fetches current records from local database for given IDs.
  ///
  /// Uses batch queries for efficiency instead of individual queries.
  Future<List<Map<String, dynamic>>> _fetchLocalRecords(
    String tableName,
    List<String> recordIds,
  ) async {
    if (recordIds.isEmpty) return [];

    switch (tableName) {
      case 'organizations':
        final orgs = await (_appDatabase.select(_appDatabase.organizations)
              ..where((o) => o.id.isIn(recordIds)))
            .get();
        return orgs.map(_organizationToMap).toList();
      case 'users':
        final users = await (_appDatabase.select(_appDatabase.users)
              ..where((u) => u.id.isIn(recordIds)))
            .get();
        return users.map(_userToMap).toList();
      default:
        return [];
    }
  }

  /// Gets a single local record by table name and ID.
  Future<Map<String, dynamic>?> _getLocalRecord(
    String tableName,
    String recordId,
  ) async {
    switch (tableName) {
      case 'organizations':
        final org = await _appDatabase.getOrganizationById(recordId);
        if (org != null) {
          return _organizationToMap(org);
        }
      case 'users':
        final user = await _appDatabase.getUserById(recordId);
        if (user != null) {
          return _userToMap(user);
        }
    }
    return null;
  }

  /// Determines if a remote change should be applied based on LWW.
  Future<bool> _shouldApplyRemoteChange(
    String tableName,
    String recordId,
    int remoteSyncVersion,
  ) async {
    final localRecord = await _getLocalRecord(tableName, recordId);
    if (localRecord == null) {
      // No local record, apply remote
      return true;
    }

    final localSyncVersion = localRecord['sync_version'] as int;

    if (remoteSyncVersion > localSyncVersion) {
      // Remote wins - notify of conflict resolution
      _syncNotificationService.notifyConflictResolved(
        tableName: tableName,
        recordId: recordId,
        winner: 'remote',
      );
      return true;
    }

    // Local wins or equal - don't apply
    return false;
  }

  /// Applies a remote record to the local database.
  Future<void> _applyRemoteRecord(
    String tableName,
    Map<String, dynamic> remote,
  ) async {
    switch (tableName) {
      case 'organizations':
        await _applyRemoteOrganization(remote);
      case 'users':
        await _applyRemoteUser(remote);
    }
  }

  Future<void> _applyRemoteOrganization(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final existing = await _appDatabase.getOrganizationById(id);

    if (existing == null) {
      // Insert new organization
      await _appDatabase.insertOrganization(
        _mapToOrganizationsCompanion(remote),
      );
    } else {
      // Update existing - note: this bypasses the sync_version increment
      // because we're applying a remote change
      await (_appDatabase.update(_appDatabase.organizations)
            ..where((o) => o.id.equals(id)))
          .write(_mapToOrganizationsCompanion(remote));
    }
  }

  Future<void> _applyRemoteUser(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final existing = await _appDatabase.getUserById(id);

    if (existing == null) {
      // Insert new user
      await _appDatabase.insertUser(_mapToUsersCompanion(remote));
    } else {
      // Update existing
      await (_appDatabase.update(_appDatabase.users)
            ..where((u) => u.id.equals(id)))
          .write(_mapToUsersCompanion(remote));
    }
  }

  /// Converts an OrganizationEntry to a map for Supabase upsert.
  Map<String, dynamic> _organizationToMap(OrganizationEntry org) {
    return {
      'id': org.id,
      'name': org.name,
      'slug': org.slug,
      'subscription_tier': org.subscriptionTier,
      'subscription_status': org.subscriptionStatus,
      'max_tournaments_per_month': org.maxTournamentsPerMonth,
      'max_active_brackets': org.maxActiveBrackets,
      'max_participants_per_bracket': org.maxParticipantsPerBracket,
      'max_participants_per_tournament': org.maxParticipantsPerTournament,
      'max_scorers': org.maxScorers,
      'is_active': org.isActive,
      'sync_version': org.syncVersion,
      'is_deleted': org.isDeleted,
      'deleted_at_timestamp': org.deletedAtTimestamp?.toIso8601String(),
      'is_demo_data': org.isDemoData,
      'created_at_timestamp': org.createdAtTimestamp.toIso8601String(),
      'updated_at_timestamp': org.updatedAtTimestamp.toIso8601String(),
    };
  }

  /// Converts a UserEntry to a map for Supabase upsert.
  Map<String, dynamic> _userToMap(UserEntry user) {
    return {
      'id': user.id,
      'organization_id': user.organizationId,
      'email': user.email,
      'display_name': user.displayName,
      'role': user.role,
      'avatar_url': user.avatarUrl,
      'is_active': user.isActive,
      'last_sign_in_at_timestamp':
          user.lastSignInAtTimestamp?.toIso8601String(),
      'sync_version': user.syncVersion,
      'is_deleted': user.isDeleted,
      'deleted_at_timestamp': user.deletedAtTimestamp?.toIso8601String(),
      'is_demo_data': user.isDemoData,
      'created_at_timestamp': user.createdAtTimestamp.toIso8601String(),
      'updated_at_timestamp': user.updatedAtTimestamp.toIso8601String(),
    };
  }

  /// Converts a remote map to OrganizationsCompanion for insertion/update.
  OrganizationsCompanion _mapToOrganizationsCompanion(
      Map<String, dynamic> map) {
    return OrganizationsCompanion(
      id: Value(map['id'] as String),
      name: Value(map['name'] as String),
      slug: Value(map['slug'] as String),
      subscriptionTier: Value(map['subscription_tier'] as String? ?? 'free'),
      subscriptionStatus:
          Value(map['subscription_status'] as String? ?? 'active'),
      maxTournamentsPerMonth:
          Value(map['max_tournaments_per_month'] as int? ?? 2),
      maxActiveBrackets: Value(map['max_active_brackets'] as int? ?? 3),
      maxParticipantsPerBracket:
          Value(map['max_participants_per_bracket'] as int? ?? 32),
      maxParticipantsPerTournament:
          Value(map['max_participants_per_tournament'] as int? ?? 100),
      maxScorers: Value(map['max_scorers'] as int? ?? 2),
      isActive: Value(map['is_active'] as bool? ?? true),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp: Value(
          _parseDateTime(map['created_at_timestamp']) ?? DateTime.now()),
      updatedAtTimestamp: Value(
          _parseDateTime(map['updated_at_timestamp']) ?? DateTime.now()),
    );
  }

  /// Converts a remote map to UsersCompanion for insertion/update.
  UsersCompanion _mapToUsersCompanion(Map<String, dynamic> map) {
    return UsersCompanion(
      id: Value(map['id'] as String),
      organizationId: Value(map['organization_id'] as String),
      email: Value(map['email'] as String),
      displayName: Value(map['display_name'] as String),
      role: Value(map['role'] as String? ?? 'viewer'),
      avatarUrl: Value(map['avatar_url'] as String?),
      isActive: Value(map['is_active'] as bool? ?? true),
      lastSignInAtTimestamp:
          Value(_parseDateTime(map['last_sign_in_at_timestamp'])),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp: Value(
          _parseDateTime(map['created_at_timestamp']) ?? DateTime.now()),
      updatedAtTimestamp: Value(
          _parseDateTime(map['updated_at_timestamp']) ?? DateTime.now()),
    );
  }

  /// Parses a nullable ISO 8601 date string.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
