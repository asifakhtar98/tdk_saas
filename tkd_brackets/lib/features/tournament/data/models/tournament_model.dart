// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

part 'tournament_model.freezed.dart';
part 'tournament_model.g.dart';

/// Data model for Tournament with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class TournamentModel with _$TournamentModel {
  /// Creates a [TournamentModel] instance.
  const factory TournamentModel({
    required String id,
    required String organizationId,
    required String createdByUserId,
    required String name,
    String? description,
    String? venueName,
    String? venueAddress,
    DateTime? scheduledDate,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    @JsonKey(name: 'federation_type') required String federationType,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'is_template') required bool isTemplate,
    @JsonKey(name: 'template_id') String? templateId,
    @JsonKey(name: 'number_of_rings') required int numberOfRings,
    @JsonKey(name: 'settings_json') required Map<String, dynamic> settingsJson,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') required bool isDeleted,
    @JsonKey(name: 'is_demo_data') required bool isDemoData,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
  }) = _TournamentModel;

  /// Private constructor for freezed mixin.
  const TournamentModel._();

  /// Convert from Supabase JSON to [TournamentModel].
  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);

  /// Convert from Drift-generated [TournamentEntry] to [TournamentModel].
  factory TournamentModel.fromDriftEntry(TournamentEntry entry) {
    return TournamentModel(
      id: entry.id,
      organizationId: entry.organizationId,
      createdByUserId: entry.createdByUserId ?? '',
      name: entry.name,
      description: entry.description,
      venueName: entry.venueName,
      venueAddress: entry.venueAddress,
      scheduledDate: entry.scheduledDate,
      scheduledStartTime: entry.scheduledStartTime,
      scheduledEndTime: entry.scheduledEndTime,
      federationType: entry.federationType,
      status: entry.status,
      isTemplate: entry.isTemplate,
      templateId: entry.templateId,
      numberOfRings: entry.numberOfRings,
      settingsJson: _parseSettingsJson(entry.settingsJson),
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
      deletedAtTimestamp: entry.deletedAtTimestamp,
    );
  }

  /// Create [TournamentModel] from domain [TournamentEntity].
  factory TournamentModel.convertFromEntity(
    TournamentEntity entity, {
    int syncVersion = 1,
    bool isDeleted = false,
    bool isDemoData = false,
    DateTime? updatedAtTimestamp,
    DateTime? deletedAtTimestamp,
  }) {
    final now = DateTime.now();
    return TournamentModel(
      id: entity.id,
      organizationId: entity.organizationId,
      createdByUserId: entity.createdByUserId,
      name: entity.name,
      description: entity.description,
      venueName: entity.venueName,
      venueAddress: entity.venueAddress,
      scheduledDate: entity.scheduledDate,
      scheduledStartTime: entity.scheduledStartTime,
      scheduledEndTime: entity.scheduledEndTime,
      federationType: entity.federationType.value,
      status: entity.status.value,
      isTemplate: entity.isTemplate,
      templateId: entity.templateId,
      numberOfRings: entity.numberOfRings,
      settingsJson: entity.settingsJson,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      isDemoData: isDemoData,
      createdAtTimestamp: entity.createdAt,
      updatedAtTimestamp: updatedAtTimestamp ?? now,
      deletedAtTimestamp: deletedAtTimestamp,
    );
  }

  /// Convert to Drift [TournamentsCompanion] for database operations.
  TournamentsCompanion toDriftCompanion() {
    return TournamentsCompanion.insert(
      id: id,
      organizationId: organizationId,
      createdByUserId: Value(createdByUserId),
      name: name,
      description: Value(description),
      venueName: Value(venueName),
      venueAddress: Value(venueAddress),
      scheduledDate: Value(scheduledDate),
      scheduledStartTime: Value(scheduledStartTime),
      scheduledEndTime: Value(scheduledEndTime),
      federationType: Value(federationType),
      status: Value(status),
      isTemplate: Value(isTemplate),
      templateId: Value(templateId),
      numberOfRings: Value(numberOfRings),
      settingsJson: Value(settingsJson.toString()),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [TournamentModel] to domain [TournamentEntity].
  TournamentEntity convertToEntity() {
    return TournamentEntity(
      id: id,
      organizationId: organizationId,
      createdByUserId: createdByUserId,
      name: name,
      description: description,
      venueName: venueName,
      venueAddress: venueAddress,
      scheduledDate: scheduledDate,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      federationType: FederationType.fromString(federationType),
      status: TournamentStatus.fromString(status),
      isTemplate: isTemplate,
      templateId: templateId,
      numberOfRings: numberOfRings,
      settingsJson: settingsJson,
      createdAt: createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp,
    );
  }

  /// Parse settings JSON string to Map.
  static Map<String, dynamic> _parseSettingsJson(String jsonString) {
    try {
      if (jsonString.isEmpty || jsonString == '{}') {
        return {};
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException {
      return {};
    }
  }
}
