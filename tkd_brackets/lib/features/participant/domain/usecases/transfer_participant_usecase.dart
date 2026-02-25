import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_params.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class TransferParticipantUseCase {
  TransferParticipantUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  Future<Either<Failure, ParticipantEntity>> call(
    TransferParticipantParams params,
  ) async {
    // STEP 1: Validate participantId not empty
    if (params.participantId.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Participant ID is required',
          fieldErrors: {'participantId': 'Participant ID cannot be empty'},
        ),
      );
    }

    // STEP 2: Validate targetDivisionId not empty
    if (params.targetDivisionId.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Target division ID is required',
          fieldErrors: {
            'targetDivisionId': 'Target division ID cannot be empty',
          },
        ),
      );
    }

    // STEP 3: Auth — get current user
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);
    if (user == null || user.organizationId.isEmpty) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You must be logged in with an '
              'organization to transfer participants',
        ),
      );
    }

    // STEP 4: Get participant
    final participantResult = await _participantRepository.getParticipantById(
      params.participantId,
    );
    final participant = participantResult.fold((failure) => null, (p) => p);
    if (participant == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Participant not found'),
      );
    }

    // STEP 5: Check participant not already in target
    if (participant.divisionId == params.targetDivisionId) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Participant is already in the target division',
          fieldErrors: {'targetDivisionId': 'Same as current division'},
        ),
      );
    }

    // STEP 6: Get source division from participant.divisionId
    final sourceDivisionResult = await _divisionRepository.getDivisionById(
      participant.divisionId,
    );
    final sourceDivision = sourceDivisionResult.fold(
      (failure) => null,
      (d) => d,
    );
    if (sourceDivision == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Source division not found'),
      );
    }

    // STEP 7: Get target division from params.targetDivisionId
    final targetDivisionResult = await _divisionRepository.getDivisionById(
      params.targetDivisionId,
    );
    final targetDivision = targetDivisionResult.fold(
      (failure) => null,
      (d) => d,
    );
    if (targetDivision == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Target division not found'),
      );
    }

    // STEP 8: Verify same tournament
    if (sourceDivision.tournamentId != targetDivision.tournamentId) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Cannot transfer between divisions of different tournaments',
          fieldErrors: {
            'targetDivisionId':
                'Target division belongs to a different tournament',
          },
        ),
      );
    }

    // STEP 9: Get tournament for org verification
    final tournamentResult = await _tournamentRepository.getTournamentById(
      sourceDivision.tournamentId,
    );
    final tournament = tournamentResult.fold((failure) => null, (t) => t);
    if (tournament == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
      );
    }

    // STEP 10: Verify org ownership
    if (tournament.organizationId != user.organizationId) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You do not have permission to transfer '
              'participants in this tournament',
        ),
      );
    }

    // STEP 11: Check source division status
    if (sourceDivision.status != DivisionStatus.setup &&
        sourceDivision.status != DivisionStatus.ready) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Cannot transfer from a '
              'division that is in progress or completed',
          fieldErrors: {
            'sourceDivision':
                'Source division is not accepting modifications',
          },
        ),
      );
    }

    // STEP 12: Check target division status
    if (targetDivision.status != DivisionStatus.setup &&
        targetDivision.status != DivisionStatus.ready) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Cannot transfer to a division that is in progress or completed',
          fieldErrors: {
            'targetDivisionId':
                'Target division is not accepting modifications',
          },
        ),
      );
    }

    // STEP 13: Update participant with copyWith
    final updatedParticipant = participant.copyWith(
      divisionId: params.targetDivisionId,
      seedNumber: null, // Reset seed — it's division-specific
      syncVersion: participant.syncVersion + 1,
      updatedAtTimestamp: DateTime.now(),
    );

    // STEP 14: Persist and return
    return _participantRepository.updateParticipant(updatedParticipant);
  }
}
