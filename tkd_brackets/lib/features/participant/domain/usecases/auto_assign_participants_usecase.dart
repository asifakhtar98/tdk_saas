import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/auto_assignment_service.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_result.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

@injectable
class AutoAssignParticipantsUseCase {
  AutoAssignParticipantsUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
    this._autoAssignmentService,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;
  final AutoAssignmentService _autoAssignmentService;

  Future<Either<Failure, AutoAssignmentResult>> call({
    required String tournamentId,
    required List<String> participantIds,
    bool dryRun = false,
  }) async {
    final userResult = await _userRepository.getCurrentUser();
    final user = userResult.fold((failure) => null, (user) => user);

    if (user == null || user.organizationId.isEmpty) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage: 'You must be logged in with an organization',
        ),
      );
    }

    final tournamentResult = await _tournamentRepository.getTournamentById(
      tournamentId,
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
              'You do not have permission to access this tournament',
        ),
      );
    }

    final divisionsResult = await _divisionRepository.getDivisionsForTournament(
      tournamentId,
    );

    if (divisionsResult.isLeft()) {
      return divisionsResult.fold(
        (failure) => Left(failure),
        (_) => const Left(
          ServerConnectionFailure(
            userFriendlyMessage: 'Failed to load divisions',
          ),
        ),
      );
    }

    final allDivisions = divisionsResult.getOrElse((_) => []);

    final eligibleDivisions = allDivisions
        .where(
          (d) =>
              d.status == DivisionStatus.setup ||
              d.status == DivisionStatus.ready,
        )
        .toList();

    if (eligibleDivisions.isEmpty) {
      final unmatched = participantIds
          .map(
            (id) => UnmatchedParticipant(
              participantId: id,
              participantName: 'Unknown',
              reason: allDivisions.isEmpty
                  ? 'No divisions exist in tournament'
                  : 'No divisions available for assignment',
            ),
          )
          .toList();

      return Right(
        AutoAssignmentResult(
          matchedAssignments: [],
          unmatchedParticipants: unmatched,
          totalParticipantsProcessed: participantIds.length,
          totalDivisionsEvaluated: 0,
        ),
      );
    }

    final matchedAssignments = <AutoAssignmentMatch>[];
    final unmatchedParticipants = <UnmatchedParticipant>[];

    for (final participantId in participantIds) {
      final participantResult = await _participantRepository.getParticipantById(
        participantId,
      );

      await participantResult.fold(
        (failure) async {
          unmatchedParticipants.add(
            UnmatchedParticipant(
              participantId: participantId,
              participantName: 'Unknown',
              reason: 'Participant not found',
            ),
          );
        },
        (participant) async {
          AutoAssignmentMatch? bestMatch;
          for (final division in eligibleDivisions) {
            final match = _autoAssignmentService.evaluateMatch(
              participant,
              division,
            );
            if (match != null) {
              if (bestMatch == null ||
                  match.matchScore > bestMatch.matchScore) {
                bestMatch = match;
              }
            }
          }

          if (bestMatch != null) {
            matchedAssignments.add(bestMatch);

            if (!dryRun) {
              final updatedParticipant = participant.copyWith(
                divisionId: bestMatch.divisionId,
                syncVersion: participant.syncVersion + 1,
                updatedAtTimestamp: DateTime.now(),
              );
              await _participantRepository.updateParticipant(
                updatedParticipant,
              );
            }
          } else {
            unmatchedParticipants.add(
              UnmatchedParticipant(
                participantId: participant.id,
                participantName:
                    '${participant.firstName} ${participant.lastName}',
                reason: _autoAssignmentService.determineUnmatchedReason(
                  participant,
                  eligibleDivisions,
                ),
              ),
            );
          }
        },
      );
    }

    return Right(
      AutoAssignmentResult(
        matchedAssignments: matchedAssignments,
        unmatchedParticipants: unmatchedParticipants,
        totalParticipantsProcessed: participantIds.length,
        totalDivisionsEvaluated: eligibleDivisions.length,
      ),
    );
  }
}
