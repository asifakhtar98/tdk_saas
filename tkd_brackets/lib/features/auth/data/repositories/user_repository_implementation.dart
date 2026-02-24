import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/user_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';

/// Implementation of [UserRepository] with offline-first strategy.
///
/// - Read: Try local first, fallback to remote if not found
/// - Write: Write to local, queue for sync if offline
/// - Sync: Last-Write-Wins based on sync_version
@LazySingleton(as: UserRepository)
class UserRepositoryImplementation implements UserRepository {
  UserRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final UserLocalDatasource _localDatasource;
  final UserRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, UserEntity>> getUserById(String id) async {
    try {
      // Try local first
      final localUser = await _localDatasource.getUserById(id);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteUser = await _remoteDatasource.getUserById(id);
        if (remoteUser != null) {
          // Cache locally
          await _localDatasource.insertUser(remoteUser);
          return Right(remoteUser.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'User not found.',
          technicalDetails:
              'No user found with the given ID in local or remote.',
        ),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve user.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserByEmail(String email) async {
    try {
      // Try local first
      final localUser = await _localDatasource.getUserByEmail(email);
      if (localUser != null) {
        return Right(localUser.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteUser = await _remoteDatasource.getUserByEmail(email);
        if (remoteUser != null) {
          // Cache locally
          await _localDatasource.insertUser(remoteUser);
          return Right(remoteUser.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'User not found.',
          technicalDetails: 'No user found with the given email.',
        ),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve user.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsersForOrganization(
    String organizationId,
  ) async {
    try {
      // Try local first
      var users = await _localDatasource.getUsersForOrganization(
        organizationId,
      );

      // If online, fetch from remote and update local cache
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteUsers = await _remoteDatasource.getUsersForOrganization(
            organizationId,
          );
          // Sync remote to local (simple overwrite for now)
          for (final user in remoteUsers) {
            final existing = await _localDatasource.getUserById(user.id);
            if (existing == null) {
              await _localDatasource.insertUser(user);
            } else if (user.syncVersion > existing.syncVersion) {
              await _localDatasource.updateUser(user);
            }
          }
          users = remoteUsers;
        } on Exception catch (_) {
          // Use local data if remote fails
        }
      }

      return Right(users.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve users.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUser(UserEntity user) async {
    try {
      final model = UserModel.convertFromEntity(user);

      // Always save locally first
      await _localDatasource.insertUser(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertUser(model);
        } on Exception catch (_) {
          // Queued for sync - continue with local success
        }
      }

      return Right(user);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to create user.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      // Get current version to increment
      final existing = await _localDatasource.getUserById(user.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = UserModel.convertFromEntity(
        user,
        syncVersion: newSyncVersion,
        updatedAtTimestamp: DateTime.now(),
      );

      await _localDatasource.updateUser(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateUser(model);
        } on Exception catch (_) {
          // Queued for sync - continue with local success
        }
      }

      return Right(user);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to update user.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteUser(String id) async {
    try {
      await _localDatasource.deleteUser(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteUser(id);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to delete user.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final authUser = _remoteDatasource.currentAuthUser;
      if (authUser == null) {
        return const Left(AuthenticationSessionExpiredFailure());
      }

      // Fetch user profile from our users table
      return getUserById(authUser.id);
    } on Exception catch (e) {
      return Left(ServerConnectionFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserEntity>> watchCurrentUser() async* {
    await for (final authState in _remoteDatasource.authStateChanges) {
      if (authState.session?.user != null) {
        final result = await getUserById(authState.session!.user.id);
        yield result;
      } else {
        yield const Left(AuthenticationSessionExpiredFailure());
      }
    }
  }
}
