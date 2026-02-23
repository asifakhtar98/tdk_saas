import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class DisqualifyParticipantUseCase {
  DisqualifyParticipantUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  Future<Either<Failure, ParticipantEntity>> call({
    required String participantId,
    required String dqReason,
  }) async {
    final trimmedReason = dqReason.trim();
    if (trimmedReason.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Disqualification reason is required',
          fieldErrors: {'dqReason': 'Cannot be empty'},
        ),
      );
    }

    final result = await _participantRepository.getParticipantById(
      participantId,
    );

    return result.fold(Left.new, (participant) async {
      final updatedParticipant = participant.copyWith(
        checkInStatus: ParticipantStatus.disqualified,
        checkInAtTimestamp: null,
        dqReason: trimmedReason,
        syncVersion: participant.syncVersion + 1,
        updatedAtTimestamp: DateTime.now(),
      );

      return _participantRepository.updateParticipant(updatedParticipant);
    });
  }
}
