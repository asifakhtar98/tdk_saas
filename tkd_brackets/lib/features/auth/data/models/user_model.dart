// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data model for User with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class UserModel with _$UserModel {
  /// Creates a [UserModel] instance.
  const factory UserModel({
    required String id,
    required String email,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'organization_id') required String organizationId,
    required String role,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'is_demo_data') required bool isDemoData,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'last_sign_in_at_timestamp') DateTime? lastSignInAtTimestamp,
  }) = _UserModel;

  /// Private constructor for freezed mixin.
  const UserModel._();

  /// Convert from Supabase JSON to [UserModel].
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Convert from Drift-generated [UserEntry] to [UserModel].
  factory UserModel.fromDriftEntry(UserEntry entry) {
    return UserModel(
      id: entry.id,
      email: entry.email,
      displayName: entry.displayName,
      organizationId: entry.organizationId,
      role: entry.role,
      avatarUrl: entry.avatarUrl,
      isActive: entry.isActive,
      lastSignInAtTimestamp: entry.lastSignInAtTimestamp,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
    );
  }

  /// Create [UserModel] from domain [UserEntity].
  factory UserModel.convertFromEntity(
    UserEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? updatedAtTimestamp,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      organizationId: entity.organizationId,
      role: entity.role.value,
      avatarUrl: entity.avatarUrl,
      isActive: entity.isActive,
      lastSignInAtTimestamp: entity.lastSignInAt,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
    );
  }

  /// Convert to Drift [UsersCompanion] for database operations.
  UsersCompanion toDriftCompanion() {
    return UsersCompanion.insert(
      id: id,
      email: email,
      displayName: displayName,
      organizationId: organizationId,
      role: Value(role),
      avatarUrl: Value(avatarUrl),
      isActive: Value(isActive),
      lastSignInAtTimestamp: Value(lastSignInAtTimestamp),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [UserModel] to domain [UserEntity].
  UserEntity convertToEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      organizationId: organizationId,
      role: UserRole.fromString(role),
      avatarUrl: avatarUrl,
      isActive: isActive,
      lastSignInAt: lastSignInAtTimestamp,
      createdAt: createdAtTimestamp,
    );
  }
}
