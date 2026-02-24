// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';

part 'organization_model.freezed.dart';
part 'organization_model.g.dart';

/// Data model for Organization with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class OrganizationModel with _$OrganizationModel {
  /// Creates an [OrganizationModel] instance.
  const factory OrganizationModel({
    required String id,
    required String name,
    required String slug,
    @JsonKey(name: 'subscription_tier') required String subscriptionTier,
    @JsonKey(name: 'subscription_status') required String subscriptionStatus,
    @JsonKey(name: 'max_tournaments_per_month')
    required int maxTournamentsPerMonth,
    @JsonKey(name: 'max_active_brackets') required int maxActiveBrackets,
    @JsonKey(name: 'max_participants_per_bracket')
    required int maxParticipantsPerBracket,
    @JsonKey(name: 'max_participants_per_tournament')
    required int maxParticipantsPerTournament,
    @JsonKey(name: 'max_scorers') required int maxScorers,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'is_demo_data') required bool isDemoData,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
  }) = _OrganizationModel;

  /// Private constructor for freezed mixin.
  const OrganizationModel._();

  /// Convert from Supabase JSON to [OrganizationModel].
  factory OrganizationModel.fromJson(Map<String, dynamic> json) =>
      _$OrganizationModelFromJson(json);

  /// Convert from Drift-generated [OrganizationEntry] to
  /// [OrganizationModel].
  factory OrganizationModel.fromDriftEntry(OrganizationEntry entry) {
    return OrganizationModel(
      id: entry.id,
      name: entry.name,
      slug: entry.slug,
      subscriptionTier: entry.subscriptionTier,
      subscriptionStatus: entry.subscriptionStatus,
      maxTournamentsPerMonth: entry.maxTournamentsPerMonth,
      maxActiveBrackets: entry.maxActiveBrackets,
      maxParticipantsPerBracket: entry.maxParticipantsPerBracket,
      maxParticipantsPerTournament: entry.maxParticipantsPerTournament,
      maxScorers: entry.maxScorers,
      isActive: entry.isActive,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
      deletedAtTimestamp: entry.deletedAtTimestamp,
    );
  }

  /// Create [OrganizationModel] from domain
  /// [OrganizationEntity].
  factory OrganizationModel.convertFromEntity(
    OrganizationEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? updatedAtTimestamp,
    DateTime? deletedAtTimestamp,
  }) {
    final now = DateTime.now();
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      subscriptionTier: entity.subscriptionTier.value,
      subscriptionStatus: entity.subscriptionStatus.value,
      maxTournamentsPerMonth: entity.maxTournamentsPerMonth,
      maxActiveBrackets: entity.maxActiveBrackets,
      maxParticipantsPerBracket: entity.maxParticipantsPerBracket,
      maxParticipantsPerTournament: entity.maxParticipantsPerTournament,
      maxScorers: entity.maxScorers,
      isActive: entity.isActive,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
      deletedAtTimestamp: deletedAtTimestamp,
    );
  }

  /// Convert to Drift [OrganizationsCompanion] for database
  /// operations.
  OrganizationsCompanion toDriftCompanion() {
    return OrganizationsCompanion.insert(
      id: id,
      name: name,
      slug: slug,
      subscriptionTier: Value(subscriptionTier),
      subscriptionStatus: Value(subscriptionStatus),
      maxTournamentsPerMonth: Value(maxTournamentsPerMonth),
      maxActiveBrackets: Value(maxActiveBrackets),
      maxParticipantsPerBracket: Value(maxParticipantsPerBracket),
      maxParticipantsPerTournament: Value(maxParticipantsPerTournament),
      maxScorers: Value(maxScorers),
      isActive: Value(isActive),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [OrganizationModel] to domain
  /// [OrganizationEntity].
  OrganizationEntity convertToEntity() {
    return OrganizationEntity(
      id: id,
      name: name,
      slug: slug,
      subscriptionTier: SubscriptionTier.fromString(subscriptionTier),
      subscriptionStatus: SubscriptionStatus.fromString(subscriptionStatus),
      maxTournamentsPerMonth: maxTournamentsPerMonth,
      maxActiveBrackets: maxActiveBrackets,
      maxParticipantsPerBracket: maxParticipantsPerBracket,
      maxParticipantsPerTournament: maxParticipantsPerTournament,
      maxScorers: maxScorers,
      isActive: isActive,
      createdAt: createdAtTimestamp,
    );
  }
}
