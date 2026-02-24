import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Datasource for Supabase Auth operations.
///
/// Handles authentication flows: magic link (OTP), session management.
/// Separate from `UserRemoteDatasource` which handles user profile data.
abstract class SupabaseAuthDatasource {
  /// Send magic link (OTP) to email for sign-up/sign-in.
  ///
  /// [email] - User's email address.
  /// [shouldCreateUser] - If true, creates account if email not found.
  ///                       Set to true for sign-up, false for sign-in only.
  /// [redirectTo] - Optional redirect URL for web apps after magic link click.
  ///                Required for web deployment. Should be app's callback URL.
  ///
  /// Supabase rate limits: 3 emails per email per 60 seconds.
  Future<void> sendMagicLink({
    required String email,
    required bool shouldCreateUser,
    String? redirectTo,
  });

  /// Verify OTP from magic link or email code.
  /// Returns the authenticated session.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
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
  Future<void> sendMagicLink({
    required String email,
    required bool shouldCreateUser,
    String? redirectTo,
  }) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
      emailRedirectTo: redirectTo, // Required for web apps
    );
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    return _supabase.auth.verifyOTP(email: email, token: token, type: type);
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
