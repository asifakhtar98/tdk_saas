// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'invitation_model.freezed.dart';
part 'invitation_model.g.dart';

/// Data model for Invitation with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class InvitationModel with _$InvitationModel {
  /// Creates an [InvitationModel] instance.
  const factory InvitationModel({
    required String id,
    @JsonKey(name: 'organization_id') required String organizationId,
    required String email,
    required String role,
    @JsonKey(name: 'invited_by') required String invitedBy,
    required String status,
    required String token,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'is_demo_data') required bool isDemoData,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
  }) = _InvitationModel;

  /// Private constructor for freezed mixin.
  const InvitationModel._();

  /// Convert from Supabase JSON to [InvitationModel].
  factory InvitationModel.fromJson(Map<String, dynamic> json) =>
      _$InvitationModelFromJson(json);

  /// Convert from Drift-generated [InvitationEntry] to [InvitationModel].
  factory InvitationModel.fromDriftEntry(InvitationEntry entry) {
    return InvitationModel(
      id: entry.id,
      organizationId: entry.organizationId,
      email: entry.email,
      role: entry.role,
      invitedBy: entry.invitedBy,
      status: entry.status,
      token: entry.token,
      expiresAt: entry.expiresAt,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
      deletedAtTimestamp: entry.deletedAtTimestamp,
    );
  }

  /// Create [InvitationModel] from domain [InvitationEntity].
  factory InvitationModel.convertFromEntity(
    InvitationEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? deletedAtTimestamp,
  }) {
    return InvitationModel(
      id: entity.id,
      organizationId: entity.organizationId,
      email: entity.email,
      role: entity.role.value,
      invitedBy: entity.invitedBy,
      status: entity.status.value,
      token: entity.token,
      expiresAt: entity.expiresAt,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: entity.updatedAt,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
      deletedAtTimestamp: deletedAtTimestamp,
    );
  }

  /// Convert to Drift [InvitationsCompanion] for database operations.
  InvitationsCompanion toDriftCompanion() {
    return InvitationsCompanion.insert(
      id: id,
      organizationId: organizationId,
      email: email,
      role: Value(role),
      invitedBy: invitedBy,
      status: Value(status),
      token: token,
      expiresAt: expiresAt,
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [InvitationModel] to domain [InvitationEntity].
  InvitationEntity convertToEntity() {
    return InvitationEntity(
      id: id,
      organizationId: organizationId,
      email: email,
      role: UserRole.fromString(role),
      invitedBy: invitedBy,
      status: InvitationStatus.fromString(status),
      token: token,
      expiresAt: expiresAt,
      createdAt: createdAtTimestamp,
      updatedAt: updatedAtTimestamp,
    );
  }
}
