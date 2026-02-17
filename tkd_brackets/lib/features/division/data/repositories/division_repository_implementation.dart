import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
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
}
