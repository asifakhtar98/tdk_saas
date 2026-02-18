import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/division/data/models/division_model.dart';

abstract class DivisionLocalDatasource {
  Future<List<DivisionModel>> getDivisionsForTournament(String tournamentId);
  Future<DivisionModel?> getDivisionById(String id);
  Future<void> insertDivision(DivisionModel division);
  Future<void> updateDivision(DivisionModel division);
  Future<void> deleteDivision(String id);
  Future<bool> isDivisionNameUnique(
    String name,
    String tournamentId, {
    String? excludeDivisionId,
  });
  Future<void> insertDivisions(List<DivisionModel> divisions);
  Future<void> updateDivisions(List<DivisionModel> divisions);
  Future<List<ParticipantEntry>> getParticipantsForDivision(String divisionId);
  Future<List<ParticipantEntry>> getParticipantsForDivisions(
    List<String> divisionIds,
  );
  Future<void> updateParticipants(List<ParticipantEntry> participants);
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

  @override
  Future<bool> isDivisionNameUnique(
    String name,
    String tournamentId, {
    String? excludeDivisionId,
  }) async {
    final divisions = await _database.getDivisionsForTournament(tournamentId);
    return !divisions.any(
      (d) =>
          d.name.toLowerCase() == name.toLowerCase() &&
          d.id != excludeDivisionId &&
          !d.isDeleted,
    );
  }

  @override
  Future<void> insertDivisions(List<DivisionModel> divisions) async {
    for (final division in divisions) {
      await _database.insertDivision(division.toDriftCompanion());
    }
  }

  @override
  Future<void> updateDivisions(List<DivisionModel> divisions) async {
    for (final division in divisions) {
      await _database.updateDivision(division.id, division.toDriftCompanion());
    }
  }

  @override
  Future<List<ParticipantEntry>> getParticipantsForDivision(
    String divisionId,
  ) async {
    return _database.getParticipantsForDivision(divisionId);
  }

  @override
  Future<List<ParticipantEntry>> getParticipantsForDivisions(
    List<String> divisionIds,
  ) async {
    final allParticipants = <ParticipantEntry>[];
    for (final divisionId in divisionIds) {
      final participants = await _database.getParticipantsForDivision(
        divisionId,
      );
      allParticipants.addAll(participants);
    }
    return allParticipants;
  }

  @override
  Future<void> updateParticipants(List<ParticipantEntry> participants) async {
    for (final participant in participants) {
      await _database.updateParticipant(
        participant.id,
        ParticipantsCompanion(
          divisionId: Value(participant.divisionId),
          syncVersion: Value(participant.syncVersion + 1),
          updatedAtTimestamp: Value(DateTime.now()),
        ),
      );
    }
  }
}
