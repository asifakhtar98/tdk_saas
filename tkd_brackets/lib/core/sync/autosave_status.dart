/// Represents the current state of the autosave service.
///
/// Used to communicate the save state throughout the application.
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
