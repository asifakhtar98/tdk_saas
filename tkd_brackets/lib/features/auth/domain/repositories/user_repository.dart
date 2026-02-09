import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Repository interface for user operations.
///
/// Implementations handle data source coordination
/// (local Drift, remote Supabase).
abstract class UserRepository {
  /// Get user by ID.
  /// Returns [Left(Failure)] if user not found or error occurs.
  Future<Either<Failure, UserEntity>> getUserById(String id);

  /// Get user by email.
  /// Returns [Left(Failure)] if user not found or error occurs.
  Future<Either<Failure, UserEntity>> getUserByEmail(String email);

  /// Get all users for an organization.
  Future<Either<Failure, List<UserEntity>>> getUsersForOrganization(
    String organizationId,
  );

  /// Create a new user (local + remote sync).
  /// Returns created user on success.
  Future<Either<Failure, UserEntity>> createUser(UserEntity user);

  /// Update an existing user.
  /// Returns updated user on success.
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);

  /// Delete a user (soft delete).
  Future<Either<Failure, Unit>> deleteUser(String id);

  /// Get current authenticated user from Supabase session.
  /// Returns [Left(Failure)] if no session or error occurs.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Watch the current user for real-time updates.
  Stream<Either<Failure, UserEntity>> watchCurrentUser();
}
