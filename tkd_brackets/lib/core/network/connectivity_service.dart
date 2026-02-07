import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:tkd_brackets/core/network/connectivity_status.dart';

/// Abstract interface for connectivity monitoring.
///
/// Provides real-time connectivity status updates and point-in-time checks.
/// Used by sync services to determine online/offline behavior.
abstract class ConnectivityService {
  /// Stream of connectivity status changes.
  ///
  /// Emits a new [ConnectivityStatus] whenever the network state changes.
  /// Subscribe to this stream to react to connectivity changes in real-time.
  Stream<ConnectivityStatus> get statusStream;

  /// Current connectivity status.
  ///
  /// Returns the last known connectivity status. May not reflect the
  /// absolute current state if a status change is in progress.
  ConnectivityStatus get currentStatus;

  /// Checks if the device currently has internet connectivity.
  ///
  /// Performs an actual connectivity check (not just network interface status).
  /// Use this for point-in-time checks before critical
  /// operations.
  ///
  /// Returns `true` if internet is reachable, `false` otherwise.
  Future<bool> hasInternetConnection();

  /// Disposes of resources and subscriptions.
  ///
  /// Call this when the service is no longer needed
  /// (typically on app shutdown).
  void dispose();
}

/// Implementation of [ConnectivityService] using connectivity_plus
/// and internet_connection_checker_plus packages.
///
/// This service:
/// - Monitors network interface changes via [Connectivity]
/// - Verifies actual internet reachability via [InternetConnection]
/// - Provides both stream-based and point-in-time connectivity checks
@LazySingleton(as: ConnectivityService)
class ConnectivityServiceImplementation implements ConnectivityService {
  ConnectivityServiceImplementation(
    this._connectivity,
    this._internetConnection,
  ) {
    _initialize();
  }

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.offline;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  @override
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  @override
  ConnectivityStatus get currentStatus => _currentStatus;

  void _initialize() {
    // Listen to network interface changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Listen to internet reachability changes
    _internetSubscription = _internetConnection.onStatusChange.listen(
      _handleInternetStatusChange,
    );

    // Perform initial check
    _performInitialCheck();
  }

  Future<void> _performInitialCheck() async {
    try {
      final hasInternet = await hasInternetConnection();
      _updateStatus(
        hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline,
      );
    } on Object {
      // If initial check fails for any reason (Exception or Error),
      // assume offline
      _updateStatus(ConnectivityStatus.offline);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // If no connectivity at all, we're definitely offline
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _updateStatus(ConnectivityStatus.offline);
      return;
    }

    // We have network interface, but need to verify internet reachability
    // The internet subscription will handle the actual status update
    _checkAndUpdateStatus().catchError((_) {
      // If connectivity check fails, assume offline
      _updateStatus(ConnectivityStatus.offline);
    });
  }

  void _handleInternetStatusChange(InternetStatus status) {
    switch (status) {
      case InternetStatus.connected:
        _updateStatus(ConnectivityStatus.online);
      case InternetStatus.disconnected:
        _updateStatus(ConnectivityStatus.offline);
    }
  }

  Future<void> _checkAndUpdateStatus() async {
    final hasInternet = await hasInternetConnection();
    _updateStatus(
      hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline,
    );
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    return _internetConnection.hasInternetAccess;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _statusController.close();
  }
}
