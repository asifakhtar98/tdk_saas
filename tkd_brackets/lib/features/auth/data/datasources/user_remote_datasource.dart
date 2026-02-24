import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';

/// Remote datasource for user operations using Supabase.
///
/// Note: Most user data operations go through RLS-protected tables.
/// The auth.users table is managed separately by Supabase Auth.
abstract class UserRemoteDatasource {
  Future<UserModel?> getUserById(String id);
  Future<UserModel?> getUserByEmail(String email);
  Future<List<UserModel>> getUsersForOrganization(String organizationId);
  Future<UserModel> insertUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String id);

  /// Get the currently authenticated user from Supabase.
  /// Returns null if no active session.
  User? get currentAuthUser;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges;
}

@LazySingleton(as: UserRemoteDatasource)
class UserRemoteDatasourceImplementation implements UserRemoteDatasource {
  UserRemoteDatasourceImplementation(this._supabase);

  final SupabaseClient _supabase;

  static const String _tableName = 'users';

  @override
  User? get currentAuthUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  @override
  Future<UserModel?> getUserById(String id) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('email', email)
        .eq('is_deleted', false)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<List<UserModel>> getUsersForOrganization(String organizationId) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('organization_id', organizationId)
        .eq('is_deleted', false)
        .order('display_name');

    return response.map<UserModel>(UserModel.fromJson).toList();
  }

  @override
  Future<UserModel> insertUser(UserModel user) async {
    final response = await _supabase
        .from(_tableName)
        .insert(user.toJson())
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final response = await _supabase
        .from(_tableName)
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  @override
  Future<void> deleteUser(String id) async {
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
