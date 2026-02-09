import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/user_model.dart';

/// Local datasource for user operations using Drift database.
///
/// Wraps existing [AppDatabase] methods with model conversion.
abstract class UserLocalDatasource {
  Future<UserModel?> getUserById(String id);
  Future<UserModel?> getUserByEmail(String email);
  Future<List<UserModel>> getUsersForOrganization(String organizationId);
  Future<void> insertUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String id);
}

@LazySingleton(as: UserLocalDatasource)
class UserLocalDatasourceImplementation implements UserLocalDatasource {
  UserLocalDatasourceImplementation(this._database);

  final AppDatabase _database;

  @override
  Future<UserModel?> getUserById(String id) async {
    final entry = await _database.getUserById(id);
    if (entry == null) return null;
    return UserModel.fromDriftEntry(entry);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final entry = await _database.getUserByEmail(email);
    if (entry == null) return null;
    return UserModel.fromDriftEntry(entry);
  }

  @override
  Future<List<UserModel>> getUsersForOrganization(String organizationId) async {
    final entries = await _database.getUsersForOrganization(organizationId);
    return entries.map(UserModel.fromDriftEntry).toList();
  }

  @override
  Future<void> insertUser(UserModel user) async {
    await _database.insertUser(user.toDriftCompanion());
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _database.updateUser(user.id, user.toDriftCompanion());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _database.softDeleteUser(id);
  }
}
