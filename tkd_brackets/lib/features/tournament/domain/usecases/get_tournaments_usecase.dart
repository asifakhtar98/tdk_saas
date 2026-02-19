import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class GetTournamentsUseCase extends UseCase<List<TournamentEntity>, String> {
  GetTournamentsUseCase(this._repository);

  final TournamentRepository _repository;

  @override
  Future<Either<Failure, List<TournamentEntity>>> call(
    String organizationId,
  ) async {
    return _repository.getTournamentsForOrganization(organizationId);
  }
}
