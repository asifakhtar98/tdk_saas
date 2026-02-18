import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_local_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/datasources/tournament_remote_datasource.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

/// Implementation of [TournamentRepository] with offline-first strategy.
///
/// - Read: Try local first, fallback to remote if not found
/// - Write: Write to local, queue for sync if offline
/// - Sync: Last-Write-Wins based on sync_version
@LazySingleton(as: TournamentRepository)
class TournamentRepositoryImplementation implements TournamentRepository {
  TournamentRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
    this._database,
  );

  final TournamentLocalDatasource _localDatasource;
  final TournamentRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;
  final AppDatabase _database;

  @override
  Future<Either<Failure, List<TournamentEntity>>> getTournamentsForOrganization(
    String organizationId,
  ) async {
    try {
      // Try local first
      var models = await _localDatasource.getTournamentsForOrganization(
        organizationId,
      );

      // If online, sync from remote
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteModels = await _remoteDatasource
              .getTournamentsForOrganization(organizationId);
          // Sync remote to local (simplified - no conflict resolution for now)
          for (final model in remoteModels) {
            final existing = await _localDatasource.getTournamentById(model.id);
            if (existing == null) {
              await _localDatasource.insertTournament(model);
            } else if (model.syncVersion > existing.syncVersion) {
              await _localDatasource.updateTournament(model);
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
  Future<Either<Failure, TournamentEntity>> getTournamentById(String id) async {
    try {
      // Try local first
      final localModel = await _localDatasource.getTournamentById(id);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteModel = await _remoteDatasource.getTournamentById(id);
        if (remoteModel != null) {
          await _localDatasource.insertTournament(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(userFriendlyMessage: 'Tournament not found.'),
      );
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> createTournament(
    TournamentEntity tournament,
    String organizationId,
  ) async {
    try {
      final model = TournamentModel.convertFromEntity(tournament);

      // Always save locally first
      await _localDatasource.insertTournament(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertTournament(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(tournament);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TournamentEntity>> updateTournament(
    TournamentEntity tournament,
  ) async {
    try {
      // Read existing to get current syncVersion for remote sync
      final existing = await _localDatasource.getTournamentById(tournament.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = TournamentModel.convertFromEntity(
        tournament,
        syncVersion: newSyncVersion,
      );

      await _localDatasource.updateTournament(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateTournament(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(tournament);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTournament(String id) async {
    try {
      await _localDatasource.deleteTournament(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteTournament(id);
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
  Future<Either<Failure, Unit>> hardDeleteTournament(
    String tournamentId,
  ) async {
    try {
      await _database.softDeleteTournament(tournamentId);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DivisionEntity>>> getDivisionsByTournamentId(
    String tournamentId,
  ) async {
    try {
      final divisions = await _database.getDivisionsForTournament(tournamentId);
      return Right(divisions.map(_divisionEntryToEntity).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DivisionEntity>> updateDivision(
    DivisionEntity division,
  ) async {
    try {
      final success = await _database.updateDivision(
        division.id,
        DivisionsCompanion(
          isDeleted: Value(division.isDeleted),
          deletedAtTimestamp: Value(division.deletedAtTimestamp),
          syncVersion: Value(division.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ),
      );
      if (success) {
        return Right(division);
      }
      return const Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to update division',
        ),
      );
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  DivisionEntity _divisionEntryToEntity(DivisionEntry entry) {
    return DivisionEntity(
      id: entry.id,
      tournamentId: entry.tournamentId,
      name: entry.name,
      category: DivisionCategory.fromString(entry.category),
      gender: DivisionGender.fromString(entry.gender),
      ageMin: entry.ageMin,
      ageMax: entry.ageMax,
      weightMinKg: entry.weightMinKg,
      weightMaxKg: entry.weightMaxKg,
      beltRankMin: entry.beltRankMin,
      beltRankMax: entry.beltRankMax,
      bracketFormat: BracketFormat.fromString(entry.bracketFormat),
      assignedRingNumber: entry.assignedRingNumber,
      isCombined: entry.isCombined,
      displayOrder: entry.displayOrder,
      status: DivisionStatus.fromString(entry.status),
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      isCustom: entry.isCustom,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
    );
  }
}
