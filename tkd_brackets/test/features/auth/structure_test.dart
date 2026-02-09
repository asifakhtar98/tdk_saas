import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests that verify the auth feature directory structure exists.
///
/// **IMPORTANT**: These tests must be run from the `tkd_brackets/` directory
/// as they use relative paths to check the lib/ structure.
///
/// ```bash
/// cd tkd_brackets
/// flutter test test/features/auth/structure_test.dart
/// ```

void expectDirectoryExists(String path) {
  expect(Directory(path).existsSync(), isTrue, reason: '$path should exist');
}

void expectFileExists(String path) {
  expect(File(path).existsSync(), isTrue, reason: '$path should exist');
}

void main() {
  group('Auth Feature Structure', () {
    test('data layer directories exist', () {
      expectDirectoryExists('lib/features/auth/data/datasources');
      expectDirectoryExists('lib/features/auth/data/models');
      expectDirectoryExists('lib/features/auth/data/repositories');
    });

    test('domain layer directories exist', () {
      expectDirectoryExists('lib/features/auth/domain/entities');
      expectDirectoryExists('lib/features/auth/domain/repositories');
      expectDirectoryExists('lib/features/auth/domain/usecases');
    });

    test('presentation layer directories exist', () {
      expectDirectoryExists('lib/features/auth/presentation/bloc');
      expectDirectoryExists('lib/features/auth/presentation/pages');
      expectDirectoryExists('lib/features/auth/presentation/widgets');
    });

    test('barrel file exists', () {
      expectFileExists('lib/features/auth/auth.dart');
    });
  });
}
