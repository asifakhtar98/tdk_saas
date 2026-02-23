import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/participant/data/datasources/participant_local_datasource.dart';
import 'package:tkd_brackets/features/participant/data/datasources/participant_remote_datasource.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

/// Implementation of [ParticipantRepository] with offline-first strategy.
///
/// - Read: Try local first, fallback to remote if not found
/// - Write: Write to local, queue for sync if offline
/// - Sync: Last-Write-Wins based on sync_version
@LazySingleton(as: ParticipantRepository)
class ParticipantRepositoryImplementation implements ParticipantRepository {
  ParticipantRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
    this._database,
  );

  final ParticipantLocalDatasource _localDatasource;
  final ParticipantRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;
  final AppDatabase _database;

  @override
  Future<Either<Failure, List<ParticipantEntity>>> getParticipantsForDivision(
    String divisionId,
  ) async {
    try {
      var models = await _localDatasource.getParticipantsForDivision(
        divisionId,
      );

      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteModels = await _remoteDatasource
              .getParticipantsForDivision(divisionId);
          for (final model in remoteModels) {
            final existing = await _localDatasource.getParticipantById(
              model.id,
            );
            if (existing == null) {
              await _localDatasource.insertParticipant(model);
            } else if (model.syncVersion > existing.syncVersion) {
              await _localDatasource.updateParticipant(model);
            }
          }
          models = remoteModels;
        } on Exception catch (_) {
          // Use local data if remote fails
        }
      }

      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParticipantEntity>> getParticipantById(
    String id,
  ) async {
    try {
      final localModel = await _localDatasource.getParticipantById(id);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }

      if (await _connectivityService.hasInternetConnection()) {
        final remoteModel = await _remoteDatasource.getParticipantById(id);
        if (remoteModel != null) {
          await _localDatasource.insertParticipant(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      }

      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Participant not found.'),
      );
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParticipantEntity>> createParticipant(
    ParticipantEntity participant,
  ) async {
    try {
      final model = ParticipantModel.convertFromEntity(participant);

      await _localDatasource.insertParticipant(model);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertParticipant(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(participant);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ParticipantEntity>> updateParticipant(
    ParticipantEntity participant,
  ) async {
    try {
      final existing = await _localDatasource.getParticipantById(
        participant.id,
      );
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = ParticipantModel.convertFromEntity(
        participant.copyWith(syncVersion: newSyncVersion),
      );

      await _localDatasource.updateParticipant(model);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateParticipant(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(participant.copyWith(syncVersion: newSyncVersion));
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteParticipant(String id) async {
    try {
      await _localDatasource.deleteParticipant(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteParticipant(id);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticipantEntity>>> createParticipantsBatch(
    List<ParticipantEntity> participants,
  ) async {
    try {
      final models = participants
          .map(ParticipantModel.convertFromEntity)
          .toList();

      await _localDatasource.insertParticipantsBatch(models);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          for (final model in models) {
            await _remoteDatasource.insertParticipant(model);
          }
        } on Exception catch (_) {
          // Queued for sync - local data is safe
        }
      }

      return Right(participants);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to save participants',
          technicalDetails: e.toString(),
        ),
      );
    }
  }
}
