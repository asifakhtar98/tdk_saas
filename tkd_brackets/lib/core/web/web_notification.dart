// Conditional export for WebNotificationService.
// Uses the web implementation on web, stub on native platforms.
export 'web_notification_service_stub.dart'
    if (dart.library.html) 'web_notification_service.dart'
    if (dart.library.js_interop) 'web_notification_service.dart';
