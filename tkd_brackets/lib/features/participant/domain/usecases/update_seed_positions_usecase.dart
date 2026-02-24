import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

part 'update_seed_positions_usecase.freezed.dart';

@freezed
class UpdateSeedPositionsParams with _$UpdateSeedPositionsParams {
  const factory UpdateSeedPositionsParams({
    /// The division whose participants are being reordered.
    required String divisionId,

    /// Ordered list of participant IDs in the desired seed order.
    /// Position 0 → seedNumber 1, Position 1 → seedNumber 2, etc.
    /// This list may be a SUBSET of all participants in the division —
    /// only the listed participants get new seed numbers.
    required List<String> participantIdsInOrder,
  }) = _UpdateSeedPositionsParams;
}

@injectable
class UpdateSeedPositionsUseCase {
  UpdateSeedPositionsUseCase(
    this._participantRepository,
    this._divisionRepository,
    this._tournamentRepository,
    this._userRepository,
  );

  final ParticipantRepository _participantRepository;
  final DivisionRepository _divisionRepository;
  final TournamentRepository _tournamentRepository;
  final UserRepository _userRepository;

  Future<Either<Failure, List<ParticipantEntity>>> call(
    UpdateSeedPositionsParams params,
  ) async {
    // Step 0: Validation (Fail Fast)
    if (params.divisionId.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Division ID is required',
          fieldErrors: {'divisionId': 'Division ID cannot be empty'},
        ),
      );
    }

    if (params.participantIdsInOrder.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Participant list is required for reordering',
          fieldErrors: {'participantIdsInOrder': 'List cannot be empty'},
        ),
      );
    }

    if (params.participantIdsInOrder.toSet().length !=
        params.participantIdsInOrder.length) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Duplicate participant IDs are not allowed',
          fieldErrors: {'participantIdsInOrder': 'Contains duplicate IDs'},
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
              'You must be logged in with an organization to update seed positions',
        ),
      );
    }

    // Step 2: Get division
    final divisionResult = await _divisionRepository.getDivisionById(
      params.divisionId,
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
              'You do not have permission to modify participants in this division',
        ),
      );
    }

    // Step 5: Division status check (write operation)
    if (division.status != DivisionStatus.setup &&
        division.status != DivisionStatus.ready) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Cannot reorder participants in a division that is in progress or completed',
          fieldErrors: {
            'divisionId': 'Division is not accepting modifications',
          },
        ),
      );
    }

    final updatedParticipants = <ParticipantEntity>[];

    // Step 6: Process updates sequentially
    for (var i = 0; i < params.participantIdsInOrder.length; i++) {
      final participantId = params.participantIdsInOrder[i];

      final participantResult = await _participantRepository.getParticipantById(
        participantId,
      );
      final participant = participantResult.fold((failure) => null, (p) => p);

      if (participant == null) {
        return Left(
          NotFoundFailure(
            userFriendlyMessage: 'Participant not found: $participantId',
          ),
        );
      }

      if (participant.divisionId != params.divisionId) {
        return Left(
          InputValidationFailure(
            userFriendlyMessage:
                'Participant ${participant.firstName} ${participant.lastName} '
                'does not belong to this division',
            fieldErrors: {
              'participantId':
                  'Participant $participantId belongs to division ${participant.divisionId}',
            },
          ),
        );
      }

      final updatedParticipant = participant.copyWith(
        seedNumber: i + 1, // 1-based seed numbering
        syncVersion: participant.syncVersion + 1,
        updatedAtTimestamp: DateTime.now(),
      );

      final updateResult = await _participantRepository.updateParticipant(
        updatedParticipant,
      );

      final savedParticipant = updateResult.fold((failure) => null, (p) => p);
      if (savedParticipant == null) {
        return updateResult.fold(
          Left.new,
          (_) => throw StateError('Unreachable'),
        );
      }

      updatedParticipants.add(savedParticipant);
    }

    return Right(updatedParticipants);
  }
}
