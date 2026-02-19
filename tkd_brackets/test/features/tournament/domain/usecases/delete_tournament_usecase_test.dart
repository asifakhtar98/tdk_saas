import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

class FakeDeleteTournamentParams extends Fake
    implements DeleteTournamentParams {}

void main() {
  late DeleteTournamentUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
    registerFallbackValue(FakeDivisionEntity());
    registerFallbackValue(FakeDeleteTournamentParams());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = DeleteTournamentUseCase(mockRepository, mockAuthRepository);
  });

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    createdByUserId: 'user-123',
    name: 'Test Tournament',
    scheduledDate: DateTime(2026, 3, 15),
    federationType: FederationType.wt,
    status: TournamentStatus.completed,
    numberOfRings: 2,
    settingsJson: {},
    isTemplate: false,
    createdAt: DateTime(2024),
    updatedAtTimestamp: DateTime(2024),
    isDeleted: false,
    syncVersion: 0,
  );

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

  group('DeleteTournamentUseCase', () {
    group('authorization (Owner ONLY)', () {
      test(
        'returns AuthorizationPermissionDeniedFailure for Admin (delete is Owner-only)',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testAdmin));

          final result = await useCase(
            DeleteTournamentParams(tournamentId: 'tournament-123'),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure, isA<AuthorizationPermissionDeniedFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('allows Owner to delete', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => const Right([]));
        when(() => mockRepository.updateTournament(any())).thenAnswer((
          invocation,
        ) async {
          final entity = invocation.positionalArguments[0] as TournamentEntity;
          return Right(entity);
        });

        final result = await useCase(
          DeleteTournamentParams(tournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
      });
    });

    group('soft delete', () {
      test(
        'sets isDeleted=true, deletedAtTimestamp=now, increments syncVersion',
        () async {
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testOwner));
          when(
            () => mockRepository.getDivisionsByTournamentId(any()),
          ).thenAnswer((_) async => const Right([]));
          when(() => mockRepository.updateTournament(any())).thenAnswer((
            invocation,
          ) async {
            final entity =
                invocation.positionalArguments[0] as TournamentEntity;
            return Right(entity);
          });

          final result = await useCase(
            DeleteTournamentParams(
              tournamentId: 'tournament-123',
              hardDelete: false,
            ),
          );

          expect(result.isRight(), isTrue);
          final deleted = result.fold(
            (failure) => testTournament,
            (tournament) => tournament,
          );
          expect(deleted.isDeleted, isTrue);
          expect(deleted.deletedAtTimestamp, isNotNull);
          expect(deleted.syncVersion, 1);
        },
      );
    });

    group('hard delete', () {
      test('calls repository.hardDeleteTournament', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.hardDeleteTournament(any()),
        ).thenAnswer((_) async => const Right(unit));

        final result = await useCase(
          DeleteTournamentParams(
            tournamentId: 'tournament-123',
            hardDelete: true,
          ),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockRepository.hardDeleteTournament('tournament-123'),
        ).called(1);
      });
    });

    group('cascade delete', () {
      test('soft-deletes divisions when tournament is soft-deleted', () async {
        final testDivision = DivisionEntity(
          id: 'division-1',
          tournamentId: 'tournament-123',
          name: 'Test Division',
          category: DivisionCategory.sparring,
          gender: DivisionGender.male,
          bracketFormat: BracketFormat.singleElimination,
          status: DivisionStatus.completed,
          createdAtTimestamp: DateTime(2024),
          updatedAtTimestamp: DateTime(2024),
          syncVersion: 0,
        );

        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(
          () => mockRepository.getDivisionsByTournamentId(any()),
        ).thenAnswer((_) async => Right([testDivision]));
        when(
          () => mockRepository.updateDivision(any()),
        ).thenAnswer((_) async => Right(testDivision));
        when(() => mockRepository.updateTournament(any())).thenAnswer((
          invocation,
        ) async {
          final entity = invocation.positionalArguments[0] as TournamentEntity;
          return Right<Failure, TournamentEntity>(entity);
        });

        final result = await useCase(
          DeleteTournamentParams(tournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockRepository.getDivisionsByTournamentId('tournament-123'),
        ).called(1);
      });
    });

    group('validation errors', () {
      test('returns NotFoundFailure when tournament does not exist', () async {
        when(() => mockRepository.getTournamentById(any())).thenAnswer(
          (_) async =>
              const Left(NotFoundFailure(userFriendlyMessage: 'Not found')),
        );

        final result = await useCase(
          DeleteTournamentParams(tournamentId: 'nonexistent'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns TournamentActiveFailure when tournament is active',
        () async {
          final activeTournament = testTournament.copyWith(
            status: TournamentStatus.active,
          );

          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(activeTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testOwner));

          final result = await useCase(
            DeleteTournamentParams(tournamentId: 'tournament-123'),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<TournamentActiveFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });
  });
}
