import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/core/error/auth_failures.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using Supabase Auth.
///
/// This class handles all Supabase-specific error mapping, keeping
/// the domain layer clean from infrastructure concerns.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImplementation implements AuthRepository {
  AuthRepositoryImplementation(
    this._authDatasource,
    this._userRemoteDatasource,
    this._userLocalDatasource,
  );

  final SupabaseAuthDatasource _authDatasource;
  final UserRemoteDatasource _userRemoteDatasource;
  final UserLocalDatasource _userLocalDatasource;

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _authDatasource.signUp(
        email: email,
        password: password,
      );

      final supabaseUser = authResponse.user;
      if (supabaseUser == null) {
        return const Left(
          ServerConnectionFailure(
            technicalDetails: 'User is null after sign up',
          ),
        );
      }

      // Create user profile
      final now = DateTime.now();
      final newUser = UserModel(
        id: supabaseUser.id,
        email: supabaseUser.email ?? email,
        displayName:
            supabaseUser.userMetadata?['display_name'] as String? ??
            email.split('@').first,
        organizationId: '',
        role: 'owner',
        isActive: true,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        lastSignInAtTimestamp: now,
      );
      
      final userModel = await _userRemoteDatasource.insertUser(newUser);
      await _userLocalDatasource.insertUser(userModel);

      return Right(userModel.convertToEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on Exception catch (e) {
      return Left(ServerConnectionFailure(technicalDetails: 'Exception: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _authDatasource.signInWithPassword(
        email: email,
        password: password,
      );

      final supabaseUser = authResponse.user;
      if (supabaseUser == null) {
        return const Left(
          UserNotFoundFailure(
            technicalDetails: 'User is null after sign in',
          ),
        );
      }

      final existingUser = await _userRemoteDatasource.getUserById(
        supabaseUser.id,
      );

      if (existingUser == null) {
        return const Left(
          UserNotFoundFailure(
            technicalDetails: 'User profile not found after sign in',
          ),
        );
      }

      final userModel = existingUser.copyWith(
        lastSignInAtTimestamp: DateTime.now(),
        updatedAtTimestamp: DateTime.now(),
      );
      
      await _userRemoteDatasource.updateUser(userModel);

      final localUser = await _userLocalDatasource.getUserById(userModel.id);
      if (localUser != null) {
        await _userLocalDatasource.updateUser(userModel);
      } else {
        await _userLocalDatasource.insertUser(userModel);
      }

      return Right(userModel.convertToEntity());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on Exception catch (e) {
      return Left(ServerConnectionFailure(technicalDetails: 'Exception: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentAuthenticatedUser() async {
    try {
      final supabaseUser = _authDatasource.currentUser;
      if (supabaseUser == null) {
        return const Left(
          UserNotFoundFailure(
            technicalDetails: 'No authenticated user in session',
          ),
        );
      }

      // Try local cache first
      final localUser = await _userLocalDatasource.getUserById(supabaseUser.id);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote - NOTE: returns UserModel? (nullable)
      final remoteUser = await _userRemoteDatasource.getUserById(
        supabaseUser.id,
      );
      if (remoteUser == null) {
        return const Left(
          UserNotFoundFailure(
            technicalDetails: 'User profile not found in database',
          ),
        );
      }

      // Cache locally for future use
      await _userLocalDatasource.insertUser(remoteUser);
      return Right(remoteUser.convertToEntity());
    } on Exception catch (e) {
      return Left(ServerConnectionFailure(technicalDetails: 'Exception: $e'));
    }
  }

  @override
  Stream<Either<Failure, UserEntity?>> get authStateChanges {
    return _authDatasource.onAuthStateChange.asyncMap((authState) async {
      final user = authState.session?.user;
      if (user == null) {
        return const Right<Failure, UserEntity?>(null);
      }

      try {
        // NOTE: returns UserModel? (nullable)
        final userModel = await _userRemoteDatasource.getUserById(user.id);
        if (userModel == null) {
          // User authenticated but no profile yet - valid during sign-up
          return const Right<Failure, UserEntity?>(null);
        }
        return Right<Failure, UserEntity?>(userModel.convertToEntity());
      } on Exception catch (e) {
        return Left<Failure, UserEntity?>(
          ServerConnectionFailure(technicalDetails: 'Exception: $e'),
        );
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _authDatasource.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(
        SignOutFailure(technicalDetails: 'AuthException: ${e.message}'),
      );
    } on Exception catch (e) {
      return Left(ServerConnectionFailure(technicalDetails: 'Exception: $e'));
    }
  }

  /// Maps Supabase AuthException to domain Failure types.
  Failure _mapAuthException(AuthException e) {
    if (e.message.contains('rate limit') ||
        e.message.contains('too many requests')) {
      return RateLimitExceededFailure(
        technicalDetails: 'Supabase rate limit: ${e.message}',
      );
    }
    return AuthFailure(
      technicalDetails: 'AuthException: ${e.message}',
    );
  }
}
