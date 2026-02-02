import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/services/logger_service.dart';

class MockLoggerService extends Mock implements LoggerService {}

void main() {
  late ErrorReportingService errorReportingService;
  late MockLoggerService mockLoggerService;

  setUp(() {
    mockLoggerService = MockLoggerService();
    errorReportingService = ErrorReportingService(mockLoggerService);
  });

  group('reportFailure', () {
    test('should log warning with failure type and message', () {
      const failure = ServerConnectionFailure(
        userFriendlyMessage: 'Cannot connect',
      );

      errorReportingService.reportFailure(failure);

      verify(
        () => mockLoggerService.warning(
          'Failure: ServerConnectionFailure - Cannot connect',
        ),
      ).called(1);
    });

    test('should log technicalDetails when present', () {
      const failure = ServerConnectionFailure(
        userFriendlyMessage: 'Cannot connect',
        technicalDetails: 'Timeout after 30s',
      );

      errorReportingService.reportFailure(failure);

      verify(
        () => mockLoggerService.warning(any()),
      ).called(1);
      verify(
        () => mockLoggerService.error('Technical details: Timeout after 30s'),
      ).called(1);
    });

    test('should not log technicalDetails when null', () {
      const failure = ServerConnectionFailure();

      errorReportingService.reportFailure(failure);

      verify(() => mockLoggerService.warning(any())).called(1);
      verifyNever(() => mockLoggerService.error(any(), any(), any()));
    });

    test('should handle InputValidationFailure', () {
      const failure = InputValidationFailure(
        userFriendlyMessage: 'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );

      errorReportingService.reportFailure(failure);

      verify(
        () => mockLoggerService.warning(
          'Failure: InputValidationFailure - Validation failed',
        ),
      ).called(1);
    });
  });

  group('reportException', () {
    test('should log exception with type and stack trace', () {
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;

      errorReportingService.reportException(exception, stackTrace);

      verify(
        () => mockLoggerService.error(
          'Exception: _Exception',
          exception,
          stackTrace,
        ),
      ).called(1);
    });

    test('should include context prefix when provided', () {
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;

      errorReportingService.reportException(
        exception,
        stackTrace,
        context: 'TournamentRepository',
      );

      verify(
        () => mockLoggerService.error(
          '[TournamentRepository] Exception: _Exception',
          exception,
          stackTrace,
        ),
      ).called(1);
    });
  });

  group('reportError', () {
    test('should log error message', () {
      errorReportingService.reportError('Something went wrong');

      verify(
        () => mockLoggerService.error('Something went wrong', null, null),
      ).called(1);
    });

    test('should log error with optional error object', () {
      final error = Exception('Error details');

      errorReportingService.reportError(
        'Something went wrong',
        error: error,
      );

      verify(
        () => mockLoggerService.error('Something went wrong', error, null),
      ).called(1);
    });

    test('should log error with optional stack trace', () {
      final stackTrace = StackTrace.current;

      errorReportingService.reportError(
        'Something went wrong',
        stackTrace: stackTrace,
      );

      verify(
        () => mockLoggerService.error('Something went wrong', null, stackTrace),
      ).called(1);
    });

    test('should log error with both error and stack trace', () {
      final error = Exception('Error details');
      final stackTrace = StackTrace.current;

      errorReportingService.reportError(
        'Something went wrong',
        error: error,
        stackTrace: stackTrace,
      );

      verify(
        () => mockLoggerService.error(
          'Something went wrong',
          error,
          stackTrace,
        ),
      ).called(1);
    });
  });

  group('addBreadcrumb', () {
    test('should log breadcrumb message', () {
      errorReportingService.addBreadcrumb(message: 'User clicked button');

      verify(
        () => mockLoggerService.info('Breadcrumb: User clicked button'),
      ).called(1);
    });

    test('should include category prefix when provided', () {
      errorReportingService.addBreadcrumb(
        message: 'User clicked button',
        category: 'ui',
      );

      verify(
        () => mockLoggerService.info('Breadcrumb: [ui] User clicked button'),
      ).called(1);
    });
  });

  group('setUserContext', () {
    test('should log user context info', () {
      errorReportingService.setUserContext(
        userId: 'user-123',
        email: 'user@example.com',
        organizationId: 'org-456',
      );

      verify(
        () => mockLoggerService.info(
          'User context set: userId=user-123, orgId=org-456',
        ),
      ).called(1);
    });

    test('should handle null organizationId', () {
      errorReportingService.setUserContext(
        userId: 'user-123',
      );

      verify(
        () => mockLoggerService.info(
          'User context set: userId=user-123, orgId=null',
        ),
      ).called(1);
    });
  });

  group('clearUserContext', () {
    test('should log context cleared', () {
      errorReportingService.clearUserContext();

      verify(
        () => mockLoggerService.info('User context cleared'),
      ).called(1);
    });
  });
}
