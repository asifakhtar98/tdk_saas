import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/match_remote_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/match_repository.dart';

@LazySingleton(as: MatchRepository)
class MatchRepositoryImplementation implements MatchRepository {
  MatchRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final MatchLocalDatasource _localDatasource;
  final MatchRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, List<MatchEntity>>> getMatchesForBracket(
    String bracketId,
  ) async {
    try {
      final models = await _localDatasource.getMatchesForBracket(bracketId);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get matches for bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<MatchEntity>>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  ) async {
    try {
      final models =
          await _localDatasource.getMatchesForRound(bracketId, roundNumber);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get matches for round: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> getMatchById(String id) async {
    try {
      final model = await _localDatasource.getMatchById(id);
      if (model != null) return Right(model.convertToEntity());

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (!hasConnection) {
        return const Left(NotFoundFailure(
          userFriendlyMessage: 'Match not found',
        ));
      }

      try {
        final remoteModel = await _remoteDatasource.getMatchById(id);
        if (remoteModel != null) {
          await _localDatasource.insertMatch(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      } on Object {
        // Remote fetch failed, return not found
      }

      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Match not found',
      ));
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get match: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> createMatch(
    MatchEntity match,
  ) async {
    try {
      final model = MatchModel.convertFromEntity(match);
      await _localDatasource.insertMatch(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.insertMatch(model);
        } on Object {
          // Remote insert failed, will sync later
        }
      }

      return Right(match);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to create match: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, List<MatchEntity>>> createMatches(
    List<MatchEntity> matchEntities,
  ) async {
    try {
      final models = matchEntities
          .map(MatchModel.convertFromEntity)
          .toList();
      await _localDatasource.insertMatches(models);
      return Right(matchEntities);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to create matches in batch: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, MatchEntity>> updateMatch(
    MatchEntity match,
  ) async {
    try {
      final existing = await _localDatasource.getMatchById(match.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final updatedEntity = match.copyWith(syncVersion: newSyncVersion);
      final model = MatchModel.convertFromEntity(updatedEntity);
      await _localDatasource.updateMatch(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.updateMatch(model);
        } on Object {
          // Remote update failed, will sync later
        }
      }

      return Right(updatedEntity);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to update match: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMatch(String id) async {
    try {
      await _localDatasource.deleteMatch(id);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.deleteMatch(id);
        } on Object {
          // Remote delete failed, will sync later
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to delete match: $e',
      ));
    }
  }
}
