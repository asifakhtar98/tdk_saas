import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests that verify the bracket feature structure and
/// Clean Architecture compliance.
///
/// **IMPORTANT**: These tests must be run from the `tkd_brackets/` directory
/// as they use relative paths to check the lib/ structure.
///
/// ```bash
/// cd tkd_brackets
/// flutter test test/features/bracket/structure_test.dart
/// ```

void main() {
  group('Bracket Feature Structure', () {
    const basePath = 'lib/features/bracket';

    test('should have all required directories', () {
      final directories = [
        '$basePath/data/datasources',
        '$basePath/data/models',
        '$basePath/data/repositories',
        '$basePath/domain/entities',
        '$basePath/domain/repositories',
        '$basePath/domain/usecases',
        '$basePath/presentation/bloc',
        '$basePath/presentation/pages',
        '$basePath/presentation/widgets',
      ];

      for (final dir in directories) {
        expect(
          Directory(dir).existsSync(),
          isTrue,
          reason: 'Directory $dir should exist',
        );
      }
    });

    test('should have barrel file', () {
      expect(
        File('$basePath/bracket.dart').existsSync(),
        isTrue,
        reason: 'Barrel file should exist',
      );
    });

    test('should have README', () {
      expect(
        File('$basePath/README.md').existsSync(),
        isTrue,
        reason: 'README should exist',
      );
    });

    test('barrel file should have twenty-two export statements', () {
      final barrelFile = File('$basePath/bracket.dart');
      final content = barrelFile.readAsStringSync();

      // Count occurrences of "export '"
      final matches = RegExp("export '").allMatches(content);

      expect(
        matches.length,
        22,
        reason: 'Barrel file should have twenty-two exports for bracket & match entity & repo + services + usecases',
      );
    });

    group('Clean Architecture Compliance', () {
      test('domain layer should not contain data imports', () {
        final domainDir = Directory('$basePath/domain');
        if (domainDir.existsSync()) {
          final dartFiles = domainDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'));

          for (final file in dartFiles) {
            final content = file.readAsStringSync();
            expect(
              content.contains("import '../data/") ||
                  content.contains('import "../data/') ||
                  content.contains("import 'package:drift") ||
                  content.contains("import 'package:supabase_flutter"),
              isFalse,
              reason:
                  'Domain file ${file.path} should not '
                  'import data layer or infrastructure',
            );
          }
        }
      });

      test('barrel file should have organized export sections', () {
        final barrelFile = File('$basePath/bracket.dart');
        final content = barrelFile.readAsStringSync();

        expect(
          content.contains('// Data exports'),
          isTrue,
          reason: 'Barrel file should have Data exports section',
        );
        expect(
          content.contains('// Domain exports'),
          isTrue,
          reason: 'Barrel file should have Domain exports section',
        );
        expect(
          content.contains('// Presentation exports'),
          isTrue,
          reason:
              'Barrel file should have Presentation exports '
              'section',
        );
      });

      test(
        'parent directories should have .gitkeep for consistency',
        () {
          final parentDirs = [
            '$basePath/data',
            '$basePath/domain',
            '$basePath/presentation',
          ];

          for (final dir in parentDirs) {
            expect(
              File('$dir/.gitkeep').existsSync(),
              isTrue,
              reason:
                  'Parent directory $dir should have '
                  '.gitkeep file',
            );
          }
        },
      );
    });

    group('Documentation', () {
      test('README should document planned dependencies', () {
        final readme = File('$basePath/README.md');
        final content = readme.readAsStringSync();

        expect(
          content.contains('Dependencies (Planned)'),
          isTrue,
          reason: 'README should mark dependencies as planned',
        );
      });
    });
  });
}
