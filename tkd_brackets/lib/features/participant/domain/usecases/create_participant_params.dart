import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

part 'create_participant_params.freezed.dart';

@freezed
class CreateParticipantParams with _$CreateParticipantParams {
  const factory CreateParticipantParams({
    required String divisionId,
    required String firstName,
    required String lastName,
    required String schoolOrDojangName,
    required String beltRank,
    DateTime? dateOfBirth,
    Gender? gender,
    double? weightKg,
    String? registrationNumber,
    String? notes,
  }) = _CreateParticipantParams;
}
