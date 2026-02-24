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
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class FakeParticipantEntity extends Fake implements ParticipantEntity {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late CreateParticipantUseCase useCase;
  late MockParticipantRepository mockParticipantRepository;
  late MockDivisionRepository mockDivisionRepository;
  late MockTournamentRepository mockTournamentRepository;
  late MockUserRepository mockUserRepository;

  setUpAll(() {
    registerFallbackValue(FakeParticipantEntity());
    registerFallbackValue(FakeDivisionEntity());
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockParticipantRepository = MockParticipantRepository();
    mockDivisionRepository = MockDivisionRepository();
    mockTournamentRepository = MockTournamentRepository();
    mockUserRepository = MockUserRepository();
    useCase = CreateParticipantUseCase(
      mockParticipantRepository,
      mockDivisionRepository,
      mockTournamentRepository,
      mockUserRepository,
    );
  });

  final testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    organizationId: 'org-456',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final testDivision = DivisionEntity(
    id: 'division-123',
    tournamentId: 'tournament-123',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    createdAtTimestamp: DateTime(2024),
    updatedAtTimestamp: DateTime(2024),
  );

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    createdByUserId: 'user-123',
    name: 'Test Tournament',
    scheduledDate: DateTime(2026, 3, 15),
    federationType: FederationType.wt,
    status: TournamentStatus.draft,
    numberOfRings: 1,
    isTemplate: false,
    settingsJson: const {},
    createdAt: DateTime(2024),
    updatedAtTimestamp: DateTime(2024),
  );

  CreateParticipantParams validParams() => const CreateParticipantParams(
    divisionId: 'division-123',
    firstName: 'John',
    lastName: 'Doe',
    schoolOrDojangName: 'TKD Academy',
    beltRank: 'Black',
  );

  group('CreateParticipantUseCase', () {
    group('validation', () {
      test('returns InputValidationFailure for empty firstName', () async {
        final result = await useCase(validParams().copyWith(firstName: ''));

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['firstName'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test(
        'returns InputValidationFailure for whitespace-only firstName',
        () async {
          final result = await useCase(
            validParams().copyWith(firstName: '   '),
          );

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<InputValidationFailure>());
            final validationFailure = failure as InputValidationFailure;
            expect(validationFailure.fieldErrors['firstName'], isNotNull);
          }, (_) => fail('Expected Left'));
        },
      );

      test('returns InputValidationFailure for empty lastName', () async {
        final result = await useCase(validParams().copyWith(lastName: ''));

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['lastName'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test(
        'returns InputValidationFailure for empty schoolOrDojangName',
        () async {
          final result = await useCase(
            validParams().copyWith(schoolOrDojangName: ''),
          );

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<InputValidationFailure>());
            final validationFailure = failure as InputValidationFailure;
            expect(
              validationFailure.fieldErrors['schoolOrDojangName'],
              isNotNull,
            );
          }, (_) => fail('Expected Left'));
        },
      );

      test('returns InputValidationFailure for empty beltRank', () async {
        final result = await useCase(validParams().copyWith(beltRank: ''));

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['beltRank'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('returns InputValidationFailure for invalid beltRank', () async {
        final result = await useCase(
          validParams().copyWith(beltRank: 'Purple'),
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['beltRank'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('accepts valid belt ranks', () async {
        final validBelts = [
          'White',
          'Yellow',
          'Orange',
          'Green',
          'Blue',
          'Red',
          'Black',
          'Black 1st Dan',
        ];

        for (final belt in validBelts) {
          when(
            () => mockUserRepository.getCurrentUser(),
          ).thenAnswer((_) async => Right(testUser));
          when(
            () => mockDivisionRepository.getDivisionById(any()),
          ).thenAnswer((_) async => Right(testDivision));
          when(
            () => mockTournamentRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockParticipantRepository.createParticipant(any()),
          ).thenAnswer((invocation) async {
            final participant =
                invocation.positionalArguments.first as ParticipantEntity;
            return Right(participant);
          });

          final result = await useCase(validParams().copyWith(beltRank: belt));

          expect(
            result.isRight(),
            isTrue,
            reason: 'Belt "$belt" should be valid',
          );
        }
      });

      test('returns InputValidationFailure for negative weightKg', () async {
        final result = await useCase(validParams().copyWith(weightKg: -5));

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['weightKg'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('returns InputValidationFailure for weightKg > 150', () async {
        final result = await useCase(validParams().copyWith(weightKg: 160));

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['weightKg'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('returns InputValidationFailure for future dateOfBirth', () async {
        final futureDate = DateTime.now().add(const Duration(days: 365));
        final result = await useCase(
          validParams().copyWith(dateOfBirth: futureDate),
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['dateOfBirth'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('returns InputValidationFailure for age < 4', () async {
        final youngDate = DateTime.now().subtract(
          const Duration(days: 365 * 2),
        );
        final result = await useCase(
          validParams().copyWith(dateOfBirth: youngDate),
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['dateOfBirth'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('returns InputValidationFailure for age > 80', () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 365 * 85));
        final result = await useCase(
          validParams().copyWith(dateOfBirth: oldDate),
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<InputValidationFailure>());
          final validationFailure = failure as InputValidationFailure;
          expect(validationFailure.fieldErrors['dateOfBirth'], isNotNull);
        }, (_) => fail('Expected Left'));
      });

      test('accepts valid age range (4-80)', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockParticipantRepository.createParticipant(any()),
        ).thenAnswer((invocation) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final validAgeDate = DateTime.now().subtract(
          const Duration(days: 365 * 25),
        );
        final result = await useCase(
          validParams().copyWith(dateOfBirth: validAgeDate),
        );

        expect(result.isRight(), isTrue);
      });
    });

    group('organization verification', () {
      test(
        'returns AuthorizationPermissionDeniedFailure when user not authenticated',
        () async {
          when(() => mockUserRepository.getCurrentUser()).thenAnswer(
            (_) async => const Left(
              AuthenticationFailure(userFriendlyMessage: 'Not authenticated'),
            ),
          );

          final result = await useCase(validParams());

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns AuthorizationPermissionDeniedFailure when user has no organization',
        () async {
          final userNoOrg = testUser.copyWith(organizationId: '');
          when(
            () => mockUserRepository.getCurrentUser(),
          ).thenAnswer((_) async => Right(userNoOrg));

          final result = await useCase(validParams());

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('returns NotFoundFailure when division not found', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));

        final result = await useCase(validParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns NotFoundFailure when tournament not found', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));

        final result = await useCase(validParams());

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns AuthorizationPermissionDeniedFailure when tournament belongs to different organization',
        () async {
          final otherOrgTournament = testTournament.copyWith(
            organizationId: 'other-org',
          );
          when(
            () => mockUserRepository.getCurrentUser(),
          ).thenAnswer((_) async => Right(testUser));
          when(
            () => mockDivisionRepository.getDivisionById(any()),
          ).thenAnswer((_) async => Right(testDivision));
          when(
            () => mockTournamentRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(otherOrgTournament));

          final result = await useCase(validParams());

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('successful creation', () {
      test('creates participant with correct defaults', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockParticipantRepository.createParticipant(any()),
        ).thenAnswer((invocation) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(validParams());

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.divisionId, equals('division-123'));
          expect(participant.firstName, equals('John'));
          expect(participant.lastName, equals('Doe'));
          expect(participant.schoolOrDojangName, equals('TKD Academy'));
          expect(participant.beltRank, equals('Black'));
          expect(participant.checkInStatus, equals(ParticipantStatus.pending));
          expect(participant.isBye, isFalse);
          expect(participant.syncVersion, equals(1));
          expect(participant.isDeleted, isFalse);
          expect(participant.isDemoData, isFalse);
          expect(participant.seedNumber, isNull);
        });
      });

      test('trims whitespace from string fields', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockParticipantRepository.createParticipant(any()),
        ).thenAnswer((invocation) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(
          const CreateParticipantParams(
            divisionId: 'division-123',
            firstName: '  John  ',
            lastName: '  Doe  ',
            schoolOrDojangName: '  TKD Academy  ',
            beltRank: '  Black  ',
            registrationNumber: '  REG123  ',
            notes: '  Test notes  ',
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.firstName, equals('John'));
          expect(participant.lastName, equals('Doe'));
          expect(participant.schoolOrDojangName, equals('TKD Academy'));
          expect(participant.beltRank, equals('Black'));
          expect(participant.registrationNumber, equals('REG123'));
          expect(participant.notes, equals('Test notes'));
        });
      });

      test('generates UUID for participant id', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockParticipantRepository.createParticipant(any()),
        ).thenAnswer((invocation) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(validParams());

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(participant.id, isNotEmpty);
          expect(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ).hasMatch(participant.id),
            isTrue,
          );
        });
      });

      test('sets timestamps on creation', () async {
        final beforeCreation = DateTime.now();

        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockParticipantRepository.createParticipant(any()),
        ).thenAnswer((invocation) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        final result = await useCase(validParams());

        final afterCreation = DateTime.now();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (participant) {
          expect(
            participant.createdAtTimestamp.isAfter(
              beforeCreation.subtract(const Duration(seconds: 1)),
            ),
            isTrue,
          );
          expect(
            participant.createdAtTimestamp.isBefore(
              afterCreation.add(const Duration(seconds: 1)),
            ),
            isTrue,
          );
          expect(
            participant.updatedAtTimestamp,
            equals(participant.createdAtTimestamp),
          );
        });
      });

      test('delegates to participant repository', () async {
        when(
          () => mockUserRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockDivisionRepository.getDivisionById(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(
          () => mockTournamentRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockParticipantRepository.createParticipant(any()),
        ).thenAnswer((invocation) async {
          final participant =
              invocation.positionalArguments.first as ParticipantEntity;
          return Right(participant);
        });

        await useCase(validParams());

        verify(
          () => mockParticipantRepository.createParticipant(any()),
        ).called(1);
      });
    });
  });
}
