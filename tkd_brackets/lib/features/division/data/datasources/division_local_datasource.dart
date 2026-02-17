import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/data/models/division_model.dart';

abstract class DivisionLocalDatasource {
  Future<List<DivisionModel>> getDivisionsForTournament(String tournamentId);
  Future<DivisionModel?> getDivisionById(String id);
  Future<void> insertDivision(DivisionModel division);
  Future<void> updateDivision(DivisionModel division);
  Future<void> deleteDivision(String id);
}

@LazySingleton(as: DivisionLocalDatasource)
class DivisionLocalDatasourceImplementation implements DivisionLocalDatasource {
  DivisionLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<List<DivisionModel>> getDivisionsForTournament(
    String tournamentId,
  ) async {
    final entries = await _database.getDivisionsForTournament(tournamentId);
    return entries.map(DivisionModel.fromDriftEntry).toList();
  }

  @override
  Future<DivisionModel?> getDivisionById(String id) async {
    final entry = await _database.getDivisionById(id);
    if (entry == null) return null;
    return DivisionModel.fromDriftEntry(entry);
  }

  @override
  Future<void> insertDivision(DivisionModel division) async {
    await _database.insertDivision(division.toDriftCompanion());
  }

  @override
  Future<void> updateDivision(DivisionModel division) async {
    await _database.updateDivision(division.id, division.toDriftCompanion());
  }

  @override
  Future<void> deleteDivision(String id) async {
    await _database.softDeleteDivision(id);
  }
}
