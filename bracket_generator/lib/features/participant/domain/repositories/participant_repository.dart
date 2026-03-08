import 'package:fpdart/fpdart.dart';
import 'package:bracket_generator/core/error/failures.dart';
import '../../../../features/participant/domain/entities/participant_entity.dart';

abstract class ParticipantRepository {
  Future<Either<Failure, List<ParticipantEntity>>> getParticipantsForDivision(String divisionId);
}
