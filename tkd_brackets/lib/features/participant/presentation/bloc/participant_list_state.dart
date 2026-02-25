import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_event.dart';

part 'participant_list_state.freezed.dart';

/// Status of an asynchronous action (e.g., create, update, transfer).
enum ActionStatus { idle, inProgress, success, failure }

@freezed
class ParticipantListState with _$ParticipantListState {
  /// Initial state before any load is requested.
  const factory ParticipantListState.initial() = ParticipantListInitial;

  /// State when loading participants is in progress.
  const factory ParticipantListState.loadInProgress() =
      ParticipantListLoadInProgress;

  /// State when participants have been loaded successfully.
  const factory ParticipantListState.loadSuccess({
    required DivisionParticipantView view,
    required String searchQuery,
    required ParticipantFilter currentFilter,
    required ParticipantSort currentSort,
    required List<ParticipantEntity> filteredParticipants,
    @Default(ActionStatus.idle) ActionStatus actionStatus,
    String? actionMessage,
  }) = ParticipantListLoadSuccess;

  /// State when loading participants failed.
  const factory ParticipantListState.loadFailure({
    required String userFriendlyMessage,
    String? technicalDetails,
  }) = ParticipantListLoadFailure;
}
