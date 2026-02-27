// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'dart:convert';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';

part 'bracket_model.freezed.dart';
part 'bracket_model.g.dart';

/// Data model for Bracket with JSON and database conversions.
@freezed
class BracketModel with _$BracketModel {
  const factory BracketModel({
    required String id,
    @JsonKey(name: 'division_id') required String divisionId,
    @JsonKey(name: 'bracket_type') required String bracketType,
    @JsonKey(name: 'total_rounds') required int totalRounds,
    @JsonKey(name: 'sync_version') required int syncVersion, @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp, @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp, @JsonKey(name: 'is_finalized') @Default(false) bool isFinalized,
    @JsonKey(name: 'pool_identifier') String? poolIdentifier,
    @JsonKey(name: 'generated_at_timestamp') DateTime? generatedAtTimestamp,
    @JsonKey(name: 'finalized_at_timestamp') DateTime? finalizedAtTimestamp,
    @JsonKey(name: 'bracket_data_json') String? bracketDataJson,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
    @JsonKey(name: 'is_demo_data') @Default(false) bool isDemoData,
  }) = _BracketModel;

  const BracketModel._();

  factory BracketModel.fromJson(Map<String, dynamic> json) =>
      _$BracketModelFromJson(json);

  /// Convert from Drift-generated [BracketEntry] to [BracketModel].
  factory BracketModel.fromDriftEntry(BracketEntry entry) {
    return BracketModel(
      id: entry.id,
      divisionId: entry.divisionId,
      bracketType: entry.bracketType,
      poolIdentifier: entry.poolIdentifier,
      totalRounds: entry.totalRounds,
      isFinalized: entry.isFinalized,
      generatedAtTimestamp: entry.generatedAtTimestamp,
      finalizedAtTimestamp: entry.finalizedAtTimestamp,
      bracketDataJson: entry.bracketDataJson,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
    );
  }

  /// Create [BracketModel] from domain [BracketEntity].
  factory BracketModel.convertFromEntity(BracketEntity entity) {
    return BracketModel(
      id: entity.id,
      divisionId: entity.divisionId,
      bracketType: entity.bracketType.value,
      poolIdentifier: entity.poolIdentifier,
      totalRounds: entity.totalRounds,
      isFinalized: entity.isFinalized,
      generatedAtTimestamp: entity.generatedAtTimestamp,
      finalizedAtTimestamp: entity.finalizedAtTimestamp,
      bracketDataJson: entity.bracketDataJson != null
          ? jsonEncode(entity.bracketDataJson)
          : null,
      syncVersion: entity.syncVersion,
      isDeleted: entity.isDeleted,
      deletedAtTimestamp: entity.deletedAtTimestamp,
      isDemoData: entity.isDemoData,
      createdAtTimestamp: entity.createdAtTimestamp,
      updatedAtTimestamp: entity.updatedAtTimestamp,
    );
  }

  /// Convert to Drift [BracketsCompanion] for database operations.
  BracketsCompanion toDriftCompanion() {
    return BracketsCompanion.insert(
      id: id,
      divisionId: divisionId,
      bracketType: bracketType,
      totalRounds: totalRounds,
      poolIdentifier: Value(poolIdentifier),
      isFinalized: Value(isFinalized),
      generatedAtTimestamp: Value(generatedAtTimestamp),
      finalizedAtTimestamp: Value(finalizedAtTimestamp),
      bracketDataJson: Value(bracketDataJson),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      deletedAtTimestamp: Value(deletedAtTimestamp),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [BracketModel] to domain [BracketEntity].
  BracketEntity convertToEntity() {
    return BracketEntity(
      id: id,
      divisionId: divisionId,
      bracketType: BracketType.fromString(bracketType),
      poolIdentifier: poolIdentifier,
      totalRounds: totalRounds,
      isFinalized: isFinalized,
      generatedAtTimestamp: generatedAtTimestamp,
      finalizedAtTimestamp: finalizedAtTimestamp,
      bracketDataJson: bracketDataJson != null
          ? jsonDecode(bracketDataJson!) as Map<String, dynamic>
          : null,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      deletedAtTimestamp: deletedAtTimestamp,
      isDemoData: isDemoData,
      createdAtTimestamp: createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp,
    );
  }
}
