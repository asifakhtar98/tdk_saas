import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

@injectable
class DeleteParticipantUseCase {
  DeleteParticipantUseCase(this._participantRepository);

  final ParticipantRepository _participantRepository;

  Future<Either<Failure, Unit>> call(String id) async {
    return _participantRepository.deleteParticipant(id);
  }
}
