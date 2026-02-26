import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/data/models/match_model.dart';

/// Remote datasource for match operations (Supabase).
/// Stub implementation — Supabase sync not yet implemented.
abstract class MatchRemoteDatasource {
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

@LazySingleton(as: MatchRemoteDatasource)
class MatchRemoteDatasourceImplementation implements MatchRemoteDatasource {
  @override
  Future<List<MatchModel>> getMatchesForBracket(String bracketId) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<List<MatchModel>> getMatchesForRound(
    String bracketId,
    int roundNumber,
  ) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<MatchModel?> getMatchById(String id) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<void> insertMatch(MatchModel match) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<void> updateMatch(MatchModel match) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }

  @override
  Future<void> deleteMatch(String id) async {
    throw UnimplementedError('Supabase match sync not yet implemented');
  }
}
