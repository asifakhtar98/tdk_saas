import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';

/// Local datasource for participant operations using Drift database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class ParticipantLocalDatasource {
  /// Get all participants for a division.
  Future<List<ParticipantModel>> getParticipantsForDivision(String divisionId);

  /// Get participant by ID.
  Future<ParticipantModel?> getParticipantById(String id);

  /// Insert a new participant.
  Future<void> insertParticipant(ParticipantModel participant);

  /// Update an existing participant.
  Future<void> updateParticipant(ParticipantModel participant);

  /// Soft delete a participant.
  Future<void> deleteParticipant(String id);
}

@LazySingleton(as: ParticipantLocalDatasource)
class ParticipantLocalDatasourceImplementation
    implements ParticipantLocalDatasource {
  ParticipantLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<List<ParticipantModel>> getParticipantsForDivision(
    String divisionId,
  ) async {
    final entries = await _database.getParticipantsForDivision(divisionId);
    return entries.map(ParticipantModel.fromDriftEntry).toList();
  }

  @override
  Future<ParticipantModel?> getParticipantById(String id) async {
    final entry = await _database.getParticipantById(id);
    if (entry == null) return null;
    return ParticipantModel.fromDriftEntry(entry);
  }

  @override
  Future<void> insertParticipant(ParticipantModel participant) async {
    await _database.insertParticipant(participant.toDriftCompanion());
  }

  @override
  Future<void> updateParticipant(ParticipantModel participant) async {
    await _database.updateParticipant(
      participant.id,
      participant.toDriftCompanion(),
    );
  }

  @override
  Future<void> deleteParticipant(String id) async {
    await _database.softDeleteParticipant(id);
  }
}
