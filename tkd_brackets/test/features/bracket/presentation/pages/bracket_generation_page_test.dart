import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_bloc.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_state.dart';
import 'package:tkd_brackets/features/bracket/presentation/pages/bracket_generation_page.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

class MockBracketGenerationBloc
    extends MockBloc<BracketGenerationEvent, BracketGenerationState>
    implements BracketGenerationBloc {}

void main() {
  late MockBracketGenerationBloc mockBloc;
  final getIt = GetIt.instance;

  const divisionId = 'd1';
  const tournamentId = 't1';

  final testDivision = DivisionEntity(
    id: divisionId,
    tournamentId: tournamentId,
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  setUpAll(() {
    getIt.registerFactory<BracketGenerationBloc>(() => mockBloc);
  });

  setUp(() {
    mockBloc = MockBracketGenerationBloc();
  });

  Widget createWidget() {
    return MaterialApp(
      home: BracketGenerationPage(
        tournamentId: tournamentId,
        divisionId: divisionId,
      ),
    );
  }

  testWidgets('renders loading indicator when state is loadInProgress',
      (tester) async {
    when(() => mockBloc.state)
        .thenReturn(const BracketGenerationState.loadInProgress());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders participant count when state is loadSuccess',
      (tester) async {
    when(() => mockBloc.state).thenReturn(BracketGenerationState.loadSuccess(
      division: testDivision,
      participants: [
        ParticipantEntity(
          id: 'p1',
          divisionId: divisionId,
          firstName: 'John',
          lastName: 'Doe',
          createdAtTimestamp: DateTime(2026),
          updatedAtTimestamp: DateTime(2026),
        ),
      ],
      existingBrackets: const [],
    ));
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidget());

    expect(find.text('1 participants available'), findsOneWidget);
    expect(find.text('Generate Bracket'), findsOneWidget);
  });

  testWidgets('renders error message when state is loadFailure', (tester) async {
    when(() => mockBloc.state).thenReturn(const BracketGenerationState.loadFailure(
      userFriendlyMessage: 'Error loading data',
    ));
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidget());

    expect(find.text('Error loading data'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders bracket list when existing brackets present',
      (tester) async {
    final testBracket = BracketEntity(
      id: 'b1',
      divisionId: divisionId,
      bracketType: BracketType.winners,
      totalRounds: 2,
      createdAtTimestamp: DateTime(2026),
      updatedAtTimestamp: DateTime(2026),
    );
    when(() => mockBloc.state).thenReturn(BracketGenerationState.loadSuccess(
      division: testDivision,
      participants: const [],
      existingBrackets: [testBracket],
    ));
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidget());

    expect(find.text('Winners Bracket'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
