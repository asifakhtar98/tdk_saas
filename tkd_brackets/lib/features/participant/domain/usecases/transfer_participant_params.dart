import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_participant_params.freezed.dart';

/// Parameters for transferring a participant to a different division.
@freezed
class TransferParticipantParams with _$TransferParticipantParams {
  const factory TransferParticipantParams({
    /// The ID of the participant to transfer.
    required String participantId,

    /// The target division to transfer the participant to.
    required String targetDivisionId,
  }) = _TransferParticipantParams;
}
