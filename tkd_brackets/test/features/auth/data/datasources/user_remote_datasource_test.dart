import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late UserRemoteDatasourceImplementation datasource;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    datasource = UserRemoteDatasourceImplementation(mockSupabase);
  });

  group('UserRemoteDatasource', () {
    group('currentAuthUser', () {
      test('returns null when no user is authenticated', () {
        when(() => mockAuth.currentUser).thenReturn(null);

        final result = datasource.currentAuthUser;

        expect(result, isNull);
      });

      test('returns User when authenticated', () {
        final mockUser = const User(
          id: 'auth-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00.000Z',
        );
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        final result = datasource.currentAuthUser;

        expect(result, isNotNull);
        expect(result!.id, 'auth-id');
      });
    });

    group('authStateChanges', () {
      test('returns auth state changes stream', () {
        final mockStream = Stream<AuthState>.empty();
        when(() => mockAuth.onAuthStateChange).thenAnswer((_) => mockStream);

        final result = datasource.authStateChanges;

        expect(result, isA<Stream<AuthState>>());
      });
    });
  });
}
