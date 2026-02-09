import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Repository interface for authentication operations.
///
/// This is the domain layer contract for auth flows.
/// The data layer provides the concrete implementation.
///
/// Note: This is separate from UserRepository which handles
/// user profile CRUD operations. This repository handles
/// authentication flows (magic link, sessions, etc.).
abstract class AuthRepository {
  /// Send magic link (OTP) to email for sign-up.
  ///
  /// Creates a new user if the email doesn't exist.
  ///
  /// Returns:
  /// - [Right(Unit)] on success - email sent
  /// - [Left(Failure)] on error (invalid email, rate limit, network)
  Future<Either<Failure, Unit>> sendSignUpMagicLink({
    required String email,
  });

  /// Send magic link (OTP) to email for sign-in.
  ///
  /// Only works for existing users.
  ///
  /// Returns:
  /// - [Right(Unit)] on success - email sent
  /// - [Left(Failure)] on error (user not found, rate limit, network)
  Future<Either<Failure, Unit>> sendSignInMagicLink({
    required String email,
  });

  /// Verify OTP token from magic link.
  ///
  /// This completes the sign-in flow:
  /// 1. Validates the OTP with Supabase
  /// 2. Establishes the user session
  /// 3. Fetches user profile from Supabase
  /// 4. Caches user locally
  /// 5. Updates lastLoginAt
  ///
  /// Returns:
  /// - [Right(UserEntity)] on success - authenticated user
  /// - [Left(Failure)] on error (expired, invalid, network)
  Future<Either<Failure, UserEntity>> verifyMagicLinkOtp({
    required String email,
    required String token,
  });

  /// Sign out the current user.
  ///
  /// Returns:
  /// - [Right(Unit)] on success
  /// - [Left(Failure)] on error
  Future<Either<Failure, Unit>> signOut();

  /// Get the currently authenticated user.
  ///
  /// Returns:
  /// - [Right(UserEntity)] if authenticated
  /// - [Left(Failure)] if not authenticated or error
  Future<Either<Failure, UserEntity>> getCurrentAuthenticatedUser();

  /// Stream of authentication state changes.
  ///
  /// Emits [Right(UserEntity)] when signed in, [Left(Failure)] when signed out.
  Stream<Either<Failure, UserEntity?>> get authStateChanges;
}
