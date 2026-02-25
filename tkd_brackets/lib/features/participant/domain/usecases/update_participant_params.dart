import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

part 'update_participant_params.freezed.dart';

/// Parameters for updating an existing participant's editable fields.
///
/// Only non-null fields will be applied to the participant.
/// Fields set to null are considered "no change" (PATCH semantics).
@freezed
class UpdateParticipantParams with _$UpdateParticipantParams {
  const factory UpdateParticipantParams({
    /// The ID of the participant to update. REQUIRED.
    required String participantId,

    /// Updated first name. Null = no change.
    String? firstName,

    /// Updated last name. Null = no change.
    String? lastName,

    /// Updated date of birth. Null = no change.
    DateTime? dateOfBirth,

    /// Updated gender. Null = no change.
    Gender? gender,

    /// Updated weight in kg. Null = no change.
    double? weightKg,

    /// Updated school or dojang name. Null = no change.
    String? schoolOrDojangName,

    /// Updated belt rank. Null = no change.
    String? beltRank,

    /// Updated registration number. Null = no change.
    String? registrationNumber,

    /// Updated notes. Null = no change.
    String? notes,
  }) = _UpdateParticipantParams;
}
