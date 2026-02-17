import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/division/data/models/division_model.dart';

abstract class DivisionRemoteDatasource {
  Future<List<DivisionModel>> getDivisionsForTournament(String tournamentId);
  Future<DivisionModel?> getDivisionById(String id);
  Future<DivisionModel> insertDivision(DivisionModel division);
  Future<DivisionModel> updateDivision(DivisionModel division);
  Future<void> deleteDivision(String id);
}

@LazySingleton(as: DivisionRemoteDatasource)
class DivisionRemoteDatasourceImplementation
    implements DivisionRemoteDatasource {
  DivisionRemoteDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  static const String _tableName = 'divisions';

  @override
  Future<List<DivisionModel>> getDivisionsForTournament(
    String tournamentId,
  ) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('tournament_id', tournamentId)
        .eq('is_deleted', false)
        .order('display_order', ascending: true);

    return response.map<DivisionModel>(DivisionModel.fromJson).toList();
  }

  @override
  Future<DivisionModel?> getDivisionById(String id) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return DivisionModel.fromJson(response);
  }

  @override
  Future<DivisionModel> insertDivision(DivisionModel division) async {
    final response = await _supabase
        .from(_tableName)
        .insert(division.toJson())
        .select()
        .single();

    return DivisionModel.fromJson(response);
  }

  @override
  Future<DivisionModel> updateDivision(DivisionModel division) async {
    final response = await _supabase
        .from(_tableName)
        .update(division.toJson())
        .eq('id', division.id)
        .select()
        .single();

    return DivisionModel.fromJson(response);
  }

  @override
  Future<void> deleteDivision(String id) async {
    await _supabase
        .from(_tableName)
        .update({
          'is_deleted': true,
          'deleted_at_timestamp': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}
