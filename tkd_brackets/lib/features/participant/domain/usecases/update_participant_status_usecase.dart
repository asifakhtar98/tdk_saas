import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class UpdateParticipantStatusUseCase {
  UpdateParticipantStatusUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  static const Map<ParticipantStatus, Set<ParticipantStatus>>
  _validTransitions = {
    ParticipantStatus.pending: {
      ParticipantStatus.checkedIn,
      ParticipantStatus.noShow,
      ParticipantStatus.withdrawn,
      ParticipantStatus.disqualified,
    },
    ParticipantStatus.checkedIn: {
      ParticipantStatus.withdrawn,
      ParticipantStatus.disqualified,
    },
    ParticipantStatus.noShow: {ParticipantStatus.pending},
    ParticipantStatus.withdrawn: {ParticipantStatus.pending},
    ParticipantStatus.disqualified: {ParticipantStatus.pending},
  };

  Future<Either<Failure, ParticipantEntity>> call({
    required String participantId,
    required ParticipantStatus newStatus,
    String? dqReason,
  }) async {
    if (newStatus == ParticipantStatus.disqualified) {
      final trimmedReason = dqReason?.trim() ?? '';
      if (trimmedReason.isEmpty) {
        return const Left(
          InputValidationFailure(
            userFriendlyMessage: 'Disqualification reason is required',
            fieldErrors: {'dqReason': 'Cannot be empty'},
          ),
        );
      }
    }

    final result = await _participantRepository.getParticipantById(
      participantId,
    );

    return result.fold(Left.new, (participant) async {
      if (!_isValidTransition(participant.checkInStatus, newStatus)) {
        return Left(
          InputValidationFailure(
            userFriendlyMessage: 'Invalid status transition',
            fieldErrors: {
              'status':
                  'Invalid: ${participant.checkInStatus.value}'
                  ' -> ${newStatus.value}',
            },
          ),
        );
      }

      final updatedParticipant = _buildUpdatedParticipant(
        participant,
        newStatus,
        dqReason?.trim(),
      );

      return _participantRepository.updateParticipant(updatedParticipant);
    });
  }

  bool _isValidTransition(ParticipantStatus from, ParticipantStatus to) {
    if (from == to) return true;
    return _validTransitions[from]?.contains(to) ?? false;
  }

  ParticipantEntity _buildUpdatedParticipant(
    ParticipantEntity participant,
    ParticipantStatus newStatus,
    String? trimmedDqReason,
  ) {
    DateTime? newCheckInAtTimestamp;
    String? newDqReason;

    switch (newStatus) {
      case ParticipantStatus.pending:
        newCheckInAtTimestamp = null;
        newDqReason = null;
      case ParticipantStatus.checkedIn:
        newCheckInAtTimestamp = DateTime.now();
        newDqReason = null;
      case ParticipantStatus.noShow:
        newCheckInAtTimestamp = null;
        newDqReason = null;
      case ParticipantStatus.withdrawn:
        newCheckInAtTimestamp = participant.checkInAtTimestamp;
        newDqReason = null;
      case ParticipantStatus.disqualified:
        newCheckInAtTimestamp = null;
        newDqReason = trimmedDqReason;
    }

    return participant.copyWith(
      checkInStatus: newStatus,
      checkInAtTimestamp: newCheckInAtTimestamp,
      dqReason: newDqReason,
      syncVersion: participant.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );
  }
}
