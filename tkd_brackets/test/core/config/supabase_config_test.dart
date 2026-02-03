import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/config/supabase_config.dart';

void main() {
  // Reset state before each test to ensure isolation
  setUp(SupabaseConfig.resetForTesting);

  group('SupabaseConfig initialization guard', () {
    test('should report not initialized before initialize() called', () {
      expect(SupabaseConfig.isInitialized, false);
    });

    test('should throw StateError when accessing client before init', () {
      expect(
        () => SupabaseConfig.client,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('accessed before initialization'),
          ),
        ),
      );
    });

    test('should throw StateError when accessing auth before init', () {
      expect(
        () => SupabaseConfig.auth,
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SupabaseConfig credential validation', () {
    test('should throw ArgumentError when url is empty', () async {
      expect(
        () => SupabaseConfig.initialize(
          url: '',
          anonKey: 'valid-anon-key',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Supabase URL cannot be empty'),
          ),
        ),
      );
    });

    test('should throw ArgumentError when anonKey is empty', () async {
      expect(
        () => SupabaseConfig.initialize(
          url: 'https://example.supabase.co',
          anonKey: '',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Supabase anon key cannot be empty'),
          ),
        ),
      );
    });

    test('should throw ArgumentError when both url and anonKey are empty',
        () async {
      // First validation (url) should trigger
      expect(
        () => SupabaseConfig.initialize(url: '', anonKey: ''),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.name,
            'name',
            equals('url'),
          ),
        ),
      );
    });
  });

  group('SupabaseConfig resetForTesting', () {
    test('should reset isInitialized flag', () {
      // Initially not initialized
      expect(SupabaseConfig.isInitialized, false);

      // Reset should keep it false (idempotent)
      SupabaseConfig.resetForTesting();
      expect(SupabaseConfig.isInitialized, false);
    });
  });

  // Note: Full integration tests require Supabase project setup.
  // These tests validate guard and validation logic without calling
  // Supabase.initialize() since that requires valid credentials.
  //
  // For integration testing with actual Supabase:
  // 1. Create a test Supabase project
  // 2. Use environment variables for credentials
  // 3. Run as integration tests (flutter test integration_test/)
}
