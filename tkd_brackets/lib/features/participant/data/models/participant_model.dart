// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

part 'participant_model.freezed.dart';
part 'participant_model.g.dart';

/// Data model for Participant with JSON and database conversions.
///
/// Uses freezed for immutability and json_serializable for JSON handling.
/// Uses @JsonKey for each field to map to snake_case JSON keys.
@freezed
class ParticipantModel with _$ParticipantModel {
  /// Creates a [ParticipantModel] instance.
  const factory ParticipantModel({
    required String id,
    @JsonKey(name: 'division_id') required String divisionId,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'date_of_birth') DateTime? dateOfBirth,
    String? gender,
    @JsonKey(name: 'weight_kg') double? weightKg,
    @JsonKey(name: 'school_or_dojang_name') String? schoolOrDojangName,
    @JsonKey(name: 'belt_rank') String? beltRank,
    @JsonKey(name: 'seed_number') int? seedNumber,
    @JsonKey(name: 'registration_number') String? registrationNumber,
    @JsonKey(name: 'is_bye') @Default(false) bool isBye,
    @JsonKey(name: 'check_in_status') required String checkInStatus,
    @JsonKey(name: 'check_in_at_timestamp') DateTime? checkInAtTimestamp,
    @JsonKey(name: 'dq_reason') String? dqReason,
    @JsonKey(name: 'photo_url') String? photoUrl,
    String? notes,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
    @JsonKey(name: 'is_demo_data') @Default(false) bool isDemoData,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
  }) = _ParticipantModel;

  /// Private constructor for freezed mixin.
  const ParticipantModel._();

  /// Convert from Supabase JSON to [ParticipantModel].
  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  /// Convert from Drift-generated [ParticipantEntry] to [ParticipantModel].
  factory ParticipantModel.fromDriftEntry(ParticipantEntry entry) {
    return ParticipantModel(
      id: entry.id,
      divisionId: entry.divisionId,
      firstName: entry.firstName,
      lastName: entry.lastName,
      dateOfBirth: entry.dateOfBirth,
      gender: entry.gender,
      weightKg: entry.weightKg,
      schoolOrDojangName: entry.schoolOrDojangName,
      beltRank: entry.beltRank,
      seedNumber: entry.seedNumber,
      registrationNumber: entry.registrationNumber,
      isBye: entry.isBye,
      checkInStatus: entry.checkInStatus,
      checkInAtTimestamp: entry.checkInAtTimestamp,
      dqReason: entry.dqReason,
      photoUrl: entry.photoUrl,
      notes: entry.notes,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
    );
  }

  /// Create [ParticipantModel] from domain [ParticipantEntity].
  factory ParticipantModel.convertFromEntity(ParticipantEntity entity) {
    return ParticipantModel(
      id: entity.id,
      divisionId: entity.divisionId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender?.value,
      weightKg: entity.weightKg,
      schoolOrDojangName: entity.schoolOrDojangName,
      beltRank: entity.beltRank,
      seedNumber: entity.seedNumber,
      registrationNumber: entity.registrationNumber,
      isBye: entity.isBye,
      checkInStatus: entity.checkInStatus.value,
      checkInAtTimestamp: entity.checkInAtTimestamp,
      dqReason: entity.dqReason,
      photoUrl: entity.photoUrl,
      notes: entity.notes,
      syncVersion: entity.syncVersion,
      isDeleted: entity.isDeleted,
      deletedAtTimestamp: entity.deletedAtTimestamp,
      isDemoData: entity.isDemoData,
      createdAtTimestamp: entity.createdAtTimestamp,
      updatedAtTimestamp: entity.updatedAtTimestamp,
    );
  }

  /// Convert to Drift [ParticipantsCompanion] for database operations.
  ParticipantsCompanion toDriftCompanion() {
    return ParticipantsCompanion.insert(
      id: id,
      divisionId: divisionId,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: Value(dateOfBirth),
      gender: Value(gender),
      weightKg: Value(weightKg),
      schoolOrDojangName: Value(schoolOrDojangName),
      beltRank: Value(beltRank),
      seedNumber: Value(seedNumber),
      registrationNumber: Value(registrationNumber),
      isBye: Value(isBye),
      checkInStatus: Value(checkInStatus),
      checkInAtTimestamp: Value(checkInAtTimestamp),
      dqReason: Value(dqReason),
      photoUrl: Value(photoUrl),
      notes: Value(notes),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      deletedAtTimestamp: Value(deletedAtTimestamp),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [ParticipantModel] to domain [ParticipantEntity].
  ParticipantEntity convertToEntity() {
    return ParticipantEntity(
      id: id,
      divisionId: divisionId,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender != null ? Gender.fromString(gender!) : null,
      weightKg: weightKg,
      schoolOrDojangName: schoolOrDojangName,
      beltRank: beltRank,
      seedNumber: seedNumber,
      registrationNumber: registrationNumber,
      isBye: isBye,
      checkInStatus: ParticipantStatus.fromString(checkInStatus),
      checkInAtTimestamp: checkInAtTimestamp,
      dqReason: dqReason,
      photoUrl: photoUrl,
      notes: notes,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      deletedAtTimestamp: deletedAtTimestamp,
      isDemoData: isDemoData,
      createdAtTimestamp: createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp,
    );
  }
}
