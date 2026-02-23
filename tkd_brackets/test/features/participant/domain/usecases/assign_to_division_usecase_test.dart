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
import 'package:tkd_brackets/features/participant/domain/usecases/assign_to_division_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late AssignToDivisionUseCase useCase;
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
    useCase = AssignToDivisionUseCase(
      mockParticipantRepo,
      mockDivisionRepo,
      mockTournamentRepo,
      mockUserRepo,
    );
  });

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

  final tDivisionReady = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.ready,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
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

  final tDivisionInProgress = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.inProgress,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tDivisionCompleted = DivisionEntity(
    id: 'division-id',
    tournamentId: 'tournament-id',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.completed,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tParticipant = ParticipantEntity(
    id: 'participant-id',
    divisionId: 'old-division-id',
    firstName: 'John',
    lastName: 'Doe',
    schoolOrDojangName: 'Test Dojang',
    beltRank: 'Black',
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  void setupSuccessMocks({DivisionEntity? division}) {
    when(
      () => mockUserRepo.getCurrentUser(),
    ).thenAnswer((_) async => Right(tUser));
    when(
      () => mockParticipantRepo.getParticipantById('participant-id'),
    ).thenAnswer((_) async => Right(tParticipant));
    when(
      () => mockDivisionRepo.getDivisionById('division-id'),
    ).thenAnswer((_) async => Right(division ?? tDivisionReady));
    when(
      () => mockTournamentRepo.getTournamentById('tournament-id'),
    ).thenAnswer((_) async => Right(tTournament));
  }

  group('input validation', () {
    test(
      'should return InputValidationFailure when participantId is empty',
      () async {
        final result = await useCase(
          participantId: '',
          divisionId: 'division-id',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockUserRepo.getCurrentUser());
      },
    );

    test(
      'should return InputValidationFailure when divisionId is empty',
      () async {
        final result = await useCase(
          participantId: 'participant-id',
          divisionId: '',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<InputValidationFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockUserRepo.getCurrentUser());
      },
    );
  });

  group('AssignToDivisionUseCase', () {
    group('success cases', () {
      test('should assign participant to division successfully', () async {
        setupSuccessMocks();

        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isRight(), true);
        verify(() => mockParticipantRepo.updateParticipant(any())).called(1);
      });

      test('should allow assignment when division status is setup', () async {
        setupSuccessMocks(division: tDivisionSetup);

        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isRight(), true);
      });

      test('should allow assignment when division status is ready', () async {
        setupSuccessMocks(division: tDivisionReady);

        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isRight(), true);
      });

      test('should increment syncVersion on update', () async {
        setupSuccessMocks();

        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.syncVersion, equals(2));
        });
      });

      test('should update updatedAtTimestamp on change', () async {
        setupSuccessMocks();

        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer((
          invocation,
        ) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final beforeUpdate = DateTime.now();

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        final afterUpdate = DateTime.now();

        expect(result.isRight(), true);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(
            participant.updatedAtTimestamp.isAfter(
              beforeUpdate.subtract(const Duration(seconds: 1)),
            ),
            true,
          );
          expect(
            participant.updatedAtTimestamp.isBefore(
              afterUpdate.add(const Duration(seconds: 1)),
            ),
            true,
          );
        });
      });
    });

    group('authorization failures', () {
      test('should return AuthorizationPermissionDeniedFailure when user not '
          'logged in', () async {
        when(() => mockUserRepo.getCurrentUser()).thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(userFriendlyMessage: 'Not logged in'),
          ),
        );

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockParticipantRepo.getParticipantById(any()));
      });

      test(
        'should return AuthorizationPermissionDeniedFailure when user has no '
        'organization',
        () async {
          final userNoOrg = tUser.copyWith(organizationId: '');
          when(
            () => mockUserRepo.getCurrentUser(),
          ).thenAnswer((_) async => Right(userNoOrg));

          final result = await useCase(
            participantId: 'participant-id',
            divisionId: 'division-id',
          );

          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Should return failure'),
          );
        },
      );

      test('should return AuthorizationPermissionDeniedFailure for wrong '
          'organization', () async {
        final wrongOrgTournament = tTournament.copyWith(
          organizationId: 'other-org',
        );
        when(
          () => mockUserRepo.getCurrentUser(),
        ).thenAnswer((_) async => Right(tUser));
        when(
          () => mockParticipantRepo.getParticipantById('participant-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(
          () => mockDivisionRepo.getDivisionById('division-id'),
        ).thenAnswer((_) async => Right(tDivisionReady));
        when(
          () => mockTournamentRepo.getTournamentById('tournament-id'),
        ).thenAnswer((_) async => Right(wrongOrgTournament));

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) =>
              expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockParticipantRepo.updateParticipant(any()));
      });
    });

    group('division status validation', () {
      test(
        'should return InputValidationFailure when division is inProgress',
        () async {
          when(
            () => mockUserRepo.getCurrentUser(),
          ).thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo.getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo.getDivisionById('division-id'),
          ).thenAnswer((_) async => Right(tDivisionInProgress));
          when(
            () => mockTournamentRepo.getTournamentById('tournament-id'),
          ).thenAnswer((_) async => Right(tTournament));

          final result = await useCase(
            participantId: 'participant-id',
            divisionId: 'division-id',
          );

          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Should return failure'),
          );
          verifyNever(() => mockParticipantRepo.updateParticipant(any()));
        },
      );

      test(
        'should return InputValidationFailure when division is completed',
        () async {
          when(
            () => mockUserRepo.getCurrentUser(),
          ).thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo.getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo.getDivisionById('division-id'),
          ).thenAnswer((_) async => Right(tDivisionCompleted));
          when(
            () => mockTournamentRepo.getTournamentById('tournament-id'),
          ).thenAnswer((_) async => Right(tTournament));

          final result = await useCase(
            participantId: 'participant-id',
            divisionId: 'division-id',
          );

          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Should return failure'),
          );
          verifyNever(() => mockParticipantRepo.updateParticipant(any()));
        },
      );
    });

    group('duplicate assignment prevention', () {
      test(
        'should return InputValidationFailure for duplicate assignment',
        () async {
          final sameDivisionParticipant = tParticipant.copyWith(
            divisionId: 'division-id',
          );
          when(
            () => mockUserRepo.getCurrentUser(),
          ).thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo.getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(sameDivisionParticipant));
          when(
            () => mockDivisionRepo.getDivisionById('division-id'),
          ).thenAnswer((_) async => Right(tDivisionReady));
          when(
            () => mockTournamentRepo.getTournamentById('tournament-id'),
          ).thenAnswer((_) async => Right(tTournament));

          final result = await useCase(
            participantId: 'participant-id',
            divisionId: 'division-id',
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<InputValidationFailure>());
            expect(
              (failure as InputValidationFailure).userFriendlyMessage,
              contains('already assigned'),
            );
          }, (_) => fail('Should return failure'));
          verifyNever(() => mockParticipantRepo.updateParticipant(any()));
        },
      );
    });

    group('not found failures', () {
      test(
        'should return NotFoundFailure when participant not found',
        () async {
          when(
            () => mockUserRepo.getCurrentUser(),
          ).thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo.getParticipantById('participant-id'),
          ).thenAnswer((_) async => const Left(NotFoundFailure()));

          final result = await useCase(
            participantId: 'participant-id',
            divisionId: 'division-id',
          );

          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Should return failure'),
          );
        },
      );

      test('should return NotFoundFailure when division not found', () async {
        when(
          () => mockUserRepo.getCurrentUser(),
        ).thenAnswer((_) async => Right(tUser));
        when(
          () => mockParticipantRepo.getParticipantById('participant-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(
          () => mockDivisionRepo.getDivisionById('division-id'),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return NotFoundFailure when tournament not found', () async {
        when(
          () => mockUserRepo.getCurrentUser(),
        ).thenAnswer((_) async => Right(tUser));
        when(
          () => mockParticipantRepo.getParticipantById('participant-id'),
        ).thenAnswer((_) async => Right(tParticipant));
        when(
          () => mockDivisionRepo.getDivisionById('division-id'),
        ).thenAnswer((_) async => Right(tDivisionReady));
        when(
          () => mockTournamentRepo.getTournamentById('tournament-id'),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('repository failure', () {
      test('should return failure when updateParticipant fails', () async {
        setupSuccessMocks();

        when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer(
          (_) async => const Left(
            LocalCacheWriteFailure(userFriendlyMessage: 'Failed to save'),
          ),
        );

        final result = await useCase(
          participantId: 'participant-id',
          divisionId: 'division-id',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<LocalCacheWriteFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
