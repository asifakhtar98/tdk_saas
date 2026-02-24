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
import 'package:tkd_brackets/features/participant/domain/usecases/update_seed_positions_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

// ⚠️ REQUIRED: updateParticipant(any()) uses any() matcher with ParticipantEntity type
class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late UpdateSeedPositionsUseCase useCase;
  late MockParticipantRepository mockParticipantRepo;
  late MockDivisionRepository mockDivisionRepo;
  late MockTournamentRepository mockTournamentRepo;
  late MockUserRepository mockUserRepo;

  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
  });

  setUp(() {
    mockParticipantRepo = MockParticipantRepository();
    mockDivisionRepo = MockDivisionRepository();
    mockTournamentRepo = MockTournamentRepository();
    mockUserRepo = MockUserRepository();
    useCase = UpdateSeedPositionsUseCase(
      mockParticipantRepo,
      mockDivisionRepo,
      mockTournamentRepo,
      mockUserRepo,
    );
  });

  // ── Test entity factories ──

  final tUser = UserEntity(
    id: 'user-id',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-id',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024, 1, 1),
  );

  final tTournament = TournamentEntity(
    id: 'tournament-id',
    organizationId: 'org-id',
    createdByUserId: 'user-id',
    name: 'Test Tournament',
    scheduledDate: DateTime(2024, 6, 1),
    federationType: FederationType.wt,
    status: TournamentStatus.active,
    numberOfRings: 2,
    isTemplate: false,
    settingsJson: const {},
    createdAt: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tDivisionSetup = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tDivisionReady = tDivisionSetup.copyWith(status: DivisionStatus.ready);
  final tDivisionInProgress = tDivisionSetup.copyWith(
    status: DivisionStatus.inProgress,
  );
  final tDivisionCompleted = tDivisionSetup.copyWith(
    status: DivisionStatus.completed,
  );

  final tParticipant1 = ParticipantEntity(
    id: 'p1',
    divisionId: 'division-id',
    firstName: 'Alice',
    lastName: 'Kim',
    schoolOrDojangName: 'Seoul Dojang',
    seedNumber: null,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tParticipant2 = ParticipantEntity(
    id: 'p2',
    divisionId: 'division-id',
    firstName: 'Bob',
    lastName: 'Lee',
    schoolOrDojangName: 'Busan Dojang',
    seedNumber: null,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tParticipant3 = ParticipantEntity(
    id: 'p3',
    divisionId: 'division-id',
    firstName: 'Charlie',
    lastName: 'Park',
    schoolOrDojangName: 'Incheon Dojang',
    seedNumber: null,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  void setupSuccessMocks({DivisionEntity? division}) {
    when(
      () => mockUserRepo.getCurrentUser(),
    ).thenAnswer((_) async => Right(tUser));
    when(
      () => mockDivisionRepo.getDivisionById('division-id'),
    ).thenAnswer((_) async => Right(division ?? tDivisionSetup));
    when(
      () => mockTournamentRepo.getTournamentById('tournament-id'),
    ).thenAnswer((_) async => Right(tTournament));

    when(
      () => mockParticipantRepo.getParticipantById('p1'),
    ).thenAnswer((_) async => Right(tParticipant1));
    when(
      () => mockParticipantRepo.getParticipantById('p2'),
    ).thenAnswer((_) async => Right(tParticipant2));
    when(
      () => mockParticipantRepo.getParticipantById('p3'),
    ).thenAnswer((_) async => Right(tParticipant3));

    when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer((
      invocation,
    ) async {
      final participant =
          invocation.positionalArguments.first as ParticipantEntity;
      return Right(participant);
    });
  }

  group('UpdateSeedPositionsUseCase', () {
    test('should successfully reorder 3 participants', () async {
      // arrange
      setupSuccessMocks();
      const params = UpdateSeedPositionsParams(
        divisionId: 'division-id',
        participantIdsInOrder: ['p3', 'p1', 'p2'],
      );

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not be left'), (list) {
        expect(list.length, 3);
        expect(list[0].id, 'p3');
        expect(list[0].seedNumber, 1);
        expect(list[1].id, 'p1');
        expect(list[1].seedNumber, 2);
        expect(list[2].id, 'p2');
        expect(list[2].seedNumber, 3);

        // Verify syncVersion increment
        expect(list[0].syncVersion, tParticipant3.syncVersion + 1);
      });
      verify(() => mockParticipantRepo.updateParticipant(any())).called(3);
    });

    test('should return InputValidationFailure for empty divisionId', () async {
      // act
      final result = await useCase(
        const UpdateSeedPositionsParams(
          divisionId: '',
          participantIdsInOrder: ['p1'],
        ),
      );

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => r), isA<InputValidationFailure>());
    });

    test(
      'should return InputValidationFailure for empty participant list',
      () async {
        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: [],
          ),
        );

        // assert
        expect(result.isLeft(), true);
      },
    );

    test(
      'should return InputValidationFailure for duplicate participant IDs',
      () async {
        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1', 'p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
      },
    );

    test(
      'should return AuthorizationPermissionDeniedFailure when user not logged in',
      () async {
        // arrange
        when(() => mockUserRepo.getCurrentUser()).thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(userFriendlyMessage: 'Not logged in'),
          ),
        );

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(
          result.fold((l) => l, (r) => r),
          isA<AuthorizationPermissionDeniedFailure>(),
        );
      },
    );

    test('should return NotFoundFailure when division not found', () async {
      // arrange
      when(
        () => mockUserRepo.getCurrentUser(),
      ).thenAnswer((_) async => Right(tUser));
      when(() => mockDivisionRepo.getDivisionById('division-id')).thenAnswer(
        (_) async =>
            const Left(NotFoundFailure(userFriendlyMessage: 'Not found')),
      );

      // act
      final result = await useCase(
        const UpdateSeedPositionsParams(
          divisionId: 'division-id',
          participantIdsInOrder: ['p1'],
        ),
      );

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => r), isA<NotFoundFailure>());
    });

    test(
      "should return AuthorizationPermissionDeniedFailure when user org doesn't match",
      () async {
        // arrange
        when(
          () => mockUserRepo.getCurrentUser(),
        ).thenAnswer((_) async => Right(tUser));
        when(
          () => mockDivisionRepo.getDivisionById('division-id'),
        ).thenAnswer((_) async => Right(tDivisionSetup));
        when(
          () => mockTournamentRepo.getTournamentById('tournament-id'),
        ).thenAnswer(
          (_) async => Right(tTournament.copyWith(organizationId: 'other-org')),
        );

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(
          result.fold((l) => l, (r) => r),
          isA<AuthorizationPermissionDeniedFailure>(),
        );
      },
    );

    test(
      'should return InputValidationFailure when division status is inProgress',
      () async {
        // arrange
        setupSuccessMocks(division: tDivisionInProgress);

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => r), isA<InputValidationFailure>());
      },
    );

    test(
      'should return InputValidationFailure when division status is completed',
      () async {
        // arrange
        setupSuccessMocks(division: tDivisionCompleted);

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => r), isA<InputValidationFailure>());
      },
    );

    test('should allow reordering when division status is setup', () async {
      // arrange
      setupSuccessMocks();

      // act
      final result = await useCase(
        const UpdateSeedPositionsParams(
          divisionId: 'division-id',
          participantIdsInOrder: ['p1'],
        ),
      );

      // assert
      expect(result.isRight(), true);
    });

    test('should allow reordering when division status is ready', () async {
      // arrange
      setupSuccessMocks(division: tDivisionReady);

      // act
      final result = await useCase(
        const UpdateSeedPositionsParams(
          divisionId: 'division-id',
          participantIdsInOrder: ['p1'],
        ),
      );

      // assert
      expect(result.isRight(), true);
    });

    test(
      "should return NotFoundFailure when a participant ID doesn't exist",
      () async {
        // arrange
        setupSuccessMocks();
        when(() => mockParticipantRepo.getParticipantById('p999')).thenAnswer(
          (_) async =>
              const Left(NotFoundFailure(userFriendlyMessage: 'Not found')),
        );

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p999'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => r), isA<NotFoundFailure>());
      },
    );

    test(
      "should return InputValidationFailure when participant doesn't belong to specified division",
      () async {
        // arrange
        setupSuccessMocks();
        when(() => mockParticipantRepo.getParticipantById('p1')).thenAnswer(
          (_) async =>
              Right(tParticipant1.copyWith(divisionId: 'other-division')),
        );

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => r), isA<InputValidationFailure>());
      },
    );

    test(
      'should propagate repository failure from updateParticipant',
      () async {
        // arrange
        setupSuccessMocks();
        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer(
          (_) async =>
              const Left(LocalCacheWriteFailure(userFriendlyMessage: 'Error')),
        );

        // act
        final result = await useCase(
          const UpdateSeedPositionsParams(
            divisionId: 'division-id',
            participantIdsInOrder: ['p1'],
          ),
        );

        // assert
        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => r), isA<LocalCacheWriteFailure>());
      },
    );
  });
}
