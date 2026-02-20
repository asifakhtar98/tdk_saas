import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/participant/data/models/participant_model.dart';

/// Remote datasource for participant operations (Supabase).
///
/// This is a stub implementation - Supabase sync not yet implemented.
abstract class ParticipantRemoteDatasource {
  /// Get all participants for a division from remote.
  Future<List<ParticipantModel>> getParticipantsForDivision(String divisionId);

  /// Get participant by ID from remote.
  Future<ParticipantModel?> getParticipantById(String id);

  /// Insert a new participant to remote.
  Future<void> insertParticipant(ParticipantModel participant);

  /// Update an existing participant on remote.
  Future<void> updateParticipant(ParticipantModel participant);

  /// Delete a participant on remote.
  Future<void> deleteParticipant(String id);
}

@LazySingleton(as: ParticipantRemoteDatasource)
class ParticipantRemoteDatasourceImplementation
    implements ParticipantRemoteDatasource {
  @override
  Future<List<ParticipantModel>> getParticipantsForDivision(
    String divisionId,
  ) async {
    throw UnimplementedError('Supabase participant sync not yet implemented');
  }

  @override
  Future<ParticipantModel?> getParticipantById(String id) async {
    throw UnimplementedError('Supabase participant sync not yet implemented');
  }

  @override
  Future<void> insertParticipant(ParticipantModel participant) async {
    throw UnimplementedError('Supabase participant sync not yet implemented');
  }

  @override
  Future<void> updateParticipant(ParticipantModel participant) async {
    throw UnimplementedError('Supabase participant sync not yet implemented');
  }

  @override
  Future<void> deleteParticipant(String id) async {
    throw UnimplementedError('Supabase participant sync not yet implemented');
  }
}
