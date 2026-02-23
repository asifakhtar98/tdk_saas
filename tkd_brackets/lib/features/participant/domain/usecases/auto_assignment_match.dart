import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_assignment_match.freezed.dart';

@freezed
class AutoAssignmentMatch with _$AutoAssignmentMatch {
  const factory AutoAssignmentMatch({
    required String participantId,
    required String divisionId,
    required String participantName,
    required String divisionName,
    required int matchScore,
    required Map<String, bool> criteriaMatched,
  }) = _AutoAssignmentMatch;
}
