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
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

class MockParticipantRepository extends Mock
    implements ParticipantRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockTournamentRepository extends Mock
    implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

void main() {
  late UpdateParticipantUseCase useCase;
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
    useCase = UpdateParticipantUseCase(
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

  final tDivision = DivisionEntity(
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

  final tParticipant = ParticipantEntity(
    id: 'participant-id',
    divisionId: 'division-id',
    firstName: 'Alice',
    lastName: 'Kim',
    schoolOrDojangName: 'Seoul Dojang',
    beltRank: 'Black',
    seedNumber: 1,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  void setupSuccessMocks({DivisionEntity? division}) {
    when(() => mockUserRepo.getCurrentUser())
        .thenAnswer((_) async => Right(tUser));
    when(
      () => mockParticipantRepo.getParticipantById('participant-id'),
    ).thenAnswer((_) async => Right(tParticipant));
    when(
      () => mockDivisionRepo.getDivisionById('division-id'),
    ).thenAnswer((_) async => Right(division ?? tDivision));
    when(
      () => mockTournamentRepo.getTournamentById('tournament-id'),
    ).thenAnswer((_) async => Right(tTournament));
    when(() => mockParticipantRepo.updateParticipant(any())).thenAnswer(
      (invocation) async {
        final participant =
            invocation.positionalArguments.first as ParticipantEntity;
        return Right(participant);
      },
    );
  }

  group('UpdateParticipantUseCase', () {
    group('input validation', () {
      test(
        'returns InputValidationFailure when '
        'participantId is empty',
        () async {
          const params = UpdateParticipantParams(
            participantId: '',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('participantId'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockParticipantRepo.getParticipantById(any()),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'no fields are provided for update',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
            },
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockUserRepo.getCurrentUser(),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'firstName is empty string',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: '',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('firstName'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'lastName is whitespace only',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            lastName: '   ',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('lastName'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'schoolOrDojangName is empty',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            schoolOrDojangName: '',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('schoolOrDojangName'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'beltRank is invalid',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            beltRank: 'purple',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('beltRank'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'weightKg is negative',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            weightKg: -5,
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('weightKg'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'weightKg exceeds maximum',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            weightKg: 200,
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('weightKg'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'dateOfBirth is in the future',
        () async {
          final params = UpdateParticipantParams(
            participantId: 'participant-id',
            dateOfBirth: DateTime.now().add(
              const Duration(days: 30),
            ),
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('dateOfBirth'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'age is below minimum (< 4)',
        () async {
          final params = UpdateParticipantParams(
            participantId: 'participant-id',
            dateOfBirth: DateTime.now().subtract(
              const Duration(days: 365), // ~1 year old
            ),
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('dateOfBirth'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'age exceeds maximum (> 80)',
        () async {
          final params = UpdateParticipantParams(
            participantId: 'participant-id',
            dateOfBirth: DateTime(1930, 1, 1), // ~96 years old
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('dateOfBirth'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'validates before making any repository calls',
        () async {
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: '', // invalid
            weightKg: -1, // invalid
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          verifyNever(
            () => mockUserRepo.getCurrentUser(),
          );
          verifyNever(
            () => mockParticipantRepo.getParticipantById(any()),
          );
        },
      );
    });

    group('authorization', () {
      test(
        'returns AuthorizationPermissionDeniedFailure '
        'when user has no organization',
        () async {
          when(() => mockUserRepo.getCurrentUser()).thenAnswer(
            (_) async => Right(
              tUser.copyWith(organizationId: ''),
            ),
          );

          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(
              failure,
              isA<AuthorizationPermissionDeniedFailure>(),
            ),
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockParticipantRepo.getParticipantById(any()),
          );
        },
      );

      test(
        'returns AuthorizationPermissionDeniedFailure '
        'when user org does not match tournament org',
        () async {
          when(() => mockUserRepo.getCurrentUser()).thenAnswer(
            (_) async => Right(
              tUser.copyWith(organizationId: 'other-org'),
            ),
          );
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo.getDivisionById('division-id'),
          ).thenAnswer((_) async => Right(tDivision));
          when(
            () => mockTournamentRepo
                .getTournamentById('tournament-id'),
          ).thenAnswer((_) async => Right(tTournament));

          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(
              failure,
              isA<AuthorizationPermissionDeniedFailure>(),
            ),
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockParticipantRepo.updateParticipant(any()),
          );
        },
      );
    });

    group('entity not found', () {
      test(
        'returns NotFoundFailure when participant not found',
        () async {
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(
                userFriendlyMessage: 'Participant not found',
              ),
            ),
          );

          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(
              failure,
              isA<NotFoundFailure>(),
            ),
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when division not found',
        () async {
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo.getDivisionById('division-id'),
          ).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(
                userFriendlyMessage: 'Division not found',
              ),
            ),
          );

          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(
              failure,
              isA<NotFoundFailure>(),
            ),
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when tournament not found',
        () async {
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo.getDivisionById('division-id'),
          ).thenAnswer((_) async => Right(tDivision));
          when(
            () => mockTournamentRepo
                .getTournamentById('tournament-id'),
          ).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(
                userFriendlyMessage: 'Tournament not found',
              ),
            ),
          );

          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(
              failure,
              isA<NotFoundFailure>(),
            ),
            (_) => fail('Should be Left'),
          );
        },
      );
    });

    group('division status check', () {
      test(
        'returns InputValidationFailure when '
        'division status is inProgress',
        () async {
          setupSuccessMocks(
            division: tDivision.copyWith(
              status: DivisionStatus.inProgress,
            ),
          );
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockParticipantRepo.updateParticipant(any()),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'division status is completed',
        () async {
          setupSuccessMocks(
            division: tDivision.copyWith(
              status: DivisionStatus.completed,
            ),
          );
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'allows update when division status is ready',
        () async {
          setupSuccessMocks(
            division: tDivision.copyWith(
              status: DivisionStatus.ready,
            ),
          );
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          final result = await useCase(params);
          expect(result.isRight(), true);
        },
      );
    });

    group('successful updates', () {
      test('should update firstName successfully', () async {
        setupSuccessMocks();
        const params = UpdateParticipantParams(
          participantId: 'participant-id',
          firstName: 'Bob',
        );
        final result = await useCase(params);
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (updated) {
            expect(updated.firstName, 'Bob');
            expect(updated.lastName, tParticipant.lastName);
            expect(
              updated.syncVersion,
              tParticipant.syncVersion + 1,
            );
          },
        );
      });

      test('should trim string values', () async {
        setupSuccessMocks();
        const params = UpdateParticipantParams(
          participantId: 'participant-id',
          firstName: '  Bob  ',
        );
        final result = await useCase(params);
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (updated) => expect(updated.firstName, 'Bob'),
        );
      });

      test(
        'should update multiple fields simultaneously',
        () async {
          setupSuccessMocks();
          final params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
            lastName: 'Park',
            weightKg: 72.5,
            dateOfBirth: DateTime(2000, 6, 15),
            gender: Gender.male,
            notes: 'Updated notes',
          );
          final result = await useCase(params);
          expect(result.isRight(), true);
          result.fold(
            (_) => fail('Should be Right'),
            (updated) {
              expect(updated.firstName, 'Bob');
              expect(updated.lastName, 'Park');
              expect(updated.weightKg, 72.5);
              expect(
                updated.dateOfBirth,
                DateTime(2000, 6, 15),
              );
              expect(updated.gender, Gender.male);
              expect(updated.notes, 'Updated notes');
            },
          );
        },
      );

      test('should accept valid belt ranks', () async {
        setupSuccessMocks();
        const params = UpdateParticipantParams(
          participantId: 'participant-id',
          beltRank: 'White',
        );
        final result = await useCase(params);
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (updated) => expect(updated.beltRank, 'White'),
        );
      });

      test('should update updatedAtTimestamp', () async {
        final beforeUpdate = DateTime.now();
        setupSuccessMocks();
        const params = UpdateParticipantParams(
          participantId: 'participant-id',
          firstName: 'Bob',
        );
        final result = await useCase(params);
        final afterUpdate = DateTime.now();

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (updated) {
            expect(
              updated.updatedAtTimestamp.isAfter(
                beforeUpdate.subtract(
                  const Duration(seconds: 1),
                ),
              ),
              isTrue,
            );
            expect(
              updated.updatedAtTimestamp.isBefore(
                afterUpdate.add(const Duration(seconds: 1)),
              ),
              isTrue,
            );
          },
        );
      });

      test(
        'should call updateParticipant on repository',
        () async {
          setupSuccessMocks();
          const params = UpdateParticipantParams(
            participantId: 'participant-id',
            firstName: 'Bob',
          );
          await useCase(params);

          verify(
            () => mockParticipantRepo.updateParticipant(any()),
          ).called(1);
        },
      );
    });
  });
}
