import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';

/// Local datasource for match operations (Drift/SQLite).
abstract class MatchLocalDatasource {
  Future<List<MatchModel>> getMatchesForBracket(String bracketId);
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  );
  Future<MatchModel?> getMatchById(String id);
  Future<void> insertMatch(MatchModel match);
  Future<void> updateMatch(MatchModel match);
  Future<void> deleteMatch(String id);
}

@LazySingleton(as: MatchLocalDatasource)
class MatchLocalDatasourceImplementation implements MatchLocalDatasource {
  MatchLocalDatasourceImplementation(this._database);
  final AppDatabase _database;

  @override
  Future<List<MatchModel>> getMatchesForBracket(String bracketId) async {
    final entries = await _database.getMatchesForBracket(bracketId);
    return entries.map(MatchModel.fromDriftEntry).toList();
  }

  @override
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  ) async {
    final entries = await _database.getMatchesByRound(bracketId, roundNumber);
    return entries.map(MatchModel.fromDriftEntry).toList();
  }

  @override
  Future<MatchModel?> getMatchById(String id) async {
    final entry = await _database.getMatchById(id);
    return entry != null ? MatchModel.fromDriftEntry(entry) : null;
  }

  @override
  Future<void> insertMatch(MatchModel match) async {
    await _database.insertMatch(match.toDriftCompanion());
  }

  @override
  Future<void> updateMatch(MatchModel match) async {
    await _database.updateMatch(match.id, match.toDriftCompanion());
  }

  @override
  Future<void> deleteMatch(String id) async {
    await _database.softDeleteMatch(id);
  }
}
