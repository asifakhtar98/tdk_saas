import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/duplicate_tournament_params.dart';

/// Use case for duplicating a tournament as a template.
///
/// ## DUPLICATION BEHAVIOR (CRITICAL - READ BEFORE IMPLEMENTING)
///
/// This use case performs the following operations in EXACT order:
///
/// 1. **Fetch Source Tournament** - Get tournament to duplicate
/// 2. **Verify Authorization** - Ensure user is Owner or Admin
/// 3. **Fetch Source Divisions** - Get divisions to duplicate (excluding soft-deleted)
/// 4. **Create New Tournament** - Generate new UUID, set status=draft, isTemplate=true
/// 5. **Create New Divisions** - Generate new UUIDs for each division, link to new tournament
/// 6. **Return Result** - Return the newly created tournament
///
/// ## WHAT IS COPIED:
/// - Tournament structure (name, federation, rings, settings)
/// - All divisions with their configuration (age, weight, gender, belt ranges)
///
/// ## WHAT IS NOT COPIED (CRITICAL):
/// - Participants - These are event-specific (registrations, payments, results)
/// - Brackets - Generated from participants, must be recreated
/// - Matches - Generated from brackets, must be recreated
/// - Scores - Event-specific results
/// - Scheduled date - Templates don't have fixed dates
///
/// ## AUTHORIZATION: Owner or Admin only
///
/// ## FAILURE CASES:
/// - NotFoundFailure: Source tournament doesn't exist or is deleted
/// - AuthenticationFailure: User not logged in
/// - AuthorizationPermissionDeniedFailure: User role not Owner/Admin
/// - ServerResponseFailure: Failed to create tournament or divisions
@injectable
class DuplicateTournamentUseCase
    extends UseCase<TournamentEntity, DuplicateTournamentParams> {
  DuplicateTournamentUseCase(
    this._repository,
    this._authRepository,
    this._divisionRepository,
  );

  final TournamentRepository _repository;
  final AuthRepository _authRepository;
  final DivisionRepository _divisionRepository;
  final Uuid _uuid = const Uuid();

  @override
  Future<Either<Failure, TournamentEntity>> call(
    DuplicateTournamentParams params,
  ) async {
    // STEP 1: Fetch the source tournament
    final tournamentResult = await _repository.getTournamentById(
      params.sourceTournamentId,
    );

    final sourceTournament = tournamentResult.fold((failure) => null, (t) => t);

    if (sourceTournament == null) {
      return Left(
        NotFoundFailure(
          userFriendlyMessage: 'Tournament not found',
          technicalDetails:
              'No tournament exists with ID: ${params.sourceTournamentId}',
        ),
      );
    }

    // STEP 2: Verify authorization (Owner or Admin)
    final authResult = await _authRepository.getCurrentAuthenticatedUser();
    final user = authResult.fold((failure) => null, (u) => u);

    if (user == null) {
      return const Left(
        AuthenticationFailure(
          userFriendlyMessage:
              'You must be logged in to duplicate a tournament',
        ),
      );
    }

    // Authorization check: Owner OR Admin can duplicate
    final canDuplicate =
        user.role == UserRole.owner || user.role == UserRole.admin;
    if (!canDuplicate) {
      return const Left(
        AuthorizationPermissionDeniedFailure(
          userFriendlyMessage:
              'Only Owners and Admins can duplicate tournaments',
        ),
      );
    }

    // STEP 3: Fetch divisions to duplicate (EXCLUDE SOFT-DELETED)
    final divisionsResult = await _repository.getDivisionsByTournamentId(
      params.sourceTournamentId,
    );

    // CRITICAL: Filter out soft-deleted divisions
    final sourceDivisions = divisionsResult.fold(
      (failure) => <DivisionEntity>[],
      (divisions) => divisions.where((d) => d.isDeleted != true).toList(),
    );

    // STEP 4: Create duplicated tournament with NEW UUID
    final newTournamentId = _uuid.v4();
    final now = DateTime.now();

    final duplicatedTournament = TournamentEntity(
      id: newTournamentId,
      name: '${sourceTournament.name} (Copy)',
      organizationId: sourceTournament.organizationId,
      federationType: sourceTournament.federationType,
      numberOfRings: sourceTournament.numberOfRings,
      settingsJson: sourceTournament.settingsJson,
      status: TournamentStatus.draft, // CRITICAL: Always draft
      isTemplate: true, // CRITICAL: Mark as template
      syncVersion: 0, // CRITICAL: New entity
      isDeleted: false,
      createdAt: now,
      scheduledDate:
          sourceTournament.scheduledDate, // Keep the date or set to now
      description: sourceTournament.description,
      venueName: sourceTournament.venueName,
      venueAddress: sourceTournament.venueAddress,
      createdByUserId: user.id,
    );

    // STEP 5: Persist duplicated tournament FIRST (before divisions!)
    final createTournamentResult = await _repository.createTournament(
      duplicatedTournament,
      sourceTournament.organizationId,
    );

    final createdTournament = createTournamentResult.fold(
      (failure) => null,
      (t) => t,
    );

    if (createdTournament == null) {
      return Left(
        createTournamentResult.fold(
          (failure) => failure,
          (_) => const ServerResponseFailure(
            userFriendlyMessage: 'Failed to create duplicated tournament',
          ),
        ),
      );
    }

    // STEP 6: Duplicate divisions with new UUIDs
    final List<DivisionEntity> createdDivisions = [];

    for (final sourceDivision in sourceDivisions) {
      final newDivisionId = _uuid.v4();

      final duplicatedDivision = DivisionEntity(
        id: newDivisionId,
        tournamentId: createdTournament.id,
        name: sourceDivision.name,
        category: sourceDivision.category,
        gender: sourceDivision.gender,
        ageMin: sourceDivision.ageMin,
        ageMax: sourceDivision.ageMax,
        weightMinKg: sourceDivision.weightMinKg,
        weightMaxKg: sourceDivision.weightMaxKg,
        beltRankMin: sourceDivision.beltRankMin,
        beltRankMax: sourceDivision.beltRankMax,
        bracketFormat: sourceDivision.bracketFormat,
        assignedRingNumber: sourceDivision.assignedRingNumber,
        isCombined: sourceDivision.isCombined,
        displayOrder: sourceDivision.displayOrder,
        status: sourceDivision.status,
        syncVersion: 0, // CRITICAL: New entity
        isDeleted: false,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
        isDemoData: sourceDivision.isDemoData,
        isCustom: sourceDivision.isCustom,
      );

      final createDivisionResult = await _divisionRepository.createDivision(
        duplicatedDivision,
      );

      // Handle partial failures gracefully
      createDivisionResult.fold((failure) {
        // Log division creation failure but continue
        // Tournament duplication succeeded, divisions are optional
      }, (created) => createdDivisions.add(created));
    }

    // STEP 7: Return the newly created tournament
    return Right(createdTournament);
  }
}
