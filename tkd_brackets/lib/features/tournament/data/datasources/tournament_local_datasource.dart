import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';

/// Local datasource for tournament operations using Drift database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class TournamentLocalDatasource {
  /// Get all tournaments for an organization.
  Future<List<TournamentModel>> getTournamentsForOrganization(
    String organizationId,
  );

  /// Get tournament by ID.
  Future<TournamentModel?> getTournamentById(String id);

  /// Insert a new tournament.
  Future<void> insertTournament(TournamentModel tournament);

  /// Update an existing tournament.
  Future<void> updateTournament(TournamentModel tournament);

  /// Soft delete a tournament.
  Future<void> deleteTournament(String id);
}

@LazySingleton(as: TournamentLocalDatasource)
class TournamentLocalDatasourceImplementation
    implements TournamentLocalDatasource {
  TournamentLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<List<TournamentModel>> getTournamentsForOrganization(
    String organizationId,
  ) async {
    final entries = await _database.getTournamentsForOrganization(
      organizationId,
    );
    return entries.map(TournamentModel.fromDriftEntry).toList();
  }

  @override
  Future<TournamentModel?> getTournamentById(String id) async {
    final entry = await _database.getTournamentById(id);
    if (entry == null) return null;
    return TournamentModel.fromDriftEntry(entry);
  }

  @override
  Future<void> insertTournament(TournamentModel tournament) async {
    await _database.insertTournament(tournament.toDriftCompanion());
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    await _database.updateTournament(
      tournament.id,
      tournament.toDriftCompanion(),
    );
  }

  @override
  Future<void> deleteTournament(String id) async {
    await _database.softDeleteTournament(id);
  }
}
