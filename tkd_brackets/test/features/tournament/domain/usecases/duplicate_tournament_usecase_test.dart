import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/duplicate_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/duplicate_tournament_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockDivisionRepository extends Mock implements DivisionRepository {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late DuplicateTournamentUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockAuthRepository mockAuthRepository;
  late MockDivisionRepository mockDivisionRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeDivisionEntity());
    registerFallbackValue(FakeUserEntity());
    registerFallbackValue(
      const DuplicateTournamentParams(sourceTournamentId: 'test-id'),
    );
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockAuthRepository = MockAuthRepository();
    mockDivisionRepository = MockDivisionRepository();
    useCase = DuplicateTournamentUseCase(
      mockRepository,
      mockAuthRepository,
      mockDivisionRepository,
    );
  });

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    name: 'Spring Championship 2026',
    federationType: FederationType.wt,
    numberOfRings: 2,
    settingsJson: const {},
    status: TournamentStatus.completed,
    isTemplate: false,
    syncVersion: 5,
    isDeleted: false,
    createdAt: DateTime(2024),
    updatedAtTimestamp: DateTime(2024),
    completedAtTimestamp: DateTime(2026, 3, 16),
    scheduledDate: DateTime(2026, 3, 15),
    createdByUserId: 'user-123',
  );

  final testSoftDeletedTournament = testTournament.copyWith(
    isDeleted: true,
    deletedAtTimestamp: DateTime(2026, 1, 1),
  );

  final testDivision = DivisionEntity(
    id: 'division-123',
    tournamentId: 'tournament-123',
    name: 'Cadets -45kg Male',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    ageMin: 12,
    ageMax: 14,
    weightMinKg: 40,
    weightMaxKg: 45,
    beltRankMin: null,
    beltRankMax: null,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.ready,
    syncVersion: 1,
    isDeleted: false,
    createdAtTimestamp: DateTime(2024),
    updatedAtTimestamp: DateTime(2024),
    isDemoData: false,
    isCustom: true,
  );

  final testDeletedDivision = testDivision.copyWith(isDeleted: true);

  final testOwner = UserEntity(
    id: 'user-123',
    email: 'owner@example.com',
    displayName: 'Owner User',
    organizationId: 'org-456',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final testAdmin = testOwner.copyWith(role: UserRole.admin);
  final testViewer = testOwner.copyWith(role: UserRole.viewer);
  final testScorer = testOwner.copyWith(role: UserRole.scorer);

  group('DuplicateTournamentUseCase', () {
    group('validation and errors', () {
      test(
        'returns NotFoundFailure when source tournament does not exist',
        () async {
          when(() => mockRepository.getTournamentById(any())).thenAnswer(
            (_) async =>
                const Left(NotFoundFailure(userFriendlyMessage: 'Not found')),
          );

          final result = await useCase(
            const DuplicateTournamentParams(sourceTournamentId: 'nonexistent'),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when source tournament returns null',
        () async {
          // Repository returns Left for null tournament (simulating database not found)
          when(() => mockRepository.getTournamentById(any())).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(userFriendlyMessage: 'Tournament not found'),
            ),
          );

          final result = await useCase(
            const DuplicateTournamentParams(
              sourceTournamentId: 'null-tournament',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns NotFoundFailure when source tournament is soft-deleted',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testSoftDeletedTournament));

          final result = await useCase(
            const DuplicateTournamentParams(
              sourceTournamentId: 'tournament-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<NotFoundFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns AuthenticationFailure when user not authenticated',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer(
            (_) async => const Left(
              AuthenticationFailure(userFriendlyMessage: 'Not authenticated'),
            ),
          );

          final result = await useCase(
            const DuplicateTournamentParams(
              sourceTournamentId: 'tournament-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<AuthenticationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns AuthorizationPermissionDeniedFailure for Viewer role',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testViewer));

          final result = await useCase(
            const DuplicateTournamentParams(
              sourceTournamentId: 'tournament-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test(
        'returns AuthorizationPermissionDeniedFailure for Scorer role',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testScorer));

          final result = await useCase(
            const DuplicateTournamentParams(
              sourceTournamentId: 'tournament-123',
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('successful duplication', () {
      test('duplicates tournament with Owner role', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });

        final result = await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.createTournament(any(), any())).called(1);

        final duplicated = result.getOrElse((failure) => testTournament);
        expect(duplicated.name, contains('(Copy)'));
        expect(duplicated.status, TournamentStatus.draft);
        expect(duplicated.isTemplate, isTrue);
        expect(duplicated.syncVersion, 0);
        expect(duplicated.id, isNot(testTournament.id));
      });

      test('duplicates tournament with Admin role', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testAdmin));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });

        final result = await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
      });

      test('duplicates divisions with new UUIDs', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => Right([testDivision]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });
        when(() => mockDivisionRepository.createDivision(any())).thenAnswer((
          invocation,
        ) async {
          final division = invocation.positionalArguments[0] as DivisionEntity;
          return Right(division);
        });

        final result = await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);

        final captured =
            verify(
                  () => mockDivisionRepository.createDivision(captureAny()),
                ).captured.single
                as DivisionEntity;
        expect(captured.id, isNot(testDivision.id));
        expect(captured.tournamentId, isNot(testDivision.tournamentId));
      });

      test('excludes soft-deleted divisions from duplication', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => Right([testDivision, testDeletedDivision]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });
        when(() => mockDivisionRepository.createDivision(any())).thenAnswer((
          invocation,
        ) async {
          final division = invocation.positionalArguments[0] as DivisionEntity;
          return Right(division);
        });

        final result = await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
        verify(() => mockDivisionRepository.createDivision(any())).called(1);
      });

      test('handles empty divisions list correctly', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });

        final result = await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
        verifyNever(() => mockDivisionRepository.createDivision(any()));
      });

      test('handles custom divisions (isCustom: true) correctly', () async {
        final customDivision = testDivision.copyWith(isCustom: true);
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => Right([customDivision]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });
        when(() => mockDivisionRepository.createDivision(any())).thenAnswer((
          invocation,
        ) async {
          final division = invocation.positionalArguments[0] as DivisionEntity;
          return Right(division);
        });

        final result = await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);

        final captured =
            verify(
                  () => mockDivisionRepository.createDivision(captureAny()),
                ).captured.single
                as DivisionEntity;
        expect(captured.isCustom, isTrue);
      });

      test('does not copy participants (only divisions)', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });

        await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        verifyNever(() => mockDivisionRepository.createDivision(any()));
      });

      test('sets createdByUserId to current user', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockRepository.createTournament(any(), any())).thenAnswer((
          invocation,
        ) async {
          final tournament =
              invocation.positionalArguments[0] as TournamentEntity;
          return Right(tournament);
        });

        await useCase(
          const DuplicateTournamentParams(sourceTournamentId: 'tournament-123'),
        );

        final captured =
            verify(
                  () => mockRepository.createTournament(captureAny(), any()),
                ).captured.single
                as TournamentEntity;
        expect(captured.createdByUserId, testOwner.id);
      });
    });
  });
}
