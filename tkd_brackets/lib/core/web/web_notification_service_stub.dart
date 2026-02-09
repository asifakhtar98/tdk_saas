/// Stub for non-web platforms.
/// Does nothing since this is only needed for web.
abstract class WebNotificationService {
  /// Notifies the web page that Flutter has fully initialized.
  /// On non-web platforms, this is a no-op.
  static void notifyFlutterReady() {
    // No-op on native platforms
  }
}
