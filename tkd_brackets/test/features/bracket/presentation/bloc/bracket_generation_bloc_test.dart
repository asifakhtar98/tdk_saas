import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/double_elimination_bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/regenerate_bracket_result.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_double_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_round_robin_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/generate_single_elimination_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_params.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_use_case.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_bloc.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_event.dart';
import 'package:tkd_brackets/features/bracket/presentation/bloc/bracket_generation_state.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/repositories/participant_repository.dart';

class MockDivisionRepository extends Mock implements DivisionRepository {}

class MockParticipantRepository extends Mock implements ParticipantRepository {}

class MockBracketRepository extends Mock implements BracketRepository {}

class MockGenerateSingleEliminationBracketUseCase extends Mock
    implements GenerateSingleEliminationBracketUseCase {}

class MockGenerateDoubleEliminationBracketUseCase extends Mock
    implements GenerateDoubleEliminationBracketUseCase {}

class MockGenerateRoundRobinBracketUseCase extends Mock
    implements GenerateRoundRobinBracketUseCase {}

class MockRegenerateBracketUseCase extends Mock
    implements RegenerateBracketUseCase {}

class FakeGenerateSingleEliminationBracketParams extends Fake
    implements GenerateSingleEliminationBracketParams {}

class FakeGenerateDoubleEliminationBracketParams extends Fake
    implements GenerateDoubleEliminationBracketParams {}

class FakeGenerateRoundRobinBracketParams extends Fake
    implements GenerateRoundRobinBracketParams {}

class FakeRegenerateBracketParams extends Fake
    implements RegenerateBracketParams {}

