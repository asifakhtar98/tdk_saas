import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

part 'bracket_generation_event.freezed.dart';

@freezed
class BracketGenerationEvent with _$BracketGenerationEvent {
  const factory BracketGenerationEvent.loadRequested({
    required String divisionId,
  }) = BracketGenerationLoadRequested;

  const factory BracketGenerationEvent.formatSelected(
    BracketFormat format,
  ) = BracketGenerationFormatSelected;

  const factory BracketGenerationEvent.generateRequested() =
      BracketGenerationGenerateRequested;

  const factory BracketGenerationEvent.regenerateRequested() =
      BracketGenerationRegenerateRequested;

  const factory BracketGenerationEvent.navigateToBracketRequested(
    String bracketId,
  ) = BracketGenerationNavigateToBracketRequested;
}
