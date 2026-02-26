// Freezed uses @JsonKey on constructor parameters which triggers this lint.
// This is the documented freezed pattern and works correctly with code gen.
// ignore_for_file: invalid_annotation_target

import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

part 'match_model.freezed.dart';
part 'match_model.g.dart';

/// Data model for Match with JSON and database conversions.
@freezed
class MatchModel with _$MatchModel {
  const factory MatchModel({
    required String id,
    @JsonKey(name: 'bracket_id') required String bracketId,
    @JsonKey(name: 'round_number') required int roundNumber,
    @JsonKey(name: 'match_number_in_round') required int matchNumberInRound,
    @JsonKey(name: 'sync_version') required int syncVersion,
    @JsonKey(name: 'created_at_timestamp') required DateTime createdAtTimestamp,
    @JsonKey(name: 'updated_at_timestamp') required DateTime updatedAtTimestamp,
    @JsonKey(name: 'participant_red_id') String? participantRedId,
    @JsonKey(name: 'participant_blue_id') String? participantBlueId,
    @JsonKey(name: 'winner_id') String? winnerId,
    @JsonKey(name: 'winner_advances_to_match_id')
    String? winnerAdvancesToMatchId,
    @JsonKey(name: 'loser_advances_to_match_id') String? loserAdvancesToMatchId,
    @JsonKey(name: 'scheduled_ring_number') int? scheduledRingNumber,
    @JsonKey(name: 'scheduled_time') DateTime? scheduledTime,
    @Default('pending') String status,
    @JsonKey(name: 'result_type') String? resultType,
    String? notes,
    @JsonKey(name: 'started_at_timestamp') DateTime? startedAtTimestamp,
    @JsonKey(name: 'completed_at_timestamp') DateTime? completedAtTimestamp,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'deleted_at_timestamp') DateTime? deletedAtTimestamp,
    @JsonKey(name: 'is_demo_data') @Default(false) bool isDemoData,
  }) = _MatchModel;

  const MatchModel._();

  factory MatchModel.fromJson(Map<String, dynamic> json) =>
      _$MatchModelFromJson(json);

  /// Convert from Drift-generated [MatchEntry] to [MatchModel].
  factory MatchModel.fromDriftEntry(MatchEntry entry) {
    return MatchModel(
      id: entry.id,
      bracketId: entry.bracketId,
      roundNumber: entry.roundNumber,
      matchNumberInRound: entry.matchNumberInRound,
      participantRedId: entry.participantRedId,
      participantBlueId: entry.participantBlueId,
      winnerId: entry.winnerId,
      winnerAdvancesToMatchId: entry.winnerAdvancesToMatchId,
      loserAdvancesToMatchId: entry.loserAdvancesToMatchId,
      scheduledRingNumber: entry.scheduledRingNumber,
      scheduledTime: entry.scheduledTime,
      status: entry.status,
      resultType: entry.resultType,
      notes: entry.notes,
      startedAtTimestamp: entry.startedAtTimestamp,
      completedAtTimestamp: entry.completedAtTimestamp,
      syncVersion: entry.syncVersion,
      isDeleted: entry.isDeleted,
      deletedAtTimestamp: entry.deletedAtTimestamp,
      isDemoData: entry.isDemoData,
      createdAtTimestamp: entry.createdAtTimestamp,
      updatedAtTimestamp: entry.updatedAtTimestamp,
    );
  }

  /// Create [MatchModel] from domain [MatchEntity].
  factory MatchModel.convertFromEntity(MatchEntity entity) {
    return MatchModel(
      id: entity.id,
      bracketId: entity.bracketId,
      roundNumber: entity.roundNumber,
      matchNumberInRound: entity.matchNumberInRound,
      participantRedId: entity.participantRedId,
      participantBlueId: entity.participantBlueId,
      winnerId: entity.winnerId,
      winnerAdvancesToMatchId: entity.winnerAdvancesToMatchId,
      loserAdvancesToMatchId: entity.loserAdvancesToMatchId,
      scheduledRingNumber: entity.scheduledRingNumber,
      scheduledTime: entity.scheduledTime,
      status: entity.status.value,
      resultType: entity.resultType?.value,
      notes: entity.notes,
      startedAtTimestamp: entity.startedAtTimestamp,
      completedAtTimestamp: entity.completedAtTimestamp,
      syncVersion: entity.syncVersion,
      isDeleted: entity.isDeleted,
      deletedAtTimestamp: entity.deletedAtTimestamp,
      isDemoData: entity.isDemoData,
      createdAtTimestamp: entity.createdAtTimestamp,
      updatedAtTimestamp: entity.updatedAtTimestamp,
    );
  }

  /// Convert to Drift [MatchesCompanion] for database operations.
  /// ONLY id, bracketId, roundNumber, matchNumberInRound are required.
  /// ALL other fields use Value() wrappers (nullable or have defaults).
  MatchesCompanion toDriftCompanion() {
    return MatchesCompanion.insert(
      id: id,
      bracketId: bracketId,
      roundNumber: roundNumber,
      matchNumberInRound: matchNumberInRound,
      participantRedId: Value(participantRedId),
      participantBlueId: Value(participantBlueId),
      winnerId: Value(winnerId),
      winnerAdvancesToMatchId: Value(winnerAdvancesToMatchId),
      loserAdvancesToMatchId: Value(loserAdvancesToMatchId),
      scheduledRingNumber: Value(scheduledRingNumber),
      scheduledTime: Value(scheduledTime),
      status: Value(status),
      resultType: Value(resultType),
      notes: Value(notes),
      startedAtTimestamp: Value(startedAtTimestamp),
      completedAtTimestamp: Value(completedAtTimestamp),
      syncVersion: Value(syncVersion),
      isDeleted: Value(isDeleted),
      deletedAtTimestamp: Value(deletedAtTimestamp),
      isDemoData: Value(isDemoData),
    );
  }

  /// Convert [MatchModel] to domain [MatchEntity].
  MatchEntity convertToEntity() {
    return MatchEntity(
      id: id,
      bracketId: bracketId,
      roundNumber: roundNumber,
      matchNumberInRound: matchNumberInRound,
      participantRedId: participantRedId,
      participantBlueId: participantBlueId,
      winnerId: winnerId,
      winnerAdvancesToMatchId: winnerAdvancesToMatchId,
      loserAdvancesToMatchId: loserAdvancesToMatchId,
      scheduledRingNumber: scheduledRingNumber,
      scheduledTime: scheduledTime,
      status: MatchStatus.fromString(status),
      resultType:
          resultType != null ? MatchResultType.fromString(resultType!) : null,
      notes: notes,
      startedAtTimestamp: startedAtTimestamp,
      completedAtTimestamp: completedAtTimestamp,
      syncVersion: syncVersion,
      isDeleted: isDeleted,
      deletedAtTimestamp: deletedAtTimestamp,
      isDemoData: isDemoData,
      createdAtTimestamp: createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp,
    );
  }
}
