/// Sentinel value to explicitly set a nullable field to null in copyWith.
/// Using this instead of null allows distinguishing "not provided" from "set to null".
const _sentinel = Object();

class MatchEntity {
  final String id;
  final String bracketId;
  final int roundNumber;
  final int matchNumberInRound;
  final DateTime createdAtTimestamp;
  final DateTime updatedAtTimestamp;
  final String? participantRedId;
  final String? participantBlueId;
  final String? winnerId;
  final String? winnerAdvancesToMatchId;
  final String? loserAdvancesToMatchId;
  final int? scheduledRingNumber;
  final DateTime? scheduledTime;
  final MatchStatus status;
  final MatchResultType? resultType;
  final String? notes;
  final DateTime? startedAtTimestamp;
  final DateTime? completedAtTimestamp;
  final int syncVersion;
  final bool isDeleted;
  final DateTime? deletedAtTimestamp;
  final bool isDemoData;

  const MatchEntity({
    required this.id,
    required this.bracketId,
    required this.roundNumber,
    required this.matchNumberInRound,
    required this.createdAtTimestamp,
    required this.updatedAtTimestamp,
    this.participantRedId,
    this.participantBlueId,
    this.winnerId,
    this.winnerAdvancesToMatchId,
    this.loserAdvancesToMatchId,
    this.scheduledRingNumber,
    this.scheduledTime,
    this.status = MatchStatus.pending,
    this.resultType,
    this.notes,
    this.startedAtTimestamp,
    this.completedAtTimestamp,
    this.syncVersion = 1,
    this.isDeleted = false,
    this.deletedAtTimestamp,
    this.isDemoData = false,
  });

  /// copyWith that supports explicitly setting nullable fields to null.
  /// Pass the field normally to update it, or omit it to keep the current value.
  /// To explicitly set a field to null, pass null for that field.
  /// The sentinel pattern lets us distinguish "not provided" from "set to null".
  MatchEntity copyWith({
    String? id,
    String? bracketId,
    int? roundNumber,
    int? matchNumberInRound,
    DateTime? createdAtTimestamp,
    DateTime? updatedAtTimestamp,
    Object? participantRedId = _sentinel,
    Object? participantBlueId = _sentinel,
    Object? winnerId = _sentinel,
    Object? winnerAdvancesToMatchId = _sentinel,
    Object? loserAdvancesToMatchId = _sentinel,
    int? scheduledRingNumber,
    DateTime? scheduledTime,
    MatchStatus? status,
    Object? resultType = _sentinel,
    String? notes,
    DateTime? startedAtTimestamp,
    DateTime? completedAtTimestamp,
    int? syncVersion,
    bool? isDeleted,
    DateTime? deletedAtTimestamp,
    bool? isDemoData,
  }) {
    return MatchEntity(
      id: id ?? this.id,
      bracketId: bracketId ?? this.bracketId,
      roundNumber: roundNumber ?? this.roundNumber,
      matchNumberInRound: matchNumberInRound ?? this.matchNumberInRound,
      createdAtTimestamp: createdAtTimestamp ?? this.createdAtTimestamp,
      updatedAtTimestamp: updatedAtTimestamp ?? this.updatedAtTimestamp,
      participantRedId: identical(participantRedId, _sentinel) ? this.participantRedId : participantRedId as String?,
      participantBlueId: identical(participantBlueId, _sentinel) ? this.participantBlueId : participantBlueId as String?,
      winnerId: identical(winnerId, _sentinel) ? this.winnerId : winnerId as String?,
      winnerAdvancesToMatchId: identical(winnerAdvancesToMatchId, _sentinel) ? this.winnerAdvancesToMatchId : winnerAdvancesToMatchId as String?,
      loserAdvancesToMatchId: identical(loserAdvancesToMatchId, _sentinel) ? this.loserAdvancesToMatchId : loserAdvancesToMatchId as String?,
      scheduledRingNumber: scheduledRingNumber ?? this.scheduledRingNumber,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      resultType: identical(resultType, _sentinel) ? this.resultType : resultType as MatchResultType?,
      notes: notes ?? this.notes,
      startedAtTimestamp: startedAtTimestamp ?? this.startedAtTimestamp,
      completedAtTimestamp: completedAtTimestamp ?? this.completedAtTimestamp,
      syncVersion: syncVersion ?? this.syncVersion,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtTimestamp: deletedAtTimestamp ?? this.deletedAtTimestamp,
      isDemoData: isDemoData ?? this.isDemoData,
    );
  }
}

/// Match lifecycle status.
enum MatchStatus {
  pending('pending'),
  ready('ready'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const MatchStatus(this.value);
  final String value;
}

/// How a match was decided.
enum MatchResultType {
  points('points'),
  knockout('knockout'),
  disqualification('disqualification'),
  withdrawal('withdrawal'),
  refereeDecision('referee_decision'),
  bye('bye');

  const MatchResultType(this.value);
  final String value;
}