void main() {
  late MockDivisionRepository divisionRepository;
  late MockParticipantRepository participantRepository;
  late MockBracketRepository bracketRepository;
  late MockGenerateSingleEliminationBracketUseCase generateSingleUseCase;
  late MockGenerateDoubleEliminationBracketUseCase generateDoubleUseCase;
  late MockGenerateRoundRobinBracketUseCase generateRoundRobinUseCase;
  late MockRegenerateBracketUseCase regenerateUseCase;

  const divisionId = 'd1';
  final testDivision = DivisionEntity(
    id: divisionId,
    tournamentId: 't1',
    name: 'Test Division',
    category: DivisionCategory.sparring,
    gender: DivisionGender.male,
    bracketFormat: BracketFormat.singleElimination,
    status: DivisionStatus.setup,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
    weightMinKg: 30,
    weightMaxKg: 40,
  );

  final testParticipants = <ParticipantEntity>[
    ParticipantEntity(
      id: 'p1',
      divisionId: divisionId,
      firstName: 'John',
      lastName: 'Doe',
      createdAtTimestamp: DateTime(2026),
      updatedAtTimestamp: DateTime(2026),
      syncVersion: 1,
    ),
    ParticipantEntity(
      id: 'p2',
      divisionId: divisionId,
      firstName: 'Jane',
      lastName: 'Doe',
      createdAtTimestamp: DateTime(2026),
      updatedAtTimestamp: DateTime(2026),
      syncVersion: 1,
    ),
  ];

  final testBracket = BracketEntity(
    id: 'b1',
    divisionId: divisionId,
    bracketType: BracketType.winners,
    totalRounds: 2,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  final testMatch = MatchEntity(
    id: 'm1',
    bracketId: 'b1',
    roundNumber: 1,
    matchNumberInRound: 1,
    createdAtTimestamp: DateTime(2026),
    updatedAtTimestamp: DateTime(2026),
  );

  setUpAll(() {
    registerFallbackValue(FakeGenerateSingleEliminationBracketParams());
    registerFallbackValue(FakeGenerateDoubleEliminationBracketParams());
    registerFallbackValue(FakeGenerateRoundRobinBracketParams());
    registerFallbackValue(FakeRegenerateBracketParams());
  });

  setUp(() {
    divisionRepository = MockDivisionRepository();
    participantRepository = MockParticipantRepository();
    bracketRepository = MockBracketRepository();
    generateSingleUseCase = MockGenerateSingleEliminationBracketUseCase();
    generateDoubleUseCase = MockGenerateDoubleEliminationBracketUseCase();
    generateRoundRobinUseCase = MockGenerateRoundRobinBracketUseCase();
    regenerateUseCase = MockRegenerateBracketUseCase();
  });

  BracketGenerationBloc buildBloc() => BracketGenerationBloc(
        divisionRepository,
        participantRepository,
        bracketRepository,
        generateSingleUseCase,
        generateDoubleUseCase,
        generateRoundRobinUseCase,
        regenerateUseCase,
      );

  group('BracketGenerationBloc', () {
    test('initial state is BracketGenerationInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const BracketGenerationInitial());
      bloc.close();
    });

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'emits [LoadInProgress, LoadSuccess] when data loading succeeds',
      setUp: () {
        when(() => divisionRepository.getDivisionById(divisionId))
            .thenAnswer((_) async => Right(testDivision));
        when(() => participantRepository.getParticipantsForDivision(divisionId))
            .thenAnswer((_) async => Right(testParticipants));
        when(() => bracketRepository.getBracketsForDivision(divisionId))
            .thenAnswer((_) async => const Right(<BracketEntity>[]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketGenerationLoadRequested(divisionId: divisionId)),
      expect: () => [
        const BracketGenerationLoadInProgress(),
        BracketGenerationLoadSuccess(
          division: testDivision,
          participants: testParticipants,
          existingBrackets: const [],
        ),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'emits [LoadInProgress, LoadFailure] when division loading fails',
      setUp: () {
        when(() => divisionRepository.getDivisionById(divisionId))
            .thenAnswer((_) async => const Left(ServerResponseFailure(userFriendlyMessage: 'Div Error')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketGenerationLoadRequested(divisionId: divisionId)),
      expect: () => [
        const BracketGenerationLoadInProgress(),
        const BracketGenerationLoadFailure(userFriendlyMessage: 'Div Error'),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'formatSelected updates state with selected format',
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision,
        participants: testParticipants,
        existingBrackets: const [],
      ),
      act: (bloc) => bloc.add(const BracketGenerationFormatSelected(BracketFormat.doubleElimination)),
      expect: () => [
        BracketGenerationLoadSuccess(
          division: testDivision,
          participants: testParticipants,
          existingBrackets: const [],
          selectedFormat: BracketFormat.doubleElimination,
        ),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'generateRequested emits [InProgress, Success] for Single Elimination',
      setUp: () {
        when(() => generateSingleUseCase(any())).thenAnswer(
          (_) async => Right(BracketGenerationResult(bracket: testBracket, matches: const [])),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision.copyWith(bracketFormat: BracketFormat.singleElimination),
        participants: testParticipants,
        existingBrackets: const [],
      ),
      act: (bloc) => bloc.add(const BracketGenerationGenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        BracketGenerationSuccess(generatedBracketId: testBracket.id),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'generateRequested emits [InProgress, Success] for Double Elimination',
      setUp: () {
        when(() => generateDoubleUseCase(any())).thenAnswer(
          (_) async => Right(DoubleEliminationBracketGenerationResult(
            winnersBracket: testBracket,
            losersBracket: testBracket.copyWith(id: 'b2', bracketType: BracketType.losers),
            grandFinalsMatch: testMatch,
            allMatches: [testMatch],
          )),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision.copyWith(bracketFormat: BracketFormat.doubleElimination),
        participants: testParticipants,
        existingBrackets: const [],
      ),
      act: (bloc) => bloc.add(const BracketGenerationGenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        BracketGenerationSuccess(generatedBracketId: testBracket.id),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'regenerateRequested calls RegenerateBracketUseCase and emits success',
      setUp: () {
        when(() => regenerateUseCase(any())).thenAnswer(
          (_) async => Right(RegenerateBracketResult(
            deletedBracketCount: 1,
            deletedMatchCount: 10,
            generationResult: BracketGenerationResult(bracket: testBracket, matches: const []),
          )),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision,
        participants: testParticipants,
        existingBrackets: [testBracket],
      ),
      act: (bloc) => bloc.add(const BracketGenerationRegenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        BracketGenerationSuccess(generatedBracketId: testBracket.id),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'emits [LoadInProgress, LoadFailure] when participant loading fails',
      setUp: () {
        when(() => divisionRepository.getDivisionById(divisionId))
            .thenAnswer((_) async => Right(testDivision));
        when(() => participantRepository.getParticipantsForDivision(divisionId))
            .thenAnswer((_) async => const Left(
                ServerResponseFailure(userFriendlyMessage: 'Participant Error')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const BracketGenerationLoadRequested(divisionId: divisionId)),
      expect: () => [
        const BracketGenerationLoadInProgress(),
        const BracketGenerationLoadFailure(userFriendlyMessage: 'Participant Error'),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'generateRequested emits [InProgress, LoadFailure] when generation fails',
      setUp: () {
        when(() => generateSingleUseCase(any())).thenAnswer(
          (_) async => const Left(
              ServerResponseFailure(userFriendlyMessage: 'Gen Error')),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision.copyWith(bracketFormat: BracketFormat.singleElimination),
        participants: testParticipants,
        existingBrackets: const [],
      ),
      act: (bloc) => bloc.add(const BracketGenerationGenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        const BracketGenerationLoadFailure(userFriendlyMessage: 'Gen Error'),
      ],
    );

    blocTest<BracketGenerationBloc, BracketGenerationState>(
      'regenerateRequested emits [InProgress, LoadFailure] when regeneration fails',
      setUp: () {
        when(() => regenerateUseCase(any())).thenAnswer(
          (_) async => const Left(
              ServerResponseFailure(userFriendlyMessage: 'Regen Error')),
        );
      },
      build: buildBloc,
      seed: () => BracketGenerationLoadSuccess(
        division: testDivision,
        participants: testParticipants,
        existingBrackets: [testBracket],
      ),
      act: (bloc) => bloc.add(const BracketGenerationRegenerateRequested()),
      expect: () => [
        const BracketGenerationInProgress(),
        const BracketGenerationLoadFailure(userFriendlyMessage: 'Regen Error'),
      ],
    );
  });
}
