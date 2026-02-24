import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/repositories/tournament_repository.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeUserEntity extends Fake implements UserEntity {}

class FakeArchiveTournamentParams extends Fake
    implements ArchiveTournamentParams {}

void main() {
  late ArchiveTournamentUseCase useCase;
  late MockTournamentRepository mockRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeUserEntity());
    registerFallbackValue(FakeArchiveTournamentParams());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = ArchiveTournamentUseCase(mockRepository, mockAuthRepository);
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

  final testAdmin = UserEntity(
    id: 'user-456',
    email: 'admin@example.com',
    displayName: 'Admin User',
    organizationId: 'org-456',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('ArchiveTournamentUseCase', () {
    group('validation and errors', () {
      test('returns NotFoundFailure when tournament does not exist', () async {
        when(() => mockRepository.getTournamentById(any())).thenAnswer(
          (_) async =>
              const Left(NotFoundFailure(userFriendlyMessage: 'Not found')),
        );

        final result = await useCase(
          const ArchiveTournamentParams(tournamentId: 'nonexistent'),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });

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
            const ArchiveTournamentParams(tournamentId: 'tournament-123'),
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
          final testViewer = testOwner.copyWith(role: UserRole.viewer);
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testViewer));

          final result = await useCase(
            const ArchiveTournamentParams(tournamentId: 'tournament-123'),
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
          final testScorer = testOwner.copyWith(role: UserRole.scorer);
          when(
            () => mockRepository.getTournamentById(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockAuthRepository.getCurrentAuthenticatedUser(),
          ).thenAnswer((_) async => Right(testScorer));

          final result = await useCase(
            const ArchiveTournamentParams(tournamentId: 'tournament-123'),
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
            const ArchiveTournamentParams(tournamentId: 'tournament-123'),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<TournamentActiveFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );
    });

    group('successful archive', () {
      test('archives tournament with Owner role', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(
            testTournament.copyWith(
              status: TournamentStatus.archived,
              syncVersion: 1,
            ),
          ),
        );

        final result = await useCase(
          const ArchiveTournamentParams(tournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
        verify(() => mockRepository.updateTournament(any())).called(1);

        final archived = result.fold(
          (failure) => testTournament,
          (tournament) => tournament,
        );
        expect(archived.status, TournamentStatus.archived);
        expect(archived.syncVersion, 1);
      });

      test('archives tournament with Admin role', () async {
        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(testTournament));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testAdmin));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(
            testTournament.copyWith(
              status: TournamentStatus.archived,
              syncVersion: 1,
            ),
          ),
        );

        final result = await useCase(
          const ArchiveTournamentParams(tournamentId: 'tournament-123'),
        );

        expect(result.isRight(), isTrue);
      });

      test('increments syncVersion correctly', () async {
        final tournamentWithVersion = testTournament.copyWith(syncVersion: 5);

        when(
          () => mockRepository.getTournamentById(any()),
        ).thenAnswer((_) async => Right(tournamentWithVersion));
        when(
          () => mockAuthRepository.getCurrentAuthenticatedUser(),
        ).thenAnswer((_) async => Right(testOwner));
        when(() => mockRepository.updateTournament(any())).thenAnswer(
          (_) async => Right(
            tournamentWithVersion.copyWith(
              status: TournamentStatus.archived,
              syncVersion: 6,
            ),
          ),
        );

        final result = await useCase(
          const ArchiveTournamentParams(tournamentId: 'tournament-123'),
        );

        final archived = result.fold(
          (failure) => testTournament,
          (tournament) => tournament,
        );
        expect(archived.syncVersion, 6);
      });
    });
  });
}
