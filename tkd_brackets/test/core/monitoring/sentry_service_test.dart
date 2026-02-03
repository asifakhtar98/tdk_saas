import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/monitoring/sentry_service.dart';

/// Helper for empty appRunner callbacks.
Future<void> _emptyAppRunner() async {}

void main() {
  setUp(SentryService.resetForTesting);

  group('SentryService initialization', () {
    test('should report not initialized before initialize() called', () {
      expect(SentryService.isInitialized, false);
      expect(SentryService.isEnabled, false);
    });

    test('should throw StateError when initialized twice', () async {
      var appRunnerCalled = false;

      // First init with empty DSN (disabled mode - doesn't require real Sentry)
      await SentryService.initialize(
        dsn: '',
        environment: 'test',
        appRunner: () async {
          appRunnerCalled = true;
        },
      );

      expect(appRunnerCalled, true);
      expect(SentryService.isInitialized, true);

      // Second init should throw
      expect(
        () => SentryService.initialize(
          dsn: '',
          environment: 'test',
          appRunner: _emptyAppRunner,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('called more than once'),
          ),
        ),
      );
    });

    test('should be disabled when DSN is empty', () async {
      await SentryService.initialize(
        dsn: '',
        environment: 'development',
        appRunner: _emptyAppRunner,
      );

      expect(SentryService.isInitialized, true);
      expect(SentryService.isEnabled, false);
    });

    test('should call appRunner when DSN is empty', () async {
      var appRunnerCalled = false;

      await SentryService.initialize(
        dsn: '',
        environment: 'development',
        appRunner: () async {
          appRunnerCalled = true;
        },
      );

      expect(appRunnerCalled, true);
    });
  });

  group('SentryService methods with disabled state', () {
    setUp(() async {
      // Initialize in disabled mode
      await SentryService.initialize(
        dsn: '',
        environment: 'test',
        appRunner: _emptyAppRunner,
      );
    });

    test('captureException should be no-op when disabled', () async {
      // Should not throw
      await SentryService.captureException(
        Exception('test'),
        stackTrace: StackTrace.current,
      );
    });

    test('captureMessage should be no-op when disabled', () async {
      // Should not throw
      await SentryService.captureMessage('test message');
    });

    test('addBreadcrumb should be no-op when disabled', () {
      // Should not throw
      SentryService.addBreadcrumb(
        message: 'test breadcrumb',
        category: 'test',
      );
    });

    test('setUserContext should be no-op when disabled', () {
      // Should not throw
      SentryService.setUserContext(
        userId: 'user-123',
        email: 'test@example.com',
      );
    });

    test('clearUserContext should be no-op when disabled', () {
      // Should not throw
      expect(SentryService.clearUserContext, returnsNormally);
    });
  });

  group('SentryService resetForTesting', () {
    test('should reset all state', () async {
      await SentryService.initialize(
        dsn: '',
        environment: 'test',
        appRunner: _emptyAppRunner,
      );

      expect(SentryService.isInitialized, true);

      SentryService.resetForTesting();

      expect(SentryService.isInitialized, false);
      expect(SentryService.isEnabled, false);
    });
  });

  // Note: Tests with real Sentry DSN require integration test setup.
  // The unit tests above validate the guard logic and disabled-mode behavior.
  //
  // For integration testing with actual Sentry:
  // 1. Create a test Sentry project
  // 2. Use environment variables for DSN
  // 3. Run as integration tests (flutter test integration_test/)
}
