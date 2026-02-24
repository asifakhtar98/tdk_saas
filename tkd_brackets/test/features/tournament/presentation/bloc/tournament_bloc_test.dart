import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/archive_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/create_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_params.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/delete_tournament_usecase.dart';
import 'package:tkd_brackets/features/tournament/domain/usecases/get_tournaments_usecase.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_bloc.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_event.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_state.dart';

class MockGetTournamentsUseCase extends Mock implements GetTournamentsUseCase {}

class MockArchiveTournamentUseCase extends Mock
    implements ArchiveTournamentUseCase {}

class MockDeleteTournamentUseCase extends Mock
    implements DeleteTournamentUseCase {}

class MockCreateTournamentUseCase extends Mock
    implements CreateTournamentUseCase {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

void main() {
  late MockGetTournamentsUseCase mockGetTournamentsUseCase;
  late MockArchiveTournamentUseCase mockArchiveTournamentUseCase;
  late MockDeleteTournamentUseCase mockDeleteTournamentUseCase;
  late MockCreateTournamentUseCase mockCreateTournamentUseCase;

  final testTournament = TournamentEntity(
    id: 'tournament-123',
    organizationId: 'org-456',
    createdByUserId: 'user-123',
    name: 'Test Tournament',
    federationType: FederationType.wt,
    status: TournamentStatus.draft,
    numberOfRings: 2,
    settingsJson: const {},
    isTemplate: false,
    createdAt: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  final testTournaments = [
    testTournament,
    testTournament.copyWith(
      id: 'tournament-456',
      name: 'Second Tournament',
      status: TournamentStatus.active,
    ),
  ];

  setUpAll(() {
    registerFallbackValue('test-org');
    registerFallbackValue(FakeTournamentEntity());
    registerFallbackValue(const ArchiveTournamentParams(tournamentId: ''));
    registerFallbackValue(const DeleteTournamentParams(tournamentId: ''));
    registerFallbackValue(
      CreateTournamentParams(name: 'test', scheduledDate: DateTime.now()),
    );
  });

  setUp(() {
    mockGetTournamentsUseCase = MockGetTournamentsUseCase();
    mockArchiveTournamentUseCase = MockArchiveTournamentUseCase();
    mockDeleteTournamentUseCase = MockDeleteTournamentUseCase();
    mockCreateTournamentUseCase = MockCreateTournamentUseCase();
  });

  TournamentBloc buildBloc() {
    return TournamentBloc(
      mockGetTournamentsUseCase,
      mockArchiveTournamentUseCase,
      mockDeleteTournamentUseCase,
      mockCreateTournamentUseCase,
    );
  }

  group('TournamentBloc', () {
    test('initial state is TournamentInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const TournamentInitial());
      bloc.close();
    });

    group('TournamentLoadRequested', () {
      blocTest<TournamentBloc, TournamentState>(
        'emits [loadInProgress, loadSuccess] when tournaments loaded successfully',
        build: () {
          when(
            () => mockGetTournamentsUseCase(any()),
          ).thenAnswer((_) async => Right(testTournaments));
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentLoadRequested(organizationId: 'org-456')),
        expect: () => [
          const TournamentLoadInProgress(),
          isA<TournamentLoadSuccess>()
              .having((s) => s.tournaments.length, 'tournaments length', 2)
              .having((s) => s.currentFilter, 'filter', TournamentFilter.all),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'emits [loadInProgress, loadFailure] when loading fails',
        build: () {
          when(() => mockGetTournamentsUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerConnectionFailure(
                userFriendlyMessage: 'Failed to load',
                technicalDetails: 'Database error',
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const TournamentLoadRequested(organizationId: 'org-456')),
        expect: () => [
          const TournamentLoadInProgress(),
          isA<TournamentLoadFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Failed to load',
          ),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'uses default organization ID when not provided',
        build: () {
          when(
            () => mockGetTournamentsUseCase(any()),
          ).thenAnswer((_) async => const Right([]));
          return buildBloc();
        },
        act: (bloc) => bloc.add(const TournamentLoadRequested()),
        verify: (_) {
          verify(() => mockGetTournamentsUseCase('default-org')).called(1);
        },
      );
    });

    group('TournamentRefreshRequested', () {
      blocTest<TournamentBloc, TournamentState>(
        'emits [loadInProgress, loadSuccess] with current filter preserved',
        build: () {
          when(
            () => mockGetTournamentsUseCase(any()),
          ).thenAnswer((_) async => Right(testTournaments));
          return buildBloc();
        },
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.draft,
        ),
        act: (bloc) => bloc.add(
          const TournamentRefreshRequested(organizationId: 'org-456'),
        ),
        expect: () => [
          const TournamentLoadInProgress(),
          isA<TournamentLoadSuccess>().having(
            (s) => s.currentFilter,
            'filter',
            TournamentFilter.draft,
          ),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'emits failure when no organization is set',
        build: buildBloc,
        seed: () => const TournamentInitial(),
        act: (bloc) => bloc.add(const TournamentRefreshRequested()),
        expect: () => [
          isA<TournamentLoadFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'No organization selected',
          ),
        ],
      );
    });

    group('TournamentFilterChanged', () {
      blocTest<TournamentBloc, TournamentState>(
        'filters tournaments by draft status',
        build: buildBloc,
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) =>
            bloc.add(const TournamentFilterChanged(TournamentFilter.draft)),
        expect: () => [
          isA<TournamentLoadSuccess>()
              .having((s) => s.currentFilter, 'filter', TournamentFilter.draft)
              .having((s) => s.tournaments.length, 'filtered length', 1),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'filters tournaments by active status',
        build: buildBloc,
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) =>
            bloc.add(const TournamentFilterChanged(TournamentFilter.active)),
        expect: () => [
          isA<TournamentLoadSuccess>()
              .having((s) => s.currentFilter, 'filter', TournamentFilter.active)
              .having((s) => s.tournaments.length, 'filtered length', 1),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'filters tournaments by archived status',
        build: buildBloc,
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) =>
            bloc.add(const TournamentFilterChanged(TournamentFilter.archived)),
        expect: () => [
          isA<TournamentLoadSuccess>()
              .having(
                (s) => s.currentFilter,
                'filter',
                TournamentFilter.archived,
              )
              .having((s) => s.tournaments.length, 'filtered length', 0),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'does nothing when not in loadSuccess state',
        build: buildBloc,
        seed: () => const TournamentInitial(),
        act: (bloc) =>
            bloc.add(const TournamentFilterChanged(TournamentFilter.draft)),
        expect: () => [],
      );
    });

    group('TournamentDeleted', () {
      blocTest<TournamentBloc, TournamentState>(
        'refreshes list after successful delete',
        build: () {
          when(
            () => mockDeleteTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockGetTournamentsUseCase(any()),
          ).thenAnswer((_) async => Right([testTournaments.first]));
          return buildBloc();
        },
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) {
          bloc.add(const TournamentDeleted('tournament-123'));
        },
        verify: (_) {
          verify(() => mockDeleteTournamentUseCase(any())).called(1);
        },
      );

      blocTest<TournamentBloc, TournamentState>(
        'emits failure when delete fails',
        build: () {
          when(() => mockDeleteTournamentUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerConnectionFailure(
                userFriendlyMessage: 'Delete failed',
                technicalDetails: 'DB error',
              ),
            ),
          );
          return buildBloc();
        },
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) => bloc.add(const TournamentDeleted('tournament-123')),
        expect: () => [
          isA<TournamentLoadFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Delete failed',
          ),
        ],
      );
    });

    group('TournamentArchived', () {
      blocTest<TournamentBloc, TournamentState>(
        'refreshes list after successful archive',
        build: () {
          when(
            () => mockArchiveTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockGetTournamentsUseCase(any()),
          ).thenAnswer((_) async => Right([testTournaments.first]));
          return buildBloc();
        },
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) => bloc.add(const TournamentArchived('tournament-123')),
        verify: (_) {
          verify(() => mockArchiveTournamentUseCase(any())).called(1);
        },
      );

      blocTest<TournamentBloc, TournamentState>(
        'emits failure when archive fails',
        build: () {
          when(() => mockArchiveTournamentUseCase(any())).thenAnswer(
            (_) async => const Left(
              ServerConnectionFailure(
                userFriendlyMessage: 'Archive failed',
                technicalDetails: 'DB error',
              ),
            ),
          );
          return buildBloc();
        },
        seed: () => TournamentLoadSuccess(
          tournaments: testTournaments,
          currentFilter: TournamentFilter.all,
        ),
        act: (bloc) => bloc.add(const TournamentArchived('tournament-123')),
        expect: () => [
          isA<TournamentLoadFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Archive failed',
          ),
        ],
      );
    });

    group('TournamentCreateRequested', () {
      blocTest<TournamentBloc, TournamentState>(
        'emits [createInProgress, createSuccess, loadInProgress] on success',
        build: () {
          when(
            () => mockCreateTournamentUseCase(any()),
          ).thenAnswer((_) async => Right(testTournament));
          when(
            () => mockGetTournamentsUseCase(any()),
          ).thenAnswer((_) async => Right([testTournament]));
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          TournamentCreateRequested(
            name: 'New Tournament',
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
            description: 'Test description',
          ),
        ),
        expect: () => [
          const TournamentCreateInProgress(),
          const TournamentCreateSuccess(),
          const TournamentLoadInProgress(),
          isA<TournamentLoadSuccess>(),
        ],
      );

      blocTest<TournamentBloc, TournamentState>(
        'emits [createInProgress, createFailure] on failure',
        build: () {
          when(() => mockCreateTournamentUseCase(any())).thenAnswer(
            (_) async => const Left(
              InputValidationFailure(
                userFriendlyMessage: 'Name is required',
                fieldErrors: {},
              ),
            ),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(
          TournamentCreateRequested(
            name: '',
            scheduledDate: DateTime.now().add(const Duration(days: 7)),
          ),
        ),
        expect: () => [
          const TournamentCreateInProgress(),
          isA<TournamentCreateFailure>().having(
            (s) => s.userFriendlyMessage,
            'message',
            'Name is required',
          ),
        ],
      );
    });
  });
}
