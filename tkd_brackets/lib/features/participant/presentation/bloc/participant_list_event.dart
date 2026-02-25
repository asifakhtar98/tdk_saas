import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_params.dart';

part 'participant_list_event.freezed.dart';

/// Filter options for the participant list.
enum ParticipantFilter { all, active, noShow, disqualified, checkedIn }

/// Sort options for the participant list.
enum ParticipantSort { nameAsc, nameDesc, dojangAsc, beltAsc, seedAsc }

@freezed
class ParticipantListEvent with _$ParticipantListEvent {
  /// Request to load participants for a specific division.
  const factory ParticipantListEvent.loadRequested({
    required String divisionId,
  }) = ParticipantListLoadRequested;

  /// Request to refresh the current list of participants.
  const factory ParticipantListEvent.refreshRequested() =
      ParticipantListRefreshRequested;

  /// Request to update the search query.
  const factory ParticipantListEvent.searchQueryChanged(String query) =
      ParticipantListSearchQueryChanged;

  /// Request to change the current filter.
  const factory ParticipantListEvent.filterChanged(ParticipantFilter filter) =
      ParticipantListFilterChanged;

  /// Request to change the current sort order.
  const factory ParticipantListEvent.sortChanged(ParticipantSort sort) =
      ParticipantListSortChanged;

  /// Request to create a new participant.
  const factory ParticipantListEvent.createRequested({
    required CreateParticipantParams params,
  }) = ParticipantListCreateRequested;

  /// Request to edit an existing participant.
  const factory ParticipantListEvent.editRequested({
    required UpdateParticipantParams params,
  }) = ParticipantListEditRequested;

  /// Request to change a participant's status.
  const factory ParticipantListEvent.statusChangeRequested({
    required String participantId,
    required ParticipantStatus newStatus,
    String? dqReason,
  }) = ParticipantListStatusChangeRequested;

  /// Request to transfer a participant to another division.
  const factory ParticipantListEvent.transferRequested({
    required TransferParticipantParams params,
  }) = ParticipantListTransferRequested;

  /// Request to remove a participant (soft-delete).
  const factory ParticipantListEvent.removeRequested({
    required String participantId,
  }) = ParticipantListRemoveRequested;
}
