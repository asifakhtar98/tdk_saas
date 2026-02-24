import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:tkd_brackets/core/di/environment.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/services/logger_service.dart';

void main() {
  setUp(() {
    // Reset GetIt between tests
    GetIt.instance.reset();
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('Dependency Injection Configuration', () {
    test('should initialize GetIt container without errors', () {
      // Act & Assert
      expect(() => configureDependencies(dev.name), returnsNormally);
    });

    test('should initialize with staging environment without errors', () {
      // Act & Assert
      expect(() => configureDependencies(staging.name), returnsNormally);
    });

    test('should initialize with production environment without errors', () {
      // Act & Assert
      expect(() => configureDependencies(prod.name), returnsNormally);
    });

    test('should resolve LoggerService after initialization', () {
      // Arrange
      configureDependencies(dev.name);

      // Act
      final logger = getIt<LoggerService>();

      // Assert
      expect(logger, isA<LoggerService>());
    });

    test('should return same instance for lazy singletons', () {
      // Arrange
      configureDependencies(dev.name);

      // Act
      final logger1 = getIt<LoggerService>();
      final logger2 = getIt<LoggerService>();

      // Assert
      expect(identical(logger1, logger2), isTrue);
    });

    test('LoggerService info method should not throw', () {
      // Arrange
      configureDependencies(dev.name);
      final logger = getIt<LoggerService>();

      // Act & Assert
      expect(() => logger.info('Test info message'), returnsNormally);
    });

    test('LoggerService warning method should not throw', () {
      // Arrange
      configureDependencies(dev.name);
      final logger = getIt<LoggerService>();

      // Act & Assert
      expect(() => logger.warning('Test warning message'), returnsNormally);
    });

    test('LoggerService error method should not throw', () {
      // Arrange
      configureDependencies(dev.name);
      final logger = getIt<LoggerService>();

      // Act & Assert
      expect(
        () => logger.error('Test error', Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
