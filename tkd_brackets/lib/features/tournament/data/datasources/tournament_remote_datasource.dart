import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';

/// Remote datasource for tournament operations using Supabase.
///
/// All queries go through RLS-protected tables.
abstract class TournamentRemoteDatasource {
  /// Get all tournaments for an organization.
  Future<List<TournamentModel>> getTournamentsForOrganization(
    String organizationId,
  );

  /// Get tournament by ID.
  Future<TournamentModel?> getTournamentById(String id);

  /// Insert a new tournament.
  Future<TournamentModel> insertTournament(TournamentModel tournament);

  /// Update an existing tournament.
  Future<TournamentModel> updateTournament(TournamentModel tournament);

  /// Soft delete a tournament.
  Future<void> deleteTournament(String id);
}

@LazySingleton(as: TournamentRemoteDatasource)
class TournamentRemoteDatasourceImplementation
    implements TournamentRemoteDatasource {
  TournamentRemoteDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  static const String _tableName = 'tournaments';

  @override
  Future<List<TournamentModel>> getTournamentsForOrganization(
    String organizationId,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('organization_id', organizationId)
        .eq('is_deleted', false)
        .order('scheduled_date', ascending: false);

    return response.map<TournamentModel>(TournamentModel.fromJson).toList();
  }

  @override
  Future<TournamentModel?> getTournamentById(String id) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return TournamentModel.fromJson(response);
  }

  @override
  Future<TournamentModel> insertTournament(TournamentModel tournament) async {
    final response = await _supabase
        .from(_tableName)
        .insert(tournament.toJson())
        .select()
        .single();

    return TournamentModel.fromJson(response);
  }

  @override
  Future<TournamentModel> updateTournament(TournamentModel tournament) async {
    final response = await _supabase
        .from(_tableName)
        .update(tournament.toJson())
        .eq('id', tournament.id)
        .select()
        .single();

    return TournamentModel.fromJson(response);
  }

  @override
  Future<void> deleteTournament(String id) async {
    // Soft delete by setting is_deleted = true
    await _supabase
        .from(_tableName)
        .update({
          'is_deleted': true,
          'deleted_at_timestamp': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
