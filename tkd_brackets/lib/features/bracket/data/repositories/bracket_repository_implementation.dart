import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_local_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/datasources/bracket_remote_datasource.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';

@LazySingleton(as: BracketRepository)
class BracketRepositoryImplementation implements BracketRepository {
  BracketRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final BracketLocalDatasource _localDatasource;
  final BracketRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, List<BracketEntity>>> getBracketsForDivision(
    String divisionId,
  ) async {
    try {
      final models = await _localDatasource.getBracketsForDivision(divisionId);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get brackets for division: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, BracketEntity>> getBracketById(String id) async {
    try {
      final model = await _localDatasource.getBracketById(id);
      if (model != null) return Right(model.convertToEntity());

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (!hasConnection) {
        return const Left(NotFoundFailure(
          userFriendlyMessage: 'Bracket not found',
        ));
      }

      try {
        final remoteModel = await _remoteDatasource.getBracketById(id);
        if (remoteModel != null) {
          await _localDatasource.insertBracket(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      } on Object {
        // Remote fetch failed, return not found
      }

      return const Left(NotFoundFailure(
        userFriendlyMessage: 'Bracket not found',
      ));
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(
        technicalDetails: 'Failed to get bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, BracketEntity>> createBracket(
    BracketEntity bracket,
  ) async {
    try {
      final model = BracketModel.convertFromEntity(bracket);
      await _localDatasource.insertBracket(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.insertBracket(model);
        } on Object {
          // Remote insert failed, will sync later
        }
      }

      return Right(bracket);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to create bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, BracketEntity>> updateBracket(
    BracketEntity bracket,
  ) async {
    try {
      final existing = await _localDatasource.getBracketById(bracket.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final updatedEntity = bracket.copyWith(syncVersion: newSyncVersion);
      final model = BracketModel.convertFromEntity(updatedEntity);
      await _localDatasource.updateBracket(model);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.updateBracket(model);
        } on Object {
          // Remote update failed, will sync later
        }
      }

      return Right(updatedEntity);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to update bracket: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBracket(String id) async {
    try {
      await _localDatasource.deleteBracket(id);

      final hasConnection =
          await _connectivityService.hasInternetConnection();
      if (hasConnection) {
        try {
          await _remoteDatasource.deleteBracket(id);
        } on Object {
          // Remote delete failed, will sync later
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(
        technicalDetails: 'Failed to delete bracket: $e',
      ));
    }
  }
}
