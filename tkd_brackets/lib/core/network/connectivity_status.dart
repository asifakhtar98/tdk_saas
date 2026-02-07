/// Represents the current connectivity status of the application.
///
/// Used by ConnectivityService to communicate network state changes
/// throughout the application, particularly for offline-first sync decisions.
enum ConnectivityStatus {
  /// Device has internet connectivity and can reach external servers.
  online,

  /// Device has no network connectivity or cannot reach external servers.
  offline,

  /// Device has connectivity but connection is slow or unstable.
  /// Useful for optimizing sync behavior (e.g., defer large uploads).
  slow,
}
