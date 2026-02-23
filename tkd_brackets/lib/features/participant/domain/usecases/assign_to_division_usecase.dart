import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class AssignToDivisionUseCase {
  AssignToDivisionUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  Future<Either<Failure, ParticipantEntity>> call({
    required String participantId,
    required String divisionId,
  }) async {
    if (participantId.isEmpty || divisionId.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Invalid participant or division ID',
          fieldErrors: {'id': 'ID cannot be empty'},
        ),
      );
    }

    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);

    if (user == null || user.organizationId.isEmpty) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You must be logged in with an organization to '
              'assign participants',
        ),
      );
    }

    final participantResult = await _participantRepository.getParticipantById(
      participantId,
    );

    final participant = participantResult.fold((failure) => null, (p) => p);

    if (participant == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Participant not found'),
      );
    }

    final divisionResult = await _divisionRepository.getDivisionById(
      divisionId,
    );

    final division = divisionResult.fold((failure) => null, (d) => d);

    if (division == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Division not found'),
      );
    }

    final tournamentResult = await _tournamentRepository.getTournamentById(
      division.tournamentId,
    );

    final tournament = tournamentResult.fold((failure) => null, (t) => t);

    if (tournament == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
      );
    }

    if (tournament.organizationId != user.organizationId) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You do not have permission to assign participants '
              'to this division',
        ),
      );
    }

    if (division.status != DivisionStatus.setup &&
        division.status != DivisionStatus.ready) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Cannot assign to division that is in progress or completed',
          fieldErrors: {
            'divisionId': 'Division is not accepting new participants',
          },
        ),
      );
    }

    if (participant.divisionId == divisionId) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Participant is already assigned to this division',
          fieldErrors: {'divisionId': 'Duplicate assignment'},
        ),
      );
    }

    final updatedParticipant = participant.copyWith(
      divisionId: divisionId,
      syncVersion: participant.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    return _participantRepository.updateParticipant(updatedParticipant);
  }
}
