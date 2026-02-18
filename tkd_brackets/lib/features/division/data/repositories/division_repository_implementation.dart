import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart'
    show ParticipantEntry;
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/division/data/datasources/division_local_datasource.dart';
import 'package:tkd_brackets/features/division/data/datasources/division_remote_datasource.dart';
import 'package:tkd_brackets/features/division/data/models/division_model.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';

@LazySingleton(as: DivisionRepository)
class DivisionRepositoryImplementation implements DivisionRepository {
  DivisionRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final DivisionLocalDatasource _localDatasource;
  final DivisionRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsForTournament(
    String tournamentId,
  ) async {
    try {
      var models = await _localDatasource.getDivisionsForTournament(
        tournamentId,
      );

      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteModels = await _remoteDatasource
              .getDivisionsForTournament(tournamentId);
          for (final model in remoteModels) {
            final existing = await _localDatasource.getDivisionById(model.id);
            if (existing == null) {
              await _localDatasource.insertDivision(model);
            } else if (model.syncVersion > existing.syncVersion) {
              await _localDatasource.updateDivision(model);
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
  Future<Either<Failure, DivisionEntity>> getDivisionById(String id) async {
    try {
      final localModel = await _localDatasource.getDivisionById(id);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }

      if (await _connectivityService.hasInternetConnection()) {
        final remoteModel = await _remoteDatasource.getDivisionById(id);
        if (remoteModel != null) {
          await _localDatasource.insertDivision(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(userFriendlyMessage: 'Division not found.'),
      );
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DivisionEntity>> getDivision(String id) =>
      getDivisionById(id);

  @override
  Future<Either<Failure, DivisionEntity>> createDivision(
    DivisionEntity division,
  ) async {
    try {
      final model = DivisionModel.convertFromEntity(division);

      await _localDatasource.insertDivision(model);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertDivision(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(division);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DivisionEntity>> updateDivision(
    DivisionEntity division,
  ) async {
    try {
      final existing = await _localDatasource.getDivisionById(division.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = DivisionModel.convertFromEntity(
        division,
        syncVersion: newSyncVersion,
      );

      await _localDatasource.updateDivision(model);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateDivision(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(division);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDivision(String id) async {
    try {
      await _localDatasource.deleteDivision(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteDivision(id);
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
  Future<Either<Failure, bool>> isDivisionNameUnique(
    String name,
    String tournamentId, {
    String? excludeDivisionId,
  }) async {
    try {
      final isUnique = await _localDatasource.isDivisionNameUnique(
        name,
        tournamentId,
        excludeDivisionId: excludeDivisionId,
      );
      return Right(isUnique);
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivision(
    String divisionId,
  ) async {
    try {
      final participants = await _localDatasource.getParticipantsForDivision(
        divisionId,
      );
      return Right(participants);
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ParticipantEntry>>> getParticipantsForDivisions(
    List<String> divisionIds,
  ) async {
    try {
      final participants = await _localDatasource.getParticipantsForDivisions(
        divisionIds,
      );
      return Right(participants);
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DivisionEntity>>> mergeDivisions({
    required DivisionEntity mergedDivision,
    required List<DivisionEntity> sourceDivisions,
    required List<ParticipantEntry> participants,
  }) async {
    try {
      final mergedModel = DivisionModel.convertFromEntity(
        mergedDivision,
        syncVersion: 1,
      );

      final sourceModels = sourceDivisions.map((d) {
        final newSyncVersion = d.syncVersion + 1;
        return DivisionModel.convertFromEntity(
          d.copyWith(
            isDeleted: true,
            syncVersion: newSyncVersion,
            updatedAtTimestamp: DateTime.now(),
          ),
          syncVersion: newSyncVersion,
          isDeleted: true,
        );
      }).toList();

      final updatedParticipants = participants.map((p) {
        return ParticipantEntry(
          id: p.id,
          firstName: p.firstName,
          lastName: p.lastName,
          dateOfBirth: p.dateOfBirth,
          gender: p.gender,
          weightKg: p.weightKg,
          schoolOrDojangName: p.schoolOrDojangName,
          beltRank: p.beltRank,
          seedNumber: p.seedNumber,
          registrationNumber: p.registrationNumber,
          isBye: p.isBye,
          checkInStatus: p.checkInStatus,
          checkInAtTimestamp: p.checkInAtTimestamp,
          photoUrl: p.photoUrl,
          notes: p.notes,
          divisionId: mergedDivision.id,
          syncVersion: p.syncVersion + 1,
          isDeleted: p.isDeleted,
          isDemoData: p.isDemoData,
          createdAtTimestamp: p.createdAtTimestamp,
          updatedAtTimestamp: DateTime.now(),
          deletedAtTimestamp: p.deletedAtTimestamp,
        );
      }).toList();

      await _localDatasource.insertDivision(mergedModel);
      await _localDatasource.updateDivisions(sourceModels);
      await _localDatasource.updateParticipants(updatedParticipants);

      // TODO(AC18): When Bracket feature is implemented (Epic 5), add bracket
      // soft-delete logic here. Existing brackets should be archived (soft-deleted)
      // when a division is merged/split.

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertDivision(mergedModel);
          for (final source in sourceModels) {
            await _remoteDatasource.updateDivision(source);
          }
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right([mergedDivision, ...sourceDivisions]);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DivisionEntity>>> splitDivision({
    required DivisionEntity poolADivision,
    required DivisionEntity poolBDivision,
    required DivisionEntity sourceDivision,
    required List<ParticipantEntry> poolAParticipants,
    required List<ParticipantEntry> poolBParticipants,
  }) async {
    try {
      final poolAModel = DivisionModel.convertFromEntity(
        poolADivision,
        syncVersion: 1,
      );
      final poolBModel = DivisionModel.convertFromEntity(
        poolBDivision,
        syncVersion: 1,
      );
      final sourceModel = DivisionModel.convertFromEntity(
        sourceDivision.copyWith(
          isDeleted: true,
          syncVersion: sourceDivision.syncVersion + 1,
          updatedAtTimestamp: DateTime.now(),
        ),
        syncVersion: sourceDivision.syncVersion + 1,
        isDeleted: true,
      );

      final updatedPoolAParticipants = poolAParticipants.map((p) {
        return ParticipantEntry(
          id: p.id,
          firstName: p.firstName,
          lastName: p.lastName,
          dateOfBirth: p.dateOfBirth,
          gender: p.gender,
          weightKg: p.weightKg,
          schoolOrDojangName: p.schoolOrDojangName,
          beltRank: p.beltRank,
          seedNumber: p.seedNumber,
          registrationNumber: p.registrationNumber,
          isBye: p.isBye,
          checkInStatus: p.checkInStatus,
          checkInAtTimestamp: p.checkInAtTimestamp,
          photoUrl: p.photoUrl,
          notes: p.notes,
          divisionId: poolADivision.id,
          syncVersion: p.syncVersion + 1,
          isDeleted: p.isDeleted,
          isDemoData: p.isDemoData,
          createdAtTimestamp: p.createdAtTimestamp,
          updatedAtTimestamp: DateTime.now(),
          deletedAtTimestamp: p.deletedAtTimestamp,
        );
      }).toList();

      final updatedPoolBParticipants = poolBParticipants.map((p) {
        return ParticipantEntry(
          id: p.id,
          firstName: p.firstName,
          lastName: p.lastName,
          dateOfBirth: p.dateOfBirth,
          gender: p.gender,
          weightKg: p.weightKg,
          schoolOrDojangName: p.schoolOrDojangName,
          beltRank: p.beltRank,
          seedNumber: p.seedNumber,
          registrationNumber: p.registrationNumber,
          isBye: p.isBye,
          checkInStatus: p.checkInStatus,
          checkInAtTimestamp: p.checkInAtTimestamp,
          photoUrl: p.photoUrl,
          notes: p.notes,
          divisionId: poolBDivision.id,
          syncVersion: p.syncVersion + 1,
          isDeleted: p.isDeleted,
          isDemoData: p.isDemoData,
          createdAtTimestamp: p.createdAtTimestamp,
          updatedAtTimestamp: DateTime.now(),
          deletedAtTimestamp: p.deletedAtTimestamp,
        );
      }).toList();

      await _localDatasource.insertDivisions([poolAModel, poolBModel]);
      await _localDatasource.updateDivision(sourceModel);
      await _localDatasource.updateParticipants([
        ...updatedPoolAParticipants,
        ...updatedPoolBParticipants,
      ]);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertDivision(poolAModel);
          await _remoteDatasource.insertDivision(poolBModel);
          await _remoteDatasource.updateDivision(sourceModel);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right([poolADivision, poolBDivision, sourceDivision]);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }
}
