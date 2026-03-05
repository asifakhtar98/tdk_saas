import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class MarkNoShowUseCase {
  MarkNoShowUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  Future<Either<Failure, ParticipantEntity>> call(String participantId) async {
    final result = await _participantRepository.getParticipantById(
      participantId,
    );

    return result.fold(Left.new, (participant) async {
      final updatedParticipant = participant.copyWith(
        checkInStatus: ParticipantStatus.noShow,
        checkInAtTimestamp: null,
        dqReason: null,
      );

      return _participantRepository.updateParticipant(updatedParticipant);
    });
  }
}
