import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';

@injectable
class GetDivisionsUseCase extends UseCase<List<DivisionEntity>, String> {
  GetDivisionsUseCase(this._repository);

  final DivisionRepository _repository;

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(
    String tournamentId,
  ) async {
    return _repository.getDivisionsForTournament(tournamentId);
  }
}
