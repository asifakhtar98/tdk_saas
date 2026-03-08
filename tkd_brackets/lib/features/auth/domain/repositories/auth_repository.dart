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
  /// Sign up with email and password.
  ///
  /// Creates a new user if the email doesn't exist.
  ///
  /// Returns:
  /// - [Right(UserEntity)] on success - authenticated user
  /// - [Left(Failure)] on error (invalid email, rate limit, network)
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sign in with email and password.
  ///
  /// Only works for existing users.
  ///
  /// Returns:
  /// - [Right(UserEntity)] on success - authenticated user
  /// - [Left(Failure)] on error (user not found, rate limit, network)
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
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
