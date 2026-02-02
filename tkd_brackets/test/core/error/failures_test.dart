import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/error/failures.dart';

void main() {
  group('Failure base class', () {
    test('should be equal when properties match', () {
      const failure1 = ServerConnectionFailure();
      const failure2 = ServerConnectionFailure();

      expect(failure1, equals(failure2));
    });

    test('should not be equal when properties differ', () {
      const failure1 = ServerConnectionFailure(
        technicalDetails: 'Connection timeout',
      );
      const failure2 = ServerConnectionFailure(
        technicalDetails: 'DNS resolution failed',
      );

      expect(failure1, isNot(equals(failure2)));
    });

    test('should expose userFriendlyMessage property', () {
      const failure = ServerConnectionFailure(
        userFriendlyMessage: 'Custom message',
      );

      expect(failure.userFriendlyMessage, 'Custom message');
    });

    test('should expose technicalDetails property', () {
      const failure = ServerConnectionFailure(
        technicalDetails: 'Error code XYZ',
      );

      expect(failure.technicalDetails, 'Error code XYZ');
    });

    test('should allow null technicalDetails', () {
      const failure = ServerConnectionFailure();

      expect(failure.technicalDetails, isNull);
    });
  });

  group('ServerConnectionFailure', () {
    test('should have default userFriendlyMessage', () {
      const failure = ServerConnectionFailure();

      expect(
        failure.userFriendlyMessage,
        'Unable to connect to server. Please check your internet connection.',
      );
    });

    test('should allow custom userFriendlyMessage', () {
      const failure = ServerConnectionFailure(
        userFriendlyMessage: 'Server unavailable',
      );

      expect(failure.userFriendlyMessage, 'Server unavailable');
    });
  });

  group('ServerResponseFailure', () {
    test('should require userFriendlyMessage', () {
      const failure = ServerResponseFailure(
        userFriendlyMessage: 'Something went wrong',
        statusCode: 500,
      );

      expect(failure.userFriendlyMessage, 'Something went wrong');
      expect(failure.statusCode, 500);
    });

    test('should include statusCode in equality', () {
      const failure1 = ServerResponseFailure(
        userFriendlyMessage: 'Error',
        statusCode: 404,
      );
      const failure2 = ServerResponseFailure(
        userFriendlyMessage: 'Error',
        statusCode: 500,
      );

      expect(failure1, isNot(equals(failure2)));
    });

    test('should allow null statusCode', () {
      const failure = ServerResponseFailure(
        userFriendlyMessage: 'Unknown error',
      );

      expect(failure.statusCode, isNull);
    });
  });

  group('LocalCacheAccessFailure', () {
    test('should have default userFriendlyMessage', () {
      const failure = LocalCacheAccessFailure();

      expect(failure.userFriendlyMessage, 'Unable to access local storage.');
    });
  });

  group('LocalCacheWriteFailure', () {
    test('should have default userFriendlyMessage', () {
      const failure = LocalCacheWriteFailure();

      expect(failure.userFriendlyMessage, 'Unable to save data locally.');
    });
  });

  group('DataSynchronizationFailure', () {
    test('should have default userFriendlyMessage', () {
      const failure = DataSynchronizationFailure();

      expect(
        failure.userFriendlyMessage,
        'Unable to sync data. Changes saved locally.',
      );
    });
  });

  group('InputValidationFailure', () {
    test('should require userFriendlyMessage and fieldErrors', () {
      const failure = InputValidationFailure(
        userFriendlyMessage: 'Validation failed',
        fieldErrors: {'email': 'Invalid email format'},
      );

      expect(failure.userFriendlyMessage, 'Validation failed');
      expect(failure.fieldErrors, {'email': 'Invalid email format'});
    });

    test('should include fieldErrors in equality', () {
      const failure1 = InputValidationFailure(
        userFriendlyMessage: 'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );
      const failure2 = InputValidationFailure(
        userFriendlyMessage: 'Validation failed',
        fieldErrors: {'name': 'Required'},
      );

      expect(failure1, isNot(equals(failure2)));
    });

    test('should handle empty fieldErrors', () {
      const failure = InputValidationFailure(
        userFriendlyMessage: 'Validation failed',
        fieldErrors: {},
      );

      expect(failure.fieldErrors, isEmpty);
    });

    test('should handle multiple field errors', () {
      const failure = InputValidationFailure(
        userFriendlyMessage: 'Validation failed',
        fieldErrors: {
          'email': 'Invalid email',
          'password': 'Too short',
          'name': 'Required',
        },
      );

      expect(failure.fieldErrors.length, 3);
      expect(failure.fieldErrors['email'], 'Invalid email');
      expect(failure.fieldErrors['password'], 'Too short');
      expect(failure.fieldErrors['name'], 'Required');
    });
  });

  group('AuthenticationSessionExpiredFailure', () {
    test('should have default userFriendlyMessage', () {
      const failure = AuthenticationSessionExpiredFailure();

      expect(
        failure.userFriendlyMessage,
        'Your session has expired. Please sign in again.',
      );
    });
  });

  group('AuthorizationPermissionDeniedFailure', () {
    test('should have default userFriendlyMessage', () {
      const failure = AuthorizationPermissionDeniedFailure();

      expect(
        failure.userFriendlyMessage,
        'You do not have permission to perform this action.',
      );
    });
  });
}
