import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/assign_to_ring_params.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class AssignToRingUseCase extends UseCase<DivisionEntity, AssignToRingParams> {
  AssignToRingUseCase(this._divisionRepository, this._tournamentRepository);

  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;

  @override
  Future<Either<Failure, DivisionEntity>> call(
    AssignToRingParams params,
  ) async {
    final validationFailure = await _validateParams(params);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final divisionResult = await _divisionRepository.getDivision(
      params.divisionId,
    );
    final division = divisionResult.fold((failure) => null, (d) => d);

    if (division == null) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Division not found',
          technicalDetails:
              'The specified division ID does not exist in the database',
          fieldErrors: {'divisionId': 'Invalid division ID'},
        ),
      );
    }

    final tournamentResult = await _tournamentRepository.getTournamentById(
      division.tournamentId,
    );
    final tournament = tournamentResult.fold((failure) => null, (t) => t);

    if (tournament != null && tournament.numberOfRings > 0) {
      if (params.ringNumber < 1 ||
          params.ringNumber > tournament.numberOfRings) {
        return Left(
          ValidationFailure(
            userFriendlyMessage:
                'Ring number must be between 1 and ${tournament.numberOfRings}',
            technicalDetails:
                'Tournament "${tournament.name}" has ${tournament.numberOfRings} rings configured',
            fieldErrors: const {
              'ringNumber': 'Invalid ring number for this tournament',
            },
          ),
        );
      }
    }

    final displayOrder =
        params.displayOrder ??
        await _getNextDisplayOrder(division.tournamentId, params.ringNumber);

    final updatedDivision = division.copyWith(
      assignedRingNumber: params.ringNumber,
      displayOrder: displayOrder,
      syncVersion: division.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    final result = await _divisionRepository.updateDivision(updatedDivision);

    return result;
  }

  Future<ValidationFailure?> _validateParams(AssignToRingParams params) async {
    if (params.ringNumber < 1) {
      return const ValidationFailure(
        userFriendlyMessage: 'Ring number must be at least 1',
        technicalDetails: 'Ring numbers are 1-based (Ring 1, Ring 2, etc.)',
        fieldErrors: {'ringNumber': 'Minimum ring number is 1'},
      );
    }

    if (params.divisionId.isEmpty) {
      return const ValidationFailure(
        userFriendlyMessage: 'Division ID is required',
        technicalDetails: 'Empty division ID provided',
        fieldErrors: {'divisionId': 'Division ID cannot be empty'},
      );
    }

    return null;
  }

  Future<int> _getNextDisplayOrder(String tournamentId, int ringNumber) async {
    final divisionsResult = await _divisionRepository.getDivisionsForTournament(
      tournamentId,
    );
    final divisions = divisionsResult.fold(
      (failure) => <DivisionEntity>[],
      (list) => list,
    );

    final ringDivisions = divisions.where(
      (d) => d.assignedRingNumber == ringNumber && d.isDeleted == false,
    );

    if (ringDivisions.isEmpty) {
      return 1;
    }

    final maxOrder = ringDivisions
        .map((d) => d.displayOrder ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return maxOrder + 1;
  }
}
