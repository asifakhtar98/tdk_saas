import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/error/exceptions.dart';

void main() {
  group('AppException base class', () {
    test('should expose message property', () {
      const exception = ServerException(message: 'Server error');

      expect(exception.message, 'Server error');
    });

    test('should expose code property', () {
      const exception = ServerException(
        message: 'Server error',
        code: 'ERR_500',
      );

      expect(exception.code, 'ERR_500');
    });

    test('should expose originalError property', () {
      final originalError = Exception('Original');
      final exception = ServerException(
        message: 'Server error',
        originalError: originalError,
      );

      expect(exception.originalError, originalError);
    });

    test('should allow null code and originalError', () {
      const exception = ServerException(message: 'Server error');

      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('toString should include message and code', () {
      const exception = ServerException(
        message: 'Server error',
        code: 'ERR_500',
      );

      expect(
          exception.toString(), 'AppException: Server error (code: ERR_500)');
    });

    test('toString should handle null code', () {
      const exception = ServerException(message: 'Server error');

      expect(exception.toString(), 'AppException: Server error (code: null)');
    });
  });

  group('ServerException', () {
    test('should expose statusCode property', () {
      const exception = ServerException(
        message: 'Internal server error',
        statusCode: 500,
      );

      expect(exception.statusCode, 500);
    });

    test('should allow null statusCode', () {
      const exception = ServerException(message: 'Server error');

      expect(exception.statusCode, isNull);
    });
  });

  group('NetworkException', () {
    test('should have default message', () {
      const exception = NetworkException();

      expect(exception.message, 'Network connection unavailable');
    });

    test('should allow custom message', () {
      const exception = NetworkException(message: 'No internet');

      expect(exception.message, 'No internet');
    });
  });

  group('UnauthorizedException', () {
    test('should have default message and code', () {
      const exception = UnauthorizedException();

      expect(exception.message, 'Authentication required');
      expect(exception.code, '401');
    });
  });

  group('ForbiddenException', () {
    test('should have default message and code', () {
      const exception = ForbiddenException();

      expect(exception.message, 'Access denied');
      expect(exception.code, '403');
    });
  });

  group('CacheException', () {
    test('should require message', () {
      const exception = CacheException(message: 'Cache error');

      expect(exception.message, 'Cache error');
    });
  });

  group('CacheReadException', () {
    test('should have default message', () {
      const exception = CacheReadException();

      expect(exception.message, 'Failed to read from local cache');
    });

    test('should extend CacheException', () {
      const exception = CacheReadException();

      expect(exception, isA<CacheException>());
    });
  });

  group('CacheWriteException', () {
    test('should have default message', () {
      const exception = CacheWriteException();

      expect(exception.message, 'Failed to write to local cache');
    });

    test('should extend CacheException', () {
      const exception = CacheWriteException();

      expect(exception, isA<CacheException>());
    });
  });

  group('Exception hierarchy', () {
    test('all exceptions should implement Exception', () {
      expect(const ServerException(message: 'test'), isA<Exception>());
      expect(const NetworkException(), isA<Exception>());
      expect(const UnauthorizedException(), isA<Exception>());
      expect(const ForbiddenException(), isA<Exception>());
      expect(const CacheException(message: 'test'), isA<Exception>());
      expect(const CacheReadException(), isA<Exception>());
      expect(const CacheWriteException(), isA<Exception>());
    });

    test('CacheReadException should be a CacheException', () {
      const exception = CacheReadException();

      expect(exception, isA<CacheException>());
      expect(exception, isA<AppException>());
    });

    test('CacheWriteException should be a CacheException', () {
      const exception = CacheWriteException();

      expect(exception, isA<CacheException>());
      expect(exception, isA<AppException>());
    });
  });
}
