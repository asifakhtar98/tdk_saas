import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

part 'bracket_generation_state.freezed.dart';

@freezed
class BracketGenerationState with _$BracketGenerationState {
  const factory BracketGenerationState.initial() = BracketGenerationInitial;

  const factory BracketGenerationState.loadInProgress() =
      BracketGenerationLoadInProgress;

  const factory BracketGenerationState.loadSuccess({
    required DivisionEntity division,
    required List<ParticipantEntity> participants,
    required List<BracketEntity> existingBrackets,
    BracketFormat? selectedFormat,
  }) = BracketGenerationLoadSuccess;

  const factory BracketGenerationState.generationInProgress() =
      BracketGenerationInProgress;

  const factory BracketGenerationState.generationSuccess({
    required String generatedBracketId,
  }) = BracketGenerationSuccess;

  const factory BracketGenerationState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = BracketGenerationLoadFailure;
}
