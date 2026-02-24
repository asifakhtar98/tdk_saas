import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class GetDivisionParticipantsUseCase {
  GetDivisionParticipantsUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  Future<Either<Failure, DivisionParticipantView>> call(
    String divisionId,
  ) async {
    // Step 0: Validation
    if (divisionId.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Division ID is required',
          fieldErrors: {'divisionId': 'Division ID cannot be empty'},
        ),
      );
    }

    // Step 1: Get current user
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);
    if (user == null || user.organizationId.isEmpty) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You must be logged in with an organization to view division participants',
        ),
      );
    }

    // Step 2: Get division
    final divisionResult = await _divisionRepository.getDivisionById(
      divisionId,
    );
    final division = divisionResult.fold((failure) => null, (d) => d);
    if (division == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Division not found'),
      );
    }

    // Step 3: Get tournament for org verification
    final tournamentResult = await _tournamentRepository.getTournamentById(
      division.tournamentId,
    );
    final tournament = tournamentResult.fold((failure) => null, (t) => t);
    if (tournament == null) {
      return const Left(
        NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
      );
    }

    // Step 4: Verify org ownership
    if (tournament.organizationId != user.organizationId) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'You do not have permission to view participants in this division',
        ),
      );
    }

    // Step 5: Fetch participants — use ParticipantRepository (returns domain entities)
    final participantsResult = await _participantRepository
        .getParticipantsForDivision(divisionId);

    return participantsResult.fold(
      Left.new,
      (participants) => Right(
        DivisionParticipantView(
          division: division,
          participants: participants,
          participantCount: participants.length,
        ),
      ),
    );
  }
}
