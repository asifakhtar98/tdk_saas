import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Datasource for Supabase Auth operations.
///
/// Handles authentication flows: magic link (OTP), session management.
/// Separate from `UserRemoteDatasource` which handles user profile data.
abstract class SupabaseAuthDatasource {
  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  /// Get the currently authenticated user.
  /// Returns null if no active session.
  User? get currentUser;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange;

  /// Sign out the current user.
  Future<void> signOut();
}

/// Supabase implementation of [SupabaseAuthDatasource].
///
/// Uses the Supabase Auth service for all authentication operations.
@LazySingleton(as: SupabaseAuthDatasource)
class SupabaseAuthDatasourceImplementation implements SupabaseAuthDatasource {
  /// Creates a [SupabaseAuthDatasourceImplementation] with the given client.
  SupabaseAuthDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
