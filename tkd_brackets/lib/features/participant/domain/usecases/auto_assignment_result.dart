import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';

part 'auto_assignment_result.freezed.dart';

@freezed
class AutoAssignmentResult with _$AutoAssignmentResult {
  const factory AutoAssignmentResult({
    required List<AutoAssignmentMatch> matchedAssignments,
    required List<UnmatchedParticipant> unmatchedParticipants,
    required int totalParticipantsProcessed,
    required int totalDivisionsEvaluated,
  }) = _AutoAssignmentResult;
}

@freezed
class UnmatchedParticipant with _$UnmatchedParticipant {
  const factory UnmatchedParticipant({
    required String participantId,
    required String participantName,
    required String reason,
  }) = _UnmatchedParticipant;
}
