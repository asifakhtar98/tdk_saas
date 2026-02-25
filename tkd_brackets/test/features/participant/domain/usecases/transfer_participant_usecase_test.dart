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
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_usecase.dart';
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
  late TransferParticipantUseCase useCase;
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
    useCase = TransferParticipantUseCase(
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

  final tSourceDivision = DivisionEntity(
    id: 'source-division-id',
    tournamentId: 'tournament-id',
    name: 'Source Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tTargetDivision = DivisionEntity(
    id: 'target-division-id',
    tournamentId: 'tournament-id',
    name: 'Target Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.female,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tParticipant = ParticipantEntity(
    id: 'participant-id',
    divisionId: 'source-division-id',
    firstName: 'Alice',
    lastName: 'Kim',
    schoolOrDojangName: 'Seoul Dojang',
    beltRank: 'Black',
    seedNumber: 3,
    syncVersion: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  void setupSuccessMocks({
    DivisionEntity? sourceDivision,
    DivisionEntity? targetDivision,
  }) {
    when(() => mockUserRepo.getCurrentUser())
        .thenAnswer((_) async => Right(tUser));
    when(
      () => mockParticipantRepo.getParticipantById('participant-id'),
    ).thenAnswer((_) async => Right(tParticipant));
    when(
      () => mockDivisionRepo
          .getDivisionById('source-division-id'),
    ).thenAnswer(
      (_) async => Right(sourceDivision ?? tSourceDivision),
    );
    when(
      () => mockDivisionRepo
          .getDivisionById('target-division-id'),
    ).thenAnswer(
      (_) async => Right(targetDivision ?? tTargetDivision),
    );
    when(
      () => mockTournamentRepo.getTournamentById('tournament-id'),
    ).thenAnswer((_) async => Right(tTournament));
    when(() => mockParticipantRepo.updateParticipant(any()))
        .thenAnswer(
      (invocation) async {
        final participant = invocation.positionalArguments.first
            as ParticipantEntity;
        return Right(participant);
      },
    );
  }

  group('TransferParticipantUseCase', () {
    group('input validation', () {
      test(
        'returns InputValidationFailure when '
        'participantId is empty',
        () async {
          final params = const TransferParticipantParams(
            participantId: '',
            targetDivisionId: 'target-division-id',
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
            () => mockUserRepo.getCurrentUser(),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'targetDivisionId is empty',
        () async {
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: '',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) {
              expect(failure, isA<InputValidationFailure>());
              expect(
                (failure as InputValidationFailure)
                    .fieldErrors
                    .containsKey('targetDivisionId'),
                true,
              );
            },
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockUserRepo.getCurrentUser(),
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

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
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
            () => mockDivisionRepo
                .getDivisionById('source-division-id'),
          ).thenAnswer(
            (_) async => Right(tSourceDivision),
          );
          when(
            () => mockDivisionRepo
                .getDivisionById('target-division-id'),
          ).thenAnswer(
            (_) async => Right(tTargetDivision),
          );
          when(
            () => mockTournamentRepo
                .getTournamentById('tournament-id'),
          ).thenAnswer((_) async => Right(tTournament));

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
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

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when '
        'source division not found',
        () async {
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo
                .getDivisionById('source-division-id'),
          ).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(
                userFriendlyMessage: 'Division not found',
              ),
            ),
          );

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when '
        'target division not found',
        () async {
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo
                .getDivisionById('source-division-id'),
          ).thenAnswer(
            (_) async => Right(tSourceDivision),
          );
          when(
            () => mockDivisionRepo
                .getDivisionById('target-division-id'),
          ).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(
                userFriendlyMessage: 'Division not found',
              ),
            ),
          );

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Should be Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when '
        'tournament not found',
        () async {
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer((_) async => Right(tParticipant));
          when(
            () => mockDivisionRepo
                .getDivisionById('source-division-id'),
          ).thenAnswer(
            (_) async => Right(tSourceDivision),
          );
          when(
            () => mockDivisionRepo
                .getDivisionById('target-division-id'),
          ).thenAnswer(
            (_) async => Right(tTargetDivision),
          );
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

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Should be Left'),
          );
        },
      );
    });

    group('transfer guards', () {
      test(
        'returns InputValidationFailure when '
        'participant is already in target division',
        () async {
          final targetParticipant = tParticipant.copyWith(
            divisionId: 'target-division-id',
          );
          when(() => mockUserRepo.getCurrentUser())
              .thenAnswer((_) async => Right(tUser));
          when(
            () => mockParticipantRepo
                .getParticipantById('participant-id'),
          ).thenAnswer(
            (_) async => Right(targetParticipant),
          );

          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockDivisionRepo.getDivisionById(any()),
          );
        },
      );

      test(
        'returns InputValidationFailure when '
        'divisions belong to different tournaments',
        () async {
          setupSuccessMocks(
            targetDivision: tTargetDivision.copyWith(
              tournamentId: 'other-tournament',
            ),
          );
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isLeft(), true);
          result.fold(
            (failure) =>
                expect(failure, isA<InputValidationFailure>()),
            (_) => fail('Should be Left'),
          );
          verifyNever(
            () => mockTournamentRepo.getTournamentById(any()),
          );
        },
      );
    });

    group('division status checks', () {
      test(
        'returns InputValidationFailure when '
        'source division is inProgress',
        () async {
          setupSuccessMocks(
            sourceDivision: tSourceDivision.copyWith(
              status: DivisionStatus.inProgress,
            ),
          );
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
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
        'source division is completed',
        () async {
          setupSuccessMocks(
            sourceDivision: tSourceDivision.copyWith(
              status: DivisionStatus.completed,
            ),
          );
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
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
        'returns InputValidationFailure when '
        'target division is inProgress',
        () async {
          setupSuccessMocks(
            targetDivision: tTargetDivision.copyWith(
              status: DivisionStatus.inProgress,
            ),
          );
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
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
        'returns InputValidationFailure when '
        'target division is completed',
        () async {
          setupSuccessMocks(
            targetDivision: tTargetDivision.copyWith(
              status: DivisionStatus.completed,
            ),
          );
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
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
        'allows transfer when both divisions '
        'are in ready status',
        () async {
          setupSuccessMocks(
            sourceDivision: tSourceDivision.copyWith(
              status: DivisionStatus.ready,
            ),
            targetDivision: tTargetDivision.copyWith(
              status: DivisionStatus.ready,
            ),
          );
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isRight(), true);
        },
      );
    });

    group('successful transfer', () {
      test(
        'transfers participant and resets seedNumber',
        () async {
          setupSuccessMocks();
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isRight(), true);
          result.fold(
            (_) => fail('Should be Right'),
            (updated) {
              expect(
                updated.divisionId,
                'target-division-id',
              );
              expect(updated.seedNumber, isNull);
              expect(
                updated.syncVersion,
                tParticipant.syncVersion + 1,
              );
            },
          );
        },
      );

      test('should update updatedAtTimestamp', () async {
        final beforeUpdate = DateTime.now();
        setupSuccessMocks();
        final params = const TransferParticipantParams(
          participantId: 'participant-id',
          targetDivisionId: 'target-division-id',
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
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          await useCase(params);

          verify(
            () => mockParticipantRepo.updateParticipant(any()),
          ).called(1);
        },
      );

      test(
        'preserves other participant fields on transfer',
        () async {
          setupSuccessMocks();
          final params = const TransferParticipantParams(
            participantId: 'participant-id',
            targetDivisionId: 'target-division-id',
          );
          final result = await useCase(params);
          expect(result.isRight(), true);
          result.fold(
            (_) => fail('Should be Right'),
            (updated) {
              expect(updated.id, tParticipant.id);
              expect(
                updated.firstName,
                tParticipant.firstName,
              );
              expect(updated.lastName, tParticipant.lastName);
              expect(
                updated.schoolOrDojangName,
                tParticipant.schoolOrDojangName,
              );
              expect(updated.beltRank, tParticipant.beltRank);
            },
          );
        },
      );
    });
  });
}
