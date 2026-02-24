// This file uses web APIs which are only available on web platforms.
// The conditional import in web_notification.dart ensures this file is only
// loaded when running on web.

// Web-specific file: Conditionally imported only on web platforms.
// ignore_for_file: avoid_web_libraries_in_flutter, https://dart.dev/tools/analysis#ignoring-rules

import 'package:web/web.dart' as web;

/// Service to notify the web page that Flutter has initialized.
/// This is used for the SEO landing page integration.
abstract class WebNotificationService {
  /// Notifies the web page that Flutter has fully initialized.
  static void notifyFlutterReady() {
    // Dispatch a custom event that the landing page JavaScript listens for
    final event = web.CustomEvent(
      'flutter-initialized',
      web.CustomEventInit(bubbles: true, cancelable: false),
    );
    web.document.dispatchEvent(event);
  }
}
