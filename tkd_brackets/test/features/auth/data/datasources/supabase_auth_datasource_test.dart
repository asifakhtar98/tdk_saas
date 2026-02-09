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
    group('sendMagicLink', () {
      test('calls signInWithOtp with correct parameters for sign-up', () async {
        // Arrange
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        // Act
        await datasource.sendMagicLink(
          email: 'test@example.com',
          shouldCreateUser: true,
        );

        // Assert
        verify(
          () => mockAuth.signInWithOtp(
            email: 'test@example.com',
            shouldCreateUser: true,
            emailRedirectTo: null,
          ),
        ).called(1);
      });

      test(
        'calls signInWithOtp with shouldCreateUser false for sign-in',
        () async {
          // Arrange
          when(
            () => mockAuth.signInWithOtp(
              email: any(named: 'email'),
              shouldCreateUser: any(named: 'shouldCreateUser'),
              emailRedirectTo: any(named: 'emailRedirectTo'),
            ),
          ).thenAnswer((_) async => AuthResponse());

          // Act
          await datasource.sendMagicLink(
            email: 'existing@example.com',
            shouldCreateUser: false,
          );

          // Assert
          verify(
            () => mockAuth.signInWithOtp(
              email: 'existing@example.com',
              shouldCreateUser: false,
              emailRedirectTo: null,
            ),
          ).called(1);
        },
      );

      test('rethrows AuthException on failure', () async {
        // Arrange
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenThrow(const AuthException('Rate limit exceeded'));

        // Act & Assert
        expect(
          () => datasource.sendMagicLink(
            email: 'test@example.com',
            shouldCreateUser: true,
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('passes redirectTo parameter for web apps', () async {
        // Arrange
        const redirectUrl = 'https://app.example.com/auth/callback';
        when(
          () => mockAuth.signInWithOtp(
            email: any(named: 'email'),
            shouldCreateUser: any(named: 'shouldCreateUser'),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        // Act
        await datasource.sendMagicLink(
          email: 'test@example.com',
          shouldCreateUser: true,
          redirectTo: redirectUrl,
        );

        // Assert
        verify(
          () => mockAuth.signInWithOtp(
            email: 'test@example.com',
            shouldCreateUser: true,
            emailRedirectTo: redirectUrl,
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

    group('verifyOtp', () {
      test('calls auth.verifyOTP with correct parameters', () async {
        // Arrange
        when(
          () => mockAuth.verifyOTP(
            email: any(named: 'email'),
            token: any(named: 'token'),
            type: any(named: 'type'),
          ),
        ).thenAnswer((_) async => AuthResponse());

        // Act
        await datasource.verifyOtp(
          email: 'test@example.com',
          token: '123456',
          type: OtpType.magiclink,
        );

        // Assert
        verify(
          () => mockAuth.verifyOTP(
            email: 'test@example.com',
            token: '123456',
            type: OtpType.magiclink,
          ),
        ).called(1);
      });
    });
  });
}
