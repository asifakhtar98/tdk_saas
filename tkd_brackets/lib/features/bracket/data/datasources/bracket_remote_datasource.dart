import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/features/bracket/data/models/bracket_model.dart';

/// Remote datasource for bracket operations (Supabase).
/// Stub implementation — Supabase sync not yet implemented.
abstract class BracketRemoteDatasource {
  Future<List<BracketModel>> getBracketsForDivision(String divisionId);
  Future<BracketModel?> getBracketById(String id);
  Future<void> insertBracket(BracketModel bracket);
  Future<void> updateBracket(BracketModel bracket);
  Future<void> deleteBracket(String id);
}

@LazySingleton(as: BracketRemoteDatasource)
class BracketRemoteDatasourceImplementation implements BracketRemoteDatasource {
  @override
  Future<List<BracketModel>> getBracketsForDivision(String divisionId) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<BracketModel?> getBracketById(String id) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<void> insertBracket(BracketModel bracket) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<void> updateBracket(BracketModel bracket) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }

  @override
  Future<void> deleteBracket(String id) async {
    throw UnimplementedError('Supabase bracket sync not yet implemented');
  }
}
