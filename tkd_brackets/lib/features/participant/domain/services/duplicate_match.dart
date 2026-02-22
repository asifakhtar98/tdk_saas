import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/duplicate_match_type.dart';

part 'duplicate_match.freezed.dart';

@freezed
class DuplicateMatch with _$DuplicateMatch {
  const factory DuplicateMatch({
    required ParticipantEntity existingParticipant,
    required DuplicateMatchType matchType,
    required double confidenceScore,
    required Map<String, String> matchedFields,
  }) = _DuplicateMatch;

  const DuplicateMatch._();

  bool get isHighConfidence => confidenceScore >= 0.8;
  bool get isMediumConfidence =>
      confidenceScore >= 0.5 && confidenceScore < 0.8;
  bool get isLowConfidence => confidenceScore < 0.5;
}
