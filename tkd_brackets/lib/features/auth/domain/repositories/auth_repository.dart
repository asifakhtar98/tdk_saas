import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';

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

  /// Sign out the current user.
  ///
  /// Returns:
  /// - [Right(Unit)] on success
  /// - [Left(Failure)] on error
  Future<Either<Failure, Unit>> signOut();
}
