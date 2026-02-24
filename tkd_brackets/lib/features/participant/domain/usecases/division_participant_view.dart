import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/get_division_participants_usecase.dart'
    show GetDivisionParticipantsUseCase;
import 'package:tkd_brackets/features/participant/domain/usecases/usecases.dart'
    show GetDivisionParticipantsUseCase;
import 'package:tkd_brackets/features/participant/participant.dart'
    show GetDivisionParticipantsUseCase;

part 'division_participant_view.freezed.dart';

/// Composite view model combining division metadata with its participant roster.
///
/// Used by [GetDivisionParticipantsUseCase] to return all information
/// needed for roster verification before bracket generation.
@freezed
class DivisionParticipantView with _$DivisionParticipantView {
  const factory DivisionParticipantView({
    /// The division being viewed.
    required DivisionEntity division,

    /// Ordered list of participants in this division.
    /// Sorted by seedNumber ASC, then lastName ASC (matching DB query).
    required List<ParticipantEntity> participants,

    /// Total count of participants (convenience field, equals participants.length).
    required int participantCount,
  }) = _DivisionParticipantView;
}
