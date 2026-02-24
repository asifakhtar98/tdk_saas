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
import 'package:tkd_brackets/features/participant/domain/usecases/get_division_participants_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';

// ── Mocks (mocktail pattern — NO @GenerateMocks) ──
class MockParticipantRepository extends Mock implements ParticipantRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetDivisionParticipantsUseCase useCase;
  late MockParticipantRepository mockParticipantRepo;
  late MockDivisionRepository mockDivisionRepo;
  late MockTournamentRepository mockTournamentRepo;
  late MockUserRepository mockUserRepo;

  setUp(() {
    mockParticipantRepo = MockParticipantRepository();
    mockDivisionRepo = MockDivisionRepository();
    mockTournamentRepo = MockTournamentRepository();
    mockUserRepo = MockUserRepository();
    useCase = GetDivisionParticipantsUseCase(
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

  final tParticipant1 = ParticipantEntity(
    id: 'p1',
    divisionId: 'division-id',
    firstName: 'Alice',
    lastName: 'Kim',
    schoolOrDojangName: 'Seoul Dojang',
    seedNumber: 1,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  final tParticipant2 = ParticipantEntity(
    id: 'p2',
    divisionId: 'division-id',
    firstName: 'Bob',
    lastName: 'Lee',
    schoolOrDojangName: 'Busan Dojang',
    seedNumber: 2,
    createdAtTimestamp: DateTime(2024, 1, 1),
    updatedAtTimestamp: DateTime(2024, 1, 1),
  );

  void setupSuccessMocks({List<ParticipantEntity>? participants}) {
    when(
      () => mockUserRepo.getCurrentUser(),
    ).thenAnswer((_) async => Right(tUser));
    when(
      () => mockDivisionRepo.getDivisionById('division-id'),
    ).thenAnswer((_) async => Right(tDivision));
    when(
      () => mockTournamentRepo.getTournamentById('tournament-id'),
    ).thenAnswer((_) async => Right(tTournament));
    when(
      () => mockParticipantRepo.getParticipantsForDivision('division-id'),
    ).thenAnswer(
      (_) async => Right(participants ?? [tParticipant1, tParticipant2]),
    );
  }

  test(
    'should return participants and division info for valid division',
    () async {
      // arrange
      setupSuccessMocks();

      // act
      final result = await useCase('division-id');

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should not be left'), (view) {
        expect(view.division, tDivision);
        expect(view.participants.length, 2);
        expect(view.participantCount, 2);
      });
      verify(() => mockUserRepo.getCurrentUser()).called(1);
      verify(() => mockDivisionRepo.getDivisionById('division-id')).called(1);
      verify(
        () => mockTournamentRepo.getTournamentById('tournament-id'),
      ).called(1);
      verify(
        () => mockParticipantRepo.getParticipantsForDivision('division-id'),
      ).called(1);
    },
  );

  test('should return empty list when division has no participants', () async {
    // arrange
    setupSuccessMocks(participants: []);

    // act
    final result = await useCase('division-id');

    // assert
    expect(result.isRight(), true);
    final view = result.getOrElse((_) => throw Exception());
    expect(view.participants.isEmpty, true);
    expect(view.participantCount, 0);
  });

  test('should return InputValidationFailure for empty divisionId', () async {
    // act
    final result = await useCase('');

    // assert
    expect(result.isLeft(), true);
    expect(result.fold((l) => l, (r) => r), isA<InputValidationFailure>());
  });

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
      final result = await useCase('division-id');

      // assert
      expect(result.isLeft(), true);
      expect(
        result.fold((l) => l, (r) => r),
        isA<AuthorizationPermissionDeniedFailure>(),
      );
    },
  );

  test(
    'should return AuthorizationPermissionDeniedFailure when user has empty organizationId',
    () async {
      // arrange
      when(
        () => mockUserRepo.getCurrentUser(),
      ).thenAnswer((_) async => Right(tUser.copyWith(organizationId: '')));

      // act
      final result = await useCase('division-id');

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
    final result = await useCase('division-id');

    // assert
    expect(result.isLeft(), true);
    expect(result.fold((l) => l, (r) => r), isA<NotFoundFailure>());
  });

  test('should return NotFoundFailure when tournament not found', () async {
    // arrange
    when(
      () => mockUserRepo.getCurrentUser(),
    ).thenAnswer((_) async => Right(tUser));
    when(
      () => mockDivisionRepo.getDivisionById('division-id'),
    ).thenAnswer((_) async => Right(tDivision));
    when(
      () => mockTournamentRepo.getTournamentById('tournament-id'),
    ).thenAnswer(
      (_) async =>
          const Left(NotFoundFailure(userFriendlyMessage: 'Not found')),
    );

    // act
    final result = await useCase('division-id');

    // assert
    expect(result.isLeft(), true);
    expect(result.fold((l) => l, (r) => r), isA<NotFoundFailure>());
  });

  test(
    "should return AuthorizationPermissionDeniedFailure when user org doesn't match tournament org",
    () async {
      // arrange
      when(
        () => mockUserRepo.getCurrentUser(),
      ).thenAnswer((_) async => Right(tUser));
      when(
        () => mockDivisionRepo.getDivisionById('division-id'),
      ).thenAnswer((_) async => Right(tDivision));
      when(
        () => mockTournamentRepo.getTournamentById('tournament-id'),
      ).thenAnswer(
        (_) async => Right(tTournament.copyWith(organizationId: 'other-org')),
      );

      // act
      final result = await useCase('division-id');

      // assert
      expect(result.isLeft(), true);
      expect(
        result.fold((l) => l, (r) => r),
        isA<AuthorizationPermissionDeniedFailure>(),
      );
    },
  );

  test(
    'should propagate repository failure from getParticipantsForDivision',
    () async {
      // arrange
      when(
        () => mockUserRepo.getCurrentUser(),
      ).thenAnswer((_) async => Right(tUser));
      when(
        () => mockDivisionRepo.getDivisionById('division-id'),
      ).thenAnswer((_) async => Right(tDivision));
      when(
        () => mockTournamentRepo.getTournamentById('tournament-id'),
      ).thenAnswer((_) async => Right(tTournament));
      when(
        () => mockParticipantRepo.getParticipantsForDivision('division-id'),
      ).thenAnswer(
        (_) async =>
            const Left(LocalCacheAccessFailure(userFriendlyMessage: 'Error')),
      );

      // act
      final result = await useCase('division-id');

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => r), isA<LocalCacheAccessFailure>());
    },
  );
}
