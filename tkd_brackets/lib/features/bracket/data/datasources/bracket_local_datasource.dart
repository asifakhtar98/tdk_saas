import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';

/// Local datasource for bracket operations (Drift/SQLite).
abstract class BracketLocalDatasource {
  Future<List<BracketModel>> getBracketsForDivision(String divisionId);
  Future<BracketModel?> getBracketById(String id);
  Future<void> insertBracket(BracketModel bracket);
  Future<void> updateBracket(BracketModel bracket);
  Future<void> deleteBracket(String id);
}

@LazySingleton(as: BracketLocalDatasource)
class BracketLocalDatasourceImplementation implements BracketLocalDatasource {
  BracketLocalDatasourceImplementation(this._database);
  final AppDatabase _database;

  @override
  Future<List<BracketModel>> getBracketsForDivision(String divisionId) async {
    final entries = await _database.getBracketsForDivision(divisionId);
    return entries.map(BracketModel.fromDriftEntry).toList();
  }

  @override
  Future<BracketModel?> getBracketById(String id) async {
    final entry = await _database.getBracketById(id);
    return entry != null ? BracketModel.fromDriftEntry(entry) : null;
  }

  @override
  Future<void> insertBracket(BracketModel bracket) async {
    await _database.insertBracket(bracket.toDriftCompanion());
  }

  @override
  Future<void> updateBracket(BracketModel bracket) async {
    await _database.updateBracket(bracket.id, bracket.toDriftCompanion());
  }

  @override
  Future<void> deleteBracket(String id) async {
    await _database.softDeleteBracket(id);
  }
}
