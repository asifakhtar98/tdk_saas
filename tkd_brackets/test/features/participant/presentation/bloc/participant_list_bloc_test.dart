import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/delete_participant_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/division_participant_view.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/get_division_participants_usecase.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/transfer_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/usecases.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_bloc.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_event.dart';
import 'package:tkd_brackets/features/participant/presentation/bloc/participant_list_state.dart';

class MockGetDivisionParticipantsUseCase extends Mock
    implements GetDivisionParticipantsUseCase {}

class MockCreateParticipantUseCase extends Mock
    implements CreateParticipantUseCase {}

class MockUpdateParticipantUseCase extends Mock
    implements UpdateParticipantUseCase {}

class MockTransferParticipantUseCase extends Mock
    implements TransferParticipantUseCase {}

class MockUpdateParticipantStatusUseCase extends Mock
    implements UpdateParticipantStatusUseCase {}

class MockDeleteParticipantUseCase extends Mock
    implements DeleteParticipantUseCase {}

class FakeCreateParticipantParams extends Fake
    implements CreateParticipantParams {}

class FakeUpdateParticipantParams extends Fake
    implements UpdateParticipantParams {}

class FakeTransferParticipantParams extends Fake
    implements TransferParticipantParams {}

void main() {
  late MockGetDivisionParticipantsUseCase mockGetParticipants;
  late MockCreateParticipantUseCase mockCreate;
  late MockUpdateParticipantUseCase mockUpdate;
  late MockTransferParticipantUseCase mockTransfer;
  late MockUpdateParticipantStatusUseCase mockUpdateStatus;
  late MockDeleteParticipantUseCase mockDelete;

  late DivisionEntity tDivision;
  late ParticipantEntity tParticipant;
  late DivisionParticipantView tView;

  setUpAll(() {
    registerFallbackValue(FakeCreateParticipantParams());
    registerFallbackValue(FakeUpdateParticipantParams());
    registerFallbackValue(FakeTransferParticipantParams());
    
    // Register named argument fallbacks for mocktail
    registerFallbackValue(ParticipantStatus.pending);
  });

  setUp(() {
    mockGetParticipants = MockGetDivisionParticipantsUseCase();
    mockCreate = MockCreateParticipantUseCase();
    mockUpdate = MockUpdateParticipantUseCase();
    mockTransfer = MockTransferParticipantUseCase();
    mockUpdateStatus = MockUpdateParticipantStatusUseCase();
    mockDelete = MockDeleteParticipantUseCase();

    tDivision = DivisionEntity(
      id: 'div-123',
      tournamentId: 'tour-123',
      name: 'Junior Boys -45kg',
      category: DivisionCategory.sparring,
      gender: DivisionGender.male,
      bracketFormat: BracketFormat.singleElimination,
      status: DivisionStatus.setup,
      createdAtTimestamp: DateTime(2026),
      updatedAtTimestamp: DateTime(2026),
    );

    tParticipant = ParticipantEntity(
      id: 'part-123',
      divisionId: 'div-123',
      firstName: 'John',
      lastName: 'Doe',
      schoolOrDojangName: 'TDK Academy',
      beltRank: 'red',
      createdAtTimestamp: DateTime(2026),
      updatedAtTimestamp: DateTime(2026),
    );

    tView = DivisionParticipantView(
      division: tDivision,
      participants: [tParticipant],
      participantCount: 1,
    );
  });

  ParticipantListBloc buildBloc() {
    return ParticipantListBloc(
      mockGetParticipants,
      mockCreate,
      mockUpdate,
      mockTransfer,
      mockUpdateStatus,
      mockDelete,
    );
  }

  group('ParticipantListBloc', () {
    test('initial state is ParticipantListInitial', () {
      expect(buildBloc().state, const ParticipantListInitial());
    });

    group('LoadRequested', () {
      blocTest<ParticipantListBloc, ParticipantListState>(
        'emits [loadInProgress, loadSuccess] when loaded successfully',
        build: () {
          when(() => mockGetParticipants(any())).thenAnswer(
            (_) async => Right(tView),
          );
          return buildBloc();
        },
        act: (bloc) =>
            bloc.add(const ParticipantListLoadRequested(divisionId: 'div-123')),
        expect: () => [
          const ParticipantListLoadInProgress(),
          ParticipantListLoadSuccess(
            view: tView,
            searchQuery: '',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: [tParticipant],
          ),
        ],
      );
    });

    group('Search', () {
      blocTest<ParticipantListBloc, ParticipantListState>(
        'filters participants based on search query',
        seed: () => ParticipantListLoadSuccess(
          view: tView,
          searchQuery: '',
          currentFilter: ParticipantFilter.all,
          currentSort: ParticipantSort.nameAsc,
          filteredParticipants: [tParticipant],
        ),
        build: () => buildBloc(),
        act: (bloc) =>
            bloc.add(const ParticipantListSearchQueryChanged('NonExistent')),
        expect: () => [
          ParticipantListLoadSuccess(
            view: tView,
            searchQuery: 'NonExistent',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: const [],
          ),
        ],
      );
    });

    group('StatusChange', () {
      blocTest<ParticipantListBloc, ParticipantListState>(
        'emits inProgress then success when status update succeeds',
        seed: () => ParticipantListLoadSuccess(
          view: tView,
          searchQuery: '',
          currentFilter: ParticipantFilter.all,
          currentSort: ParticipantSort.nameAsc,
          filteredParticipants: [tParticipant],
        ),
        build: () {
          when(() => mockUpdateStatus(
                participantId: any(named: 'participantId'),
                newStatus: any(named: 'newStatus'),
                dqReason: any(named: 'dqReason'),
              )).thenAnswer((_) async => Right(tParticipant));
          when(() => mockGetParticipants(any())).thenAnswer(
            (_) async => Right(tView),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const ParticipantListStatusChangeRequested(
          participantId: 'part-123',
          newStatus: ParticipantStatus.checkedIn,
        )),
        expect: () => [
          ParticipantListLoadSuccess(
            view: tView,
            searchQuery: '',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: [tParticipant],
            actionStatus: ActionStatus.inProgress,
          ),
          ParticipantListLoadSuccess(
            view: tView,
            searchQuery: '',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: [tParticipant],
            actionStatus: ActionStatus.success,
            actionMessage: 'Status updated',
          ),
        ],
        verify: (_) {
          verify(() => mockUpdateStatus(
                participantId: 'part-123',
                newStatus: ParticipantStatus.checkedIn,
              )).called(1);
        },
      );
    });

    group('RemoveRequested', () {
      blocTest<ParticipantListBloc, ParticipantListState>(
        'calls deleteParticipant and refreshes list',
        seed: () => ParticipantListLoadSuccess(
          view: tView,
          searchQuery: '',
          currentFilter: ParticipantFilter.all,
          currentSort: ParticipantSort.nameAsc,
          filteredParticipants: [tParticipant],
        ),
        build: () {
          when(() => mockDelete(any())).thenAnswer((_) async => const Right(unit));
          when(() => mockGetParticipants(any())).thenAnswer(
            (_) async => Right(tView),
          );
          return buildBloc();
        },
        act: (bloc) => bloc.add(const ParticipantListRemoveRequested(
          participantId: 'part-123',
        )),
        expect: () => [
          ParticipantListLoadSuccess(
            view: tView,
            searchQuery: '',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: [tParticipant],
            actionStatus: ActionStatus.inProgress,
          ),
          ParticipantListLoadSuccess(
            view: tView,
            searchQuery: '',
            currentFilter: ParticipantFilter.all,
            currentSort: ParticipantSort.nameAsc,
            filteredParticipants: [tParticipant],
            actionStatus: ActionStatus.success,
            actionMessage: 'Participant removed',
          ),
        ],
        verify: (_) {
          verify(() => mockDelete('part-123')).called(1);
        },
      );
    });
  });
}
