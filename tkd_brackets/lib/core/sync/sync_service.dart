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
  static const List<String> _syncableTables = [
    'organizations',
    'users',
    'tournaments',
    'divisions',
    'participants',
  ];

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
          } else {
            // Exhausted all retry attempts — mark as permanently failed
            // so it doesn't stay in the queue indefinitely.
            await _syncQueue.markFailed(
              item.id,
              'Exhausted $_maxRetryAttempts retry attempts: $e',
            );
            failedCount++;
            _errorReportingService.reportError(
              'Sync item ${item.id} exhausted retries for ${item.tableName_}',
              error: e,
            );
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
            tableName,
            recordId,
            remoteSyncVersion,
          )) {
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
        final orgs = await (_appDatabase.select(
          _appDatabase.organizations,
        )..where((o) => o.id.isIn(recordIds))).get();
        return orgs.map(_organizationToMap).toList();
      case 'users':
        final users = await (_appDatabase.select(
          _appDatabase.users,
        )..where((u) => u.id.isIn(recordIds))).get();
        return users.map(_userToMap).toList();
      case 'tournaments':
        final ts = await (_appDatabase.select(_appDatabase.tournaments)
              ..where((t) => t.id.isIn(recordIds)))
            .get();
        return ts.map(_tournamentToMap).toList();
      case 'divisions':
        final ds = await (_appDatabase.select(_appDatabase.divisions)
              ..where((d) => d.id.isIn(recordIds)))
            .get();
        return ds.map(_divisionToMap).toList();
      case 'participants':
        final ps = await (_appDatabase.select(_appDatabase.participants)
              ..where((p) => p.id.isIn(recordIds)))
            .get();
        return ps.map(_participantToMap).toList();
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
      case 'tournaments':
        final t = await _appDatabase.getTournamentById(recordId);
        if (t != null) return _tournamentToMap(t);
      case 'divisions':
        final d = await _appDatabase.getDivisionById(recordId);
        if (d != null) return _divisionToMap(d);
      case 'participants':
        final p = await _appDatabase.getParticipantById(recordId);
        if (p != null) return _participantToMap(p);
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
      case 'tournaments':
        await _applyRemoteTournament(remote);
      case 'divisions':
        await _applyRemoteDivision(remote);
      case 'participants':
        await _applyRemoteParticipant(remote);
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
    } else if ((remote['sync_version'] as int? ?? 0) > existing.syncVersion) {
      // Update existing if remote is newer
      await (_appDatabase.update(
        _appDatabase.users,
      )..where((u) => u.id.equals(id))).write(_mapToUsersCompanion(remote));
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
      'last_sign_in_at_timestamp': user.lastSignInAtTimestamp
          ?.toIso8601String(),
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
    Map<String, dynamic> map,
  ) {
    return OrganizationsCompanion(
      id: Value(map['id'] as String),
      name: Value(map['name'] as String),
      slug: Value(map['slug'] as String),
      subscriptionTier: Value(map['subscription_tier'] as String? ?? 'free'),
      subscriptionStatus: Value(
        map['subscription_status'] as String? ?? 'active',
      ),
      maxTournamentsPerMonth: Value(
        map['max_tournaments_per_month'] as int? ?? 2,
      ),
      maxActiveBrackets: Value(map['max_active_brackets'] as int? ?? 3),
      maxParticipantsPerBracket: Value(
        map['max_participants_per_bracket'] as int? ?? 32,
      ),
      maxParticipantsPerTournament: Value(
        map['max_participants_per_tournament'] as int? ?? 100,
      ),
      maxScorers: Value(map['max_scorers'] as int? ?? 2),
      isActive: Value(map['is_active'] as bool? ?? true),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp: Value(
        _parseDateTime(map['created_at_timestamp']) ?? DateTime.now(),
      ),
      updatedAtTimestamp: Value(
        _parseDateTime(map['updated_at_timestamp']) ?? DateTime.now(),
      ),
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
      lastSignInAtTimestamp: Value(
        _parseDateTime(map['last_sign_in_at_timestamp']),
      ),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp: Value(
        _parseDateTime(map['created_at_timestamp']) ?? DateTime.now(),
      ),
      updatedAtTimestamp: Value(
        _parseDateTime(map['updated_at_timestamp']) ?? DateTime.now(),
      ),
    );
  }

  Future<void> _applyRemoteTournament(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final existing = await _appDatabase.getTournamentById(id);

    if (existing == null) {
      await _appDatabase.insertTournament(_mapToTournamentsCompanion(remote));
    } else {
      await (_appDatabase.update(_appDatabase.tournaments)
            ..where((t) => t.id.equals(id)))
          .write(_mapToTournamentsCompanion(remote));
    }
  }

  Future<void> _applyRemoteDivision(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final existing = await _appDatabase.getDivisionById(id);

    if (existing == null) {
      await _appDatabase.insertDivision(_mapToDivisionsCompanion(remote));
    } else {
      await (_appDatabase.update(_appDatabase.divisions)
            ..where((d) => d.id.equals(id)))
          .write(_mapToDivisionsCompanion(remote));
    }
  }

  Future<void> _applyRemoteParticipant(Map<String, dynamic> remote) async {
    final id = remote['id'] as String;
    final existing = await _appDatabase.getParticipantById(id);

    if (existing == null) {
      await _appDatabase.insertParticipant(_mapToParticipantsCompanion(remote));
    } else {
      await (_appDatabase.update(_appDatabase.participants)
            ..where((p) => p.id.equals(id)))
          .write(_mapToParticipantsCompanion(remote));
    }
  }

  /// Converts a TournamentEntry to a map for Supabase upsert.
  Map<String, dynamic> _tournamentToMap(TournamentEntry tournament) {
    return {
      'id': tournament.id,
      'organization_id': tournament.organizationId,
      'name': tournament.name,
      'description': tournament.description,
      'scheduled_date': tournament.scheduledDate?.toIso8601String(),
      'status': tournament.status,
      'venue_name': tournament.venueName,
      'venue_address': tournament.venueAddress,
      'is_template': tournament.isTemplate,
      'template_id': tournament.templateId,
      'number_of_rings': tournament.numberOfRings,
      'settings_json': tournament.settingsJson,
      'sync_version': tournament.syncVersion,
      'is_deleted': tournament.isDeleted,
      'deleted_at_timestamp': tournament.deletedAtTimestamp?.toIso8601String(),
      'is_demo_data': tournament.isDemoData,
      'created_at_timestamp': tournament.createdAtTimestamp.toIso8601String(),
      'updated_at_timestamp': tournament.updatedAtTimestamp.toIso8601String(),
    };
  }

  /// Converts a DivisionEntry to a map for Supabase upsert.
  Map<String, dynamic> _divisionToMap(DivisionEntry division) {
    return {
      'id': division.id,
      'tournament_id': division.tournamentId,
      'name': division.name,
      'category': division.category,
      'age_min': division.ageMin,
      'age_max': division.ageMax,
      'gender': division.gender,
      'weight_min_kg': division.weightMinKg,
      'weight_max_kg': division.weightMaxKg,
      'belt_rank_min': division.beltRankMin,
      'belt_rank_max': division.beltRankMax,
      'bracket_format': division.bracketFormat,
      'status': division.status,
      'is_combined': division.isCombined,
      'is_custom': division.isCustom,
      'assigned_ring_number': division.assignedRingNumber,
      'display_order': division.displayOrder,
      'sync_version': division.syncVersion,
      'is_deleted': division.isDeleted,
      'deleted_at_timestamp': division.deletedAtTimestamp?.toIso8601String(),
      'is_demo_data': division.isDemoData,
      'created_at_timestamp': division.createdAtTimestamp.toIso8601String(),
      'updated_at_timestamp': division.updatedAtTimestamp.toIso8601String(),
    };
  }

  /// Converts a remote map to TournamentsCompanion.
   TournamentsCompanion _mapToTournamentsCompanion(Map<String, dynamic> map) {
    return TournamentsCompanion(
      id: Value(map['id'] as String),
      organizationId: Value(map['organization_id'] as String),
      name: Value(map['name'] as String),
      description: Value(map['description'] as String?),
      scheduledDate: Value(_parseDateTime(map['scheduled_date']) ?? DateTime.now()),
      status: Value(map['status'] as String? ?? 'draft'),
      venueName: Value(map['venue_name'] as String?),
      venueAddress: Value(map['venue_address'] as String?),
      isTemplate: Value(map['is_template'] as bool? ?? false),
      templateId: Value(map['template_id'] as String?),
      numberOfRings: Value(map['number_of_rings'] as int? ?? 1),
      settingsJson: Value(map['settings_json'] as String? ?? '{}'),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp: Value(_parseDateTime(map['created_at_timestamp']) ?? DateTime.now()),
      updatedAtTimestamp: Value(_parseDateTime(map['updated_at_timestamp']) ?? DateTime.now()),
    );
  }

  /// Converts a remote map to DivisionsCompanion.
  DivisionsCompanion _mapToDivisionsCompanion(Map<String, dynamic> map) {
    return DivisionsCompanion(
      id: Value(map['id'] as String),
      tournamentId: Value(map['tournament_id'] as String),
      name: Value(map['name'] as String),
      category: Value(map['category'] as String),
      ageMin: Value(map['age_min'] as int?),
      ageMax: Value(map['age_max'] as int?),
      gender: Value(map['gender'] as String),
      weightMinKg: Value(map['weight_min_kg'] != null ? (map['weight_min_kg'] as num).toDouble() : null),
      weightMaxKg: Value(map['weight_max_kg'] != null ? (map['weight_max_kg'] as num).toDouble() : null),
      beltRankMin: Value(map['belt_rank_min'] as String?),
      beltRankMax: Value(map['belt_rank_max'] as String?),
      bracketFormat: Value(map['bracket_format'] as String? ?? 'single_elimination'),
      status: Value(map['status'] as String? ?? 'setup'),
      isCombined: Value(map['is_combined'] as bool? ?? false),
      isCustom: Value(map['is_custom'] as bool? ?? false),
      assignedRingNumber: Value(map['assigned_ring_number'] as int?),
      displayOrder: Value(map['display_order'] as int? ?? 0),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp: Value(_parseDateTime(map['created_at_timestamp']) ?? DateTime.now()),
      updatedAtTimestamp: Value(_parseDateTime(map['updated_at_timestamp']) ?? DateTime.now()),
    );
  }

  /// Parses a nullable ISO 8601 date string.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Converts a ParticipantEntry to a map for Supabase upsert.
  Map<String, dynamic> _participantToMap(ParticipantEntry participant) {
    return {
      'id': participant.id,
      'division_id': participant.divisionId,
      'first_name': participant.firstName,
      'last_name': participant.lastName,
      'date_of_birth': participant.dateOfBirth?.toIso8601String(),
      'gender': participant.gender,
      'weight_kg': participant.weightKg,
      'school_or_dojang_name': participant.schoolOrDojangName,
      'belt_rank': participant.beltRank,
      'seed_number': participant.seedNumber,
      'registration_number': participant.registrationNumber,
      'is_bye': participant.isBye,
      'check_in_status': participant.checkInStatus,
      'check_in_at_timestamp': participant.checkInAtTimestamp?.toIso8601String(),
      'dq_reason': participant.dqReason,
      'photo_url': participant.photoUrl,
      'notes': participant.notes,
      'sync_version': participant.syncVersion,
      'is_deleted': participant.isDeleted,
      'deleted_at_timestamp': participant.deletedAtTimestamp?.toIso8601String(),
      'is_demo_data': participant.isDemoData,
      'created_at_timestamp': participant.createdAtTimestamp.toIso8601String(),
      'updated_at_timestamp': participant.updatedAtTimestamp.toIso8601String(),
    };
  }

  /// Converts a remote map to ParticipantsCompanion.
  ParticipantsCompanion _mapToParticipantsCompanion(Map<String, dynamic> map) {
    return ParticipantsCompanion(
      id: Value(map['id'] as String),
      divisionId: Value(map['division_id'] as String),
      firstName: Value(map['first_name'] as String),
      lastName: Value(map['last_name'] as String),
      dateOfBirth: Value(_parseDateTime(map['date_of_birth'])),
      gender: Value(map['gender'] as String?),
      weightKg: Value(map['weight_kg'] != null ? (map['weight_kg'] as num).toDouble() : null),
      schoolOrDojangName: Value(map['school_or_dojang_name'] as String?),
      beltRank: Value(map['belt_rank'] as String?),
      seedNumber: Value(map['seed_number'] as int?),
      registrationNumber: Value(map['registration_number'] as String?),
      isBye: Value(map['is_bye'] as bool? ?? false),
      checkInStatus: Value(map['check_in_status'] as String? ?? 'pending'),
      checkInAtTimestamp: Value(_parseDateTime(map['check_in_at_timestamp'])),
      dqReason: Value(map['dq_reason'] as String?),
      photoUrl: Value(map['photo_url'] as String?),
      notes: Value(map['notes'] as String?),
      syncVersion: Value(map['sync_version'] as int? ?? 1),
      isDeleted: Value(map['is_deleted'] as bool? ?? false),
      deletedAtTimestamp: Value(_parseDateTime(map['deleted_at_timestamp'])),
      isDemoData: Value(map['is_demo_data'] as bool? ?? false),
      createdAtTimestamp:
          Value(_parseDateTime(map['created_at_timestamp']) ?? DateTime.now()),
      updatedAtTimestamp:
          Value(_parseDateTime(map['updated_at_timestamp']) ?? DateTime.now()),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
