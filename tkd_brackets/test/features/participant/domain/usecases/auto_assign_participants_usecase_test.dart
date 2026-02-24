import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';
import 'package:tkd_brackets/features/participant/domain/services/auto_assignment_service.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assign_participants_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/auto_assignment_match.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class MockAutoAssignmentService extends Mock implements AutoAssignmentService {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  late AutoAssignParticipantsUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockTournamentRepository mockTournamentRepository;
  late MockDivisionRepository mockDivisionRepository;
  late MockParticipantRepository mockParticipantRepository;
  late MockAutoAssignmentService mockService;

  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
    registerFallbackValue(FakeDivisionEntity());
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockTournamentRepository = MockTournamentRepository();
    mockDivisionRepository = MockDivisionRepository();
    mockParticipantRepository = MockParticipantRepository();
    mockService = MockAutoAssignmentService();
    useCase = AutoAssignParticipantsUseCase(
      mockParticipantRepository,
      mockDivisionRepository,
      mockTournamentRepository,
      mockUserRepository,
      mockService,
    );
  });

  UserEntity createTestUser({
    String id = 'user-1',
    String organizationId = 'org-1',
  }) {
    return UserEntity(
      id: id,
      email: 'test@test.com',
      displayName: 'Test User',
      organizationId: organizationId,
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  TournamentEntity createTestTournament({
    String id = 'tournament-1',
    String organizationId = 'org-1',
  }) {
    return TournamentEntity(
      id: id,
      organizationId: organizationId,
      createdByUserId: 'user-1',
      name: 'Test Tournament',
      federationType: FederationType.wt,
      status: TournamentStatus.active,
      numberOfRings: 4,
      settingsJson: {},
      isTemplate: false,
      createdAt: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  DivisionEntity createTestDivision({
    String id = 'division-1',
    DivisionStatus status = DivisionStatus.ready,
  }) {
    return DivisionEntity(
      id: id,
      tournamentId: 'tournament-1',
      name: 'Test Division',
      category: DivisionCategory.sparring,
      gender: DivisionGender.male,
      bracketFormat: BracketFormat.singleElimination,
      status: status,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  ParticipantEntity createTestParticipant({
    String id = 'participant-1',
    String divisionId = 'old-division',
  }) {
    return ParticipantEntity(
      id: id,
      divisionId: divisionId,
      firstName: 'Test',
      lastName: 'Participant',
      checkInStatus: ParticipantStatus.pending,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  AutoAssignmentMatch createTestMatch({
    String participantId = 'participant-1',
    String divisionId = 'division-1',
    int matchScore = 3,
  }) {
    return AutoAssignmentMatch(
      participantId: participantId,
      divisionId: divisionId,
      participantName: 'Test Participant',
      divisionName: 'Test Division',
      matchScore: matchScore,
      criteriaMatched: {'age': true, 'gender': true, 'weight': true},
    );
  }

  void setUpHappyPath() {
    when(
      () => mockUserRepository.getCurrentUser(),
    ).thenAnswer((_) async => Right(createTestUser()));
    when(
      () => mockTournamentRepository.getTournamentById('tournament-1'),
    ).thenAnswer((_) async => Right(createTestTournament()));
    when(
      () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
    ).thenAnswer((_) async => Right([createTestDivision()]));
  }

  group('authorization', () {
    test(
      'returns AuthorizationPermissionDeniedFailure when user not logged in',
      () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Left(ServerConnectionFailure()));

        final result = await useCase(
          tournamentId: 'tournament-1',
          participantIds: ['participant-1'],
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Should fail'),
        );
      },
    );

    test(
      'returns AuthorizationPermissionDeniedFailure when user has no organization',
      () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(createTestUser(organizationId: '')));

        final result = await useCase(
          tournamentId: 'tournament-1',
          participantIds: ['participant-1'],
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Should fail'),
        );
      },
    );

    test('returns NotFoundFailure when tournament not found', () async {
      when(
        () => mockUserRepository.getCurrentUser(),
      ).thenAnswer((_) async => Right(createTestUser()));
      when(
        () => mockTournamentRepository.getTournamentById('tournament-1'),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test(
      'returns AuthorizationPermissionDeniedFailure when tournament not in user org',
      () async {
        when(() => mockUserRepository.getCurrentUser()).thenAnswer(
          (_) async => Right(createTestUser(organizationId: 'org-1')),
        );
        when(
          () => mockTournamentRepository.getTournamentById('tournament-1'),
        ).thenAnswer(
          (_) async => Right(createTestTournament(organizationId: 'org-2')),
        );

        final result = await useCase(
          tournamentId: 'tournament-1',
          participantIds: ['participant-1'],
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Should fail'),
        );
      },
    );
  });

  group('division status filtering', () {
    test('excludes in_progress divisions from matching', () async {
      setUpHappyPath();
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer(
        (_) async => Right([
          createTestDivision(id: 'd1', status: DivisionStatus.inProgress),
          createTestDivision(id: 'd2', status: DivisionStatus.ready),
        ]),
      );
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(
        () => mockService.evaluateMatch(any(), any()),
      ).thenReturn(createTestMatch(divisionId: 'd2'));
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.totalDivisionsEvaluated, 1);
      });

      verify(() => mockService.evaluateMatch(any(), any())).called(1);
    });

    test('excludes completed divisions from matching', () async {
      setUpHappyPath();
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer(
        (_) async => Right([
          createTestDivision(id: 'd1', status: DivisionStatus.completed),
          createTestDivision(id: 'd2', status: DivisionStatus.setup),
        ]),
      );
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(
        () => mockService.evaluateMatch(any(), any()),
      ).thenReturn(createTestMatch(divisionId: 'd2'));
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.totalDivisionsEvaluated, 1);
      });
    });

    test('includes setup and ready divisions', () async {
      when(
        () => mockUserRepository.getCurrentUser(),
      ).thenAnswer((_) async => Right(createTestUser()));
      when(
        () => mockTournamentRepository.getTournamentById('tournament-1'),
      ).thenAnswer((_) async => Right(createTestTournament()));
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer(
        (_) async => Right([
          createTestDivision(id: 'd1', status: DivisionStatus.setup),
          createTestDivision(id: 'd2', status: DivisionStatus.ready),
        ]),
      );
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(
        () => mockService.evaluateMatch(any(), any()),
      ).thenReturn(createTestMatch());
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.totalDivisionsEvaluated, 2);
      });
    });
  });

  group('empty scenarios', () {
    test('returns empty result when no participants provided', () async {
      setUpHappyPath();

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: [],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.matchedAssignments, isEmpty);
        expect(autoResult.unmatchedParticipants, isEmpty);
        expect(autoResult.totalParticipantsProcessed, 0);
      });
    });

    test('returns failure when division repository fails', () async {
      when(
        () => mockUserRepository.getCurrentUser(),
      ).thenAnswer((_) async => Right(createTestUser()));
      when(
        () => mockTournamentRepository.getTournamentById('tournament-1'),
      ).thenAnswer((_) async => Right(createTestTournament()));
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer((_) async => const Left(ServerConnectionFailure()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerConnectionFailure>()),
        (_) => fail('Should fail with server connection failure'),
      );
    });

    test('returns all unmatched when no divisions exist', () async {
      when(
        () => mockUserRepository.getCurrentUser(),
      ).thenAnswer((_) async => Right(createTestUser()));
      when(
        () => mockTournamentRepository.getTournamentById('tournament-1'),
      ).thenAnswer((_) async => Right(createTestTournament()));
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1', 'participant-2'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.matchedAssignments, isEmpty);
        expect(autoResult.unmatchedParticipants.length, 2);
        expect(
          autoResult.unmatchedParticipants.first.reason,
          'No divisions exist in tournament',
        );
        expect(autoResult.totalDivisionsEvaluated, 0);
      });
    });

    test(
      'returns all unmatched when all divisions are in_progress/completed',
      () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(createTestUser()));
        when(
          () => mockTournamentRepository.getTournamentById('tournament-1'),
        ).thenAnswer((_) async => Right(createTestTournament()));
        when(
          () =>
              mockDivisionRepository.getDivisionsForTournament('tournament-1'),
        ).thenAnswer(
          (_) async => Right([
            createTestDivision(id: 'd1', status: DivisionStatus.inProgress),
            createTestDivision(id: 'd2', status: DivisionStatus.completed),
          ]),
        );

        final result = await useCase(
          tournamentId: 'tournament-1',
          participantIds: ['participant-1'],
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should succeed'), (autoResult) {
          expect(autoResult.matchedAssignments, isEmpty);
          expect(autoResult.unmatchedParticipants.length, 1);
          expect(
            autoResult.unmatchedParticipants.first.reason,
            'No divisions available for assignment',
          );
        });
      },
    );
  });

  group('participant handling', () {
    test('skips participant not found with appropriate reason', () async {
      setUpHappyPath();
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.matchedAssignments, isEmpty);
        expect(autoResult.unmatchedParticipants.length, 1);
        expect(
          autoResult.unmatchedParticipants.first.reason,
          'Participant not found',
        );
      });
    });

    test('reassigns already assigned participant to new division', () async {
      setUpHappyPath();
      final alreadyAssigned = createTestParticipant(
        id: 'participant-1',
        divisionId: 'old-division',
      );
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(alreadyAssigned));
      when(
        () => mockService.evaluateMatch(any(), any()),
      ).thenReturn(createTestMatch(divisionId: 'new-division'));
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.matchedAssignments.length, 1);
      });

      final captured =
          verify(
                () => mockParticipantRepository.updateParticipant(captureAny()),
              ).captured.single
              as ParticipantEntity;
      expect(captured.divisionId, 'new-division');
    });
  });

  group('best match selection', () {
    test('selects division with highest matchScore', () async {
      setUpHappyPath();
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer(
        (_) async => Right([
          createTestDivision(id: 'd1'),
          createTestDivision(id: 'd2'),
          createTestDivision(id: 'd3'),
        ]),
      );
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(() => mockService.evaluateMatch(any(), any())).thenAnswer((
        invocation,
      ) {
        final division = invocation.positionalArguments[1] as DivisionEntity;
        if (division.id == 'd1') {
          return createTestMatch(divisionId: 'd1', matchScore: 2);
        } else if (division.id == 'd2') {
          return createTestMatch(divisionId: 'd2', matchScore: 4);
        } else {
          return createTestMatch(divisionId: 'd3', matchScore: 3);
        }
      });
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.matchedAssignments.length, 1);
        expect(autoResult.matchedAssignments.first.divisionId, 'd2');
        expect(autoResult.matchedAssignments.first.matchScore, 4);
      });
    });

    test('uses first match as tie-breaker when scores equal', () async {
      setUpHappyPath();
      when(
        () => mockDivisionRepository.getDivisionsForTournament('tournament-1'),
      ).thenAnswer(
        (_) async =>
            Right([createTestDivision(id: 'd1'), createTestDivision(id: 'd2')]),
      );
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(() => mockService.evaluateMatch(any(), any())).thenAnswer((
        invocation,
      ) {
        final division = invocation.positionalArguments[1] as DivisionEntity;
        return createTestMatch(divisionId: division.id, matchScore: 3);
      });
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.matchedAssignments.first.divisionId, 'd1');
      });
    });
  });

  group('dry run vs actual assignment', () {
    test('dry run does not update participant', () async {
      setUpHappyPath();
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(
        () => mockService.evaluateMatch(any(), any()),
      ).thenReturn(createTestMatch());

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
        dryRun: true,
      );

      expect(result.isRight(), true);
      verifyNever(() => mockParticipantRepository.updateParticipant(any()));
    });

    test('actual assignment updates participant', () async {
      setUpHappyPath();
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(
        () => mockService.evaluateMatch(any(), any()),
      ).thenReturn(createTestMatch());
      when(
        () => mockParticipantRepository.updateParticipant(any()),
      ).thenAnswer((_) async => Right(createTestParticipant()));

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
        dryRun: false,
      );

      expect(result.isRight(), true);
      verify(
        () => mockParticipantRepository.updateParticipant(any()),
      ).called(1);
    });

    test(
      'actual assignment increments syncVersion and sets updatedAtTimestamp',
      () async {
        setUpHappyPath();
        final originalParticipant = createTestParticipant();
        when(
          () => mockParticipantRepository.getParticipantById('participant-1'),
        ).thenAnswer((_) async => Right(originalParticipant));
        when(
          () => mockService.evaluateMatch(any(), any()),
        ).thenReturn(createTestMatch(divisionId: 'new-division'));
        when(
          () => mockParticipantRepository.updateParticipant(any()),
        ).thenAnswer((_) async => Right(createTestParticipant()));

        await useCase(
          tournamentId: 'tournament-1',
          participantIds: ['participant-1'],
          dryRun: false,
        );

        final captured =
            verify(
                  () =>
                      mockParticipantRepository.updateParticipant(captureAny()),
                ).captured.single
                as ParticipantEntity;
        expect(captured.syncVersion, originalParticipant.syncVersion + 1);
        expect(
          captured.updatedAtTimestamp.isAfter(
            originalParticipant.updatedAtTimestamp,
          ),
          true,
        );
      },
    );
  });

  group('unmatched participant reasons', () {
    test('includes reason from service when no match found', () async {
      setUpHappyPath();
      when(
        () => mockParticipantRepository.getParticipantById('participant-1'),
      ).thenAnswer((_) async => Right(createTestParticipant()));
      when(() => mockService.evaluateMatch(any(), any())).thenReturn(null);
      when(
        () => mockService.determineUnmatchedReason(any(), any()),
      ).thenReturn('No divisions with matching gender criteria');

      final result = await useCase(
        tournamentId: 'tournament-1',
        participantIds: ['participant-1'],
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should succeed'), (autoResult) {
        expect(autoResult.unmatchedParticipants.length, 1);
        expect(
          autoResult.unmatchedParticipants.first.reason,
          'No divisions with matching gender criteria',
        );
      });
    });
  });
}
