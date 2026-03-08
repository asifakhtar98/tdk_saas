import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late SupabaseAuthDatasourceImplementation datasource;

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(OtpType.magiclink);
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    datasource = SupabaseAuthDatasourceImplementation(mockSupabase);
  });

  group('SupabaseAuthDatasource', () {
    group('signUp', () {
      test('calls signUp with correct parameters', () async {
        // Arrange
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        // Act
        await datasource.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        verify(
          () => mockAuth.signUp(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      });

      test('rethrows AuthException on failure', () async {
        // Arrange
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Rate limit exceeded'));

        // Act & Assert
        expect(
          () => datasource.signUp(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithPassword', () {
      test('calls signInWithPassword with correct parameters', () async {
        // Arrange
        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        // Act
        await datasource.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        verify(
            () => mockAuth.signInWithPassword(
              email: 'test@example.com',
              password: 'password123',
            ),
        ).called(1);
      });
    });

    group('currentUser', () {
      test('returns current user from Supabase auth', () {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act
        final result = datasource.currentUser;

        // Assert
        expect(result, isNull);
        verify(() => mockAuth.currentUser).called(1);
      });
    });

    group('onAuthStateChange', () {
      test('returns auth state stream from Supabase auth', () {
        // Arrange
        const mockStream = Stream<AuthState>.empty();
        when(() => mockAuth.onAuthStateChange).thenAnswer((_) => mockStream);

        // Act
        final result = datasource.onAuthStateChange;

        // Assert
        expect(result, equals(mockStream));
        verify(() => mockAuth.onAuthStateChange).called(1);
      });
    });

    group('signOut', () {
      test('calls signOut on Supabase auth', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await datasource.signOut();

        // Assert
        verify(() => mockAuth.signOut()).called(1);
      });
    });
  });
}
