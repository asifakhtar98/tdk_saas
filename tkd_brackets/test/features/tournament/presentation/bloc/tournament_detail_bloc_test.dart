import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/conflict_warning.dart';
import 'package:tkd_brackets/features/division/domain/usecases/get_divisions_usecase.dart';
import 'package:tkd_brackets/features/division/domain/services/conflict_detection_service.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/update_tournament_settings_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_bloc.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_event.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_state.dart';

class MockGetTournamentUseCase extends Mock implements GetTournamentUseCase {}

class MockUpdateTournamentSettingsUseCase extends Mock
    implements UpdateTournamentSettingsUseCase {}

class MockDeleteTournamentUseCase extends Mock
    implements DeleteTournamentUseCase {}

class MockArchiveTournamentUseCase extends Mock
    implements ArchiveTournamentUseCase {}

class MockGetDivisionsUseCase extends Mock implements GetDivisionsUseCase {}

class MockConflictDetectionService extends Mock
    implements ConflictDetectionService {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

class FakeDivisionEntity extends Fake implements DivisionEntity {}

void main() {
  late MockGetTournamentUseCase mockGetTournamentUseCase;
  late MockUpdateTournamentSettingsUseCase mockUpdateTournamentSettingsUseCase;
  late MockDeleteTournamentUseCase mockDeleteTournamentUseCase;
  late MockArchiveTournamentUseCase mockArchiveTournamentUseCase;
  late MockGetDivisionsUseCase mockGetDivisionsUseCase;
  late MockConflictDetectionService mockConflictDetectionService;

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    createdByUserId: 'user-123',
    name: 'Test Tournament',
    federationType: FederationType.wt,
    status: TournamentStatus.active,
    numberOfRings: 2,
    settingsJson: const {},
    isTemplate: false,
    createdAt: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  final testDivision = DivisionEntity(
    id: 'division-123',
    tournamentId: 'tournament-123',
    name: 'Adults Male Sparring',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    ageMin: 18,
    ageMax: 32,
    weightMinKg: 60,
    weightMaxKg: 70,
    bracketFormat: BracketFormat.singleElimination,
    assignedRingNumber: 1,
    status: DivisionStatus.ready,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  final testConflict = ConflictWarning(
    id: 'conflict-123',
    participantId: 'participant-123',
    participantName: 'John Doe',
    dojangName: 'Test Dojang',
    divisionId1: 'division-123',
    divisionName1: 'Adults Male Sparring',
    ringNumber1: 1,
    divisionId2: 'division-456',
    divisionName2: 'Adults Male Poomsae',
    ringNumber2: 1,
    conflictType: ConflictType.sameRing,
  );

  setUpAll(() {
    registerFallbackValue('test-id');
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(FakeDivisionEntity());
    registerFallbackValue(
      UpdateTournamentSettingsParams(
        tournamentId: 'test',
        venueName: 'test',
        venueAddress: 'test',
        ringCount: 1,
      ),
    );
    registerFallbackValue(DeleteTournamentParams(tournamentId: ''));
    registerFallbackValue(ArchiveTournamentParams(tournamentId: ''));
  });

  setUp(() {
    mockGetTournamentUseCase = MockGetTournamentUseCase();
    mockUpdateTournamentSettingsUseCase = MockUpdateTournamentSettingsUseCase();
    mockDeleteTournamentUseCase = MockDeleteTournamentUseCase();
    mockArchiveTournamentUseCase = MockArchiveTournamentUseCase();
    mockGetDivisionsUseCase = MockGetDivisionsUseCase();
    mockConflictDetectionService = MockConflictDetectionService();
  });

  TournamentDetailBloc buildBloc() {
    return TournamentDetailBloc(
      mockGetTournamentUseCase,
      mockUpdateTournamentSettingsUseCase,
      mockDeleteTournamentUseCase,
      mockArchiveTournamentUseCase,
      mockGetDivisionsUseCase,
      mockConflictDetectionService,
    );
  }

  group('TournamentDetailBloc', () {
    test('initial state is TournamentDetailInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const TournamentDetailInitial());
      bloc.close();
    });

    group('TournamentDetailLoadRequested', () {
      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [loadInProgress, loadSuccess] when tournament loads successfully',
        build: () {
          when(
            () => mockGetTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockGetDivisionsUseCase(any()),
          ).thenAnswer((_) async => Right([testDivision]));
          when(
            () => mockConflictDetectionService.detectConflicts(any()),
          ).thenAnswer((_) async => const Right([]));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailLoadRequested('tournament-123')),
        expect: () => [
          const TournamentDetailLoadInProgress(),
          isA<TournamentDetailLoadSuccess>()
              .having((s) => s.tournament.id, 'tournament id', 'tournament-123')
              .having((s) => s.divisions.length, 'divisions length', 1)
              .having((s) => s.conflicts.length, 'conflicts length', 0),
        ],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [loadInProgress, loadSuccess] with conflicts when detected',
        build: () {
          when(
            () => mockGetTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockGetDivisionsUseCase(any()),
          ).thenAnswer((_) async => Right([testDivision]));
          when(
            () => mockConflictDetectionService.detectConflicts(any()),
          ).thenAnswer((_) async => Right([testConflict]));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailLoadRequested('tournament-123')),
        expect: () => [
          const TournamentDetailLoadInProgress(),
          isA<TournamentDetailLoadSuccess>()
              .having((s) => s.conflicts.length, 'conflicts length', 1)
              .having(
                (s) => s.conflicts.first.participantName,
                'participant',
                'John Doe',
              ),
        ],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [loadInProgress, loadFailure] when tournament not found',
        build: () {
          when(() => mockGetTournamentUseCase(any())).thenAnswer(
            (_) async => const Left(
              NotFoundFailure(
                userFriendlyMessage: 'Tournament not found',
                technicalDetails: 'No tournament with ID',
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailLoadRequested('tournament-123')),
        expect: () => [
          const TournamentDetailLoadInProgress(),
          isA<TournamentDetailLoadFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Tournament not found',
          ),
        ],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'handles division load failure gracefully',
        build: () {
          when(
            () => mockGetTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(() => mockGetDivisionsUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerConnectionFailure(
                userFriendlyMessage: 'Failed to load divisions',
                technicalDetails: 'DB error',
              ),
            ),
          );
          when(
            () => mockConflictDetectionService.detectConflicts(any()),
          ).thenAnswer((_) async => const Right([]));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailLoadRequested('tournament-123')),
        expect: () => [
          const TournamentDetailLoadInProgress(),
          isA<TournamentDetailLoadSuccess>().having(
            (s) => s.divisions.length,
            'divisions',
            0,
          ),
        ],
      );
    });

    group('TournamentDetailUpdateRequested', () {
      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [updateInProgress, updateSuccess] when update succeeds',
        build: () {
          when(() => mockUpdateTournamentSettingsUseCase(any())).thenAnswer(
            (_) async => Right(
              testTournament.copyWith(venueName: 'New Venue', numberOfRings: 3),
            ),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          TournamentDetailUpdateRequested(
            'tournament-123',
            'New Venue',
            'New Address',
            3,
          ),
        ),
        expect: () => [
          const TournamentDetailUpdateInProgress(),
          isA<TournamentDetailUpdateSuccess>().having(
            (s) => s.tournament.venueName,
            'venueName',
            'New Venue',
          ),
        ],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [updateInProgress, updateFailure] when update fails',
        build: () {
          when(() => mockUpdateTournamentSettingsUseCase(any())).thenAnswer(
            (_) async => const Left(
              ValidationFailure(
                userFriendlyMessage: 'Validation failed',
                fieldErrors: {},
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          TournamentDetailUpdateRequested('tournament-123', '', null, null),
        ),
        expect: () => [
          const TournamentDetailUpdateInProgress(),
          isA<TournamentDetailUpdateFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Validation failed',
          ),
        ],
      );
    });

    group('TournamentDetailDeleteRequested', () {
      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [deleteSuccess] when delete succeeds',
        build: () {
          when(
            () => mockDeleteTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailDeleteRequested('tournament-123')),
        expect: () => [const TournamentDetailDeleteSuccess()],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [deleteFailure] when delete fails',
        build: () {
          when(() => mockDeleteTournamentUseCase(any())).thenAnswer(
            (_) async => const Left(
              AuthorizationPermissionDeniedFailure(
                userFriendlyMessage: 'Only owners can delete',
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailDeleteRequested('tournament-123')),
        expect: () => [
          isA<TournamentDetailDeleteFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Only owners can delete',
          ),
        ],
      );
    });

    group('TournamentDetailArchiveRequested', () {
      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [archiveSuccess] when archive succeeds',
        build: () {
          when(() => mockArchiveTournamentUseCase(any())).thenAnswer(
            (_) async => Right(
              testTournament.copyWith(status: TournamentStatus.archived),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailArchiveRequested('tournament-123')),
        expect: () => [
          isA<TournamentDetailArchiveSuccess>().having(
            (s) => s.tournament.status,
            'status',
            TournamentStatus.archived,
          ),
        ],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'emits [archiveFailure] when archive fails',
        build: () {
          when(() => mockArchiveTournamentUseCase(any())).thenAnswer(
            (_) async => const Left(
              TournamentActiveFailure(
                userFriendlyMessage: 'Cannot archive active tournament',
                technicalDetails: 'Tournament has matches in progress',
                activeMatchCount: 5,
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentDetailArchiveRequested('tournament-123')),
        expect: () => [
          isA<TournamentDetailArchiveFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Cannot archive active tournament',
          ),
        ],
      );
    });

    group('ConflictDismissed', () {
      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'adds conflict ID to dismissed list',
        build: () => buildBloc(),
        seed: () => TournamentDetailLoadSuccess(
          tournament: testTournament,
          divisions: [testDivision],
          conflicts: [testConflict],
          dismissedConflictIds: const [],
        ),
        act: (bloc) => bloc.add(const ConflictDismissed('conflict-123')),
        expect: () => [
          isA<TournamentDetailLoadSuccess>().having(
            (s) => s.dismissedConflictIds,
            'dismissed',
            ['conflict-123'],
          ),
        ],
      );

      blocTest<TournamentDetailBloc, TournamentDetailState>(
        'does nothing when not in loadSuccess state',
        build: () => buildBloc(),
        seed: () => const TournamentDetailInitial(),
        act: (bloc) => bloc.add(const ConflictDismissed('conflict-123')),
        expect: () => [],
      );
    });
  });
}
