import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/seeding_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_entry.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/ranked_seeding_import_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/ranked_seeding_import_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/ranked_seeding_import_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockSeedingEngine extends Mock implements SeedingEngine {}

void main() {
  late MockSeedingEngine mockEngine;
  late RankedSeedingImportUseCase useCase;

  setUpAll(() {
    registerFallbackValue(BracketFormat.singleElimination);
    registerFallbackValue(SeedingStrategy.ranked);
    registerFallbackValue(<SeedingConstraint>[]);
    registerFallbackValue(<String, int>{});
  });

  setUp(() {
    mockEngine = MockSeedingEngine();
    useCase = RankedSeedingImportUseCase(mockEngine);
  });

  final tParticipants = [
    const SeedingParticipant(id: 'p1', dojangName: 'Tiger TKD'),
    const SeedingParticipant(id: 'p2', dojangName: 'Dragon MA'),
    const SeedingParticipant(id: 'p3', dojangName: 'Eagle Gym'),
  ];

  final tParticipantNames = {
    'p1': 'John Smith',
    'p2': 'Jane Doe',
    'p3': 'Alex Kim',
  };

  final tRankedEntries = [
    const RankedSeedingEntry(name: 'John Smith', rank: 1),
    const RankedSeedingEntry(name: 'Alex Kim', rank: 2),
  ];

  final tParams = RankedSeedingImportParams(
    divisionId: 'div1',
    participants: tParticipants,
    rankedEntries: tRankedEntries,
    participantNames: tParticipantNames,
  );

  const tSeedingResult = SeedingResult(
    placements: [],
    appliedConstraints: [],
    randomSeed: 0,
  );

  void setupMockEngine() {
    when(() => mockEngine.generateSeeding(
          participants: any(named: 'participants'),
          strategy: any(named: 'strategy'),
          constraints: any(named: 'constraints'),
          bracketFormat: any(named: 'bracketFormat'),
          randomSeed: any(named: 'randomSeed'),
          pinnedSeeds: any(named: 'pinnedSeeds'),
        )).thenReturn(const Right(tSeedingResult));
  }

  group('RankedSeedingImportUseCase - Validation', () {
    test('should return ValidationFailure when divisionId is empty', () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: '',
        participants: tParticipants,
        rankedEntries: tRankedEntries,
        participantNames: tParticipantNames,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when less than 2 participants',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: [tParticipants.first],
        rankedEntries: tRankedEntries,
        participantNames: tParticipantNames,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when participant ID is empty',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: [
          const SeedingParticipant(id: '', dojangName: 'Tiger TKD'),
          const SeedingParticipant(id: 'p2', dojangName: 'Dragon MA'),
        ],
        rankedEntries: tRankedEntries,
        participantNames: {'': 'No Name', 'p2': 'Jane Doe'},
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when duplicate participant IDs',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: [
          const SeedingParticipant(id: 'p1', dojangName: 'Tiger TKD'),
          const SeedingParticipant(id: 'p1', dojangName: 'Dragon MA'),
        ],
        rankedEntries: tRankedEntries,
        participantNames: {'p1': 'John Smith'},
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when rankedEntries is empty',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: const [],
        participantNames: tParticipantNames,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when rank is <= 0', () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(name: 'John Smith', rank: 0),
        ],
        participantNames: tParticipantNames,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when duplicate ranks', () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(name: 'John Smith', rank: 1),
          const RankedSeedingEntry(name: 'Alex Kim', rank: 1),
        ],
        participantNames: tParticipantNames,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when entry name is empty', () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(name: '  ', rank: 1),
        ],
        participantNames: tParticipantNames,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when matchThreshold > 1.0',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: tRankedEntries,
        participantNames: tParticipantNames,
        matchThreshold: 1.5,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when matchThreshold < 0.0',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: tRankedEntries,
        participantNames: tParticipantNames,
        matchThreshold: -0.1,
      ));
      expect(result.isLeft(), isTrue);
    });

    test('should return ValidationFailure when participantNames is incomplete',
        () async {
      final result = await useCase(RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: tRankedEntries,
        participantNames: {'p1': 'John'}, // Missing p2, p3
      ));
      expect(result.isLeft(), isTrue);
    });
  });

  group('RankedSeedingImportUseCase - Fuzzy Matching', () {
    test('should match exact names with confidence 1.0', () async {
      setupMockEngine();
      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);
      final matchResult =
          (result as Right<Failure, RankedSeedingImportResult>)
              .value
              .matchResult;
      expect(matchResult.matchedParticipants['p1'], 1);
      expect(matchResult.matchConfidences['p1'], 1.0);
      expect(matchResult.matchedParticipants['p3'], 2);
      expect(matchResult.matchConfidences['p3'], 1.0);
    });

    test('should match close names above threshold', () async {
      setupMockEngine();
      final fuzzyParams = RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(
              name: 'Jon Smith', rank: 1), // Fuzzy match for John Smith
        ],
        participantNames: tParticipantNames,
      );

      final result = await useCase(fuzzyParams);

      expect(result.isRight(), isTrue);
      final matchResult =
          (result as Right<Failure, RankedSeedingImportResult>)
              .value
              .matchResult;
      expect(matchResult.matchedParticipants.containsKey('p1'), isTrue);
      expect(matchResult.matchedParticipants['p1'], 1);
      expect(matchResult.matchConfidences['p1']!, greaterThanOrEqualTo(0.8));
    });

    test(
        'should reject names below threshold and add to unmatchedEntries',
        () async {
      setupMockEngine();
      final belowThresholdParams = RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(
              name: 'ZZZZZZZZZ', rank: 1), // No match
        ],
        participantNames: tParticipantNames,
      );

      final result = await useCase(belowThresholdParams);

      expect(result.isRight(), isTrue);
      final matchResult =
          (result as Right<Failure, RankedSeedingImportResult>)
              .value
              .matchResult;
      expect(matchResult.unmatchedEntries.length, 1);
      expect(matchResult.unmatchedEntries.first.name, 'ZZZZZZZZZ');
      expect(matchResult.unmatchedParticipants.length, 3);
    });

    test('should use club disambiguation to match correct participant',
        () async {
      setupMockEngine();
      final sameNameParticipants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger TKD'),
        const SeedingParticipant(id: 'p2', dojangName: 'Dragon MA'),
      ];
      final sameNameMap = {
        'p1': 'John Smith',
        'p2': 'John Smith',
      };

      final clubParams = RankedSeedingImportParams(
        divisionId: 'div1',
        participants: sameNameParticipants,
        rankedEntries: [
          const RankedSeedingEntry(
              name: 'John Smith', rank: 1, club: 'Dragon MA'),
        ],
        participantNames: sameNameMap,
      );

      final result = await useCase(clubParams);

      final matchResult =
          (result as Right<Failure, RankedSeedingImportResult>)
              .value
              .matchResult;
      expect(matchResult.matchedParticipants.containsKey('p2'),
          isTrue); // Dragon MA
      expect(matchResult.matchedParticipants.containsKey('p1'),
          isFalse); // Tiger TKD - no match
      expect(matchResult.unmatchedParticipants.length, 1);
      expect(matchResult.unmatchedParticipants.first.id, 'p1');
    });

    test(
        'should match first best-scoring participant when entry has no club',
        () async {
      setupMockEngine();
      final sameNameParticipants = [
        const SeedingParticipant(id: 'p1', dojangName: 'Tiger TKD'),
        const SeedingParticipant(id: 'p2', dojangName: 'Dragon MA'),
      ];
      final sameNameMap = {
        'p1': 'John Smith',
        'p2': 'John Smith',
      };

      final noClubParams = RankedSeedingImportParams(
        divisionId: 'div1',
        participants: sameNameParticipants,
        rankedEntries: [
          const RankedSeedingEntry(
              name: 'John Smith', rank: 1), // No club → first match wins
        ],
        participantNames: sameNameMap,
      );

      final result = await useCase(noClubParams);

      final matchResult =
          (result as Right<Failure, RankedSeedingImportResult>)
              .value
              .matchResult;
      // Should match p1 (first in list with same score)
      expect(matchResult.matchedParticipants.containsKey('p1'), isTrue);
    });
  });

  group('RankedSeedingImportUseCase - Seed Assignment', () {
    test('should call engine with correct pinnedSeeds and return success',
        () async {
      setupMockEngine();
      final result = await useCase(tParams);

      expect(result.isRight(), isTrue);

      final rightResult =
          result as Right<Failure, RankedSeedingImportResult>;
      expect(rightResult.value.seedingResult, tSeedingResult);
      expect(rightResult.value.matchResult.matchedParticipants, {
        'p1': 1,
        'p3': 2,
      });

      verify(() => mockEngine.generateSeeding(
            participants: tParticipants,
            strategy: SeedingStrategy.ranked,
            constraints: const [],
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: 0,
            pinnedSeeds: const {
              'p1': 1, // Matched rank 1
              'p3': 2, // Matched rank 2
              'p2': 3, // Unmatched - appended at end
            },
          )).called(1);
    });

    test(
        'should normalize rank gaps (1, 3, 7 → seeds 1, 2, 3)',
        () async {
      setupMockEngine();
      final gapParams = RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(name: 'John Smith', rank: 1),
          const RankedSeedingEntry(name: 'Jane Doe', rank: 3),
          const RankedSeedingEntry(name: 'Alex Kim', rank: 7),
        ],
        participantNames: tParticipantNames,
      );

      final result = await useCase(gapParams);

      expect(result.isRight(), isTrue);
      verify(() => mockEngine.generateSeeding(
            participants: tParticipants,
            strategy: SeedingStrategy.ranked,
            constraints: const [],
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: 0,
            pinnedSeeds: const {
              'p1': 1, // rank 1 → seed 1
              'p2': 2, // rank 3 → seed 2 (normalized)
              'p3': 3, // rank 7 → seed 3 (normalized)
            },
          )).called(1);
    });

    test(
        'should give unmatched participants trailing seed positions',
        () async {
      setupMockEngine();
      // Only rank one participant — others unmatched
      final oneMatchParams = RankedSeedingImportParams(
        divisionId: 'div1',
        participants: tParticipants,
        rankedEntries: [
          const RankedSeedingEntry(name: 'John Smith', rank: 1),
        ],
        participantNames: tParticipantNames,
      );

      final result = await useCase(oneMatchParams);

      expect(result.isRight(), isTrue);
      final matchResult =
          (result as Right<Failure, RankedSeedingImportResult>)
              .value
              .matchResult;
      expect(matchResult.unmatchedParticipants.length, 2);

      verify(() => mockEngine.generateSeeding(
            participants: tParticipants,
            strategy: SeedingStrategy.ranked,
            constraints: const [],
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: 0,
            pinnedSeeds: const {
              'p1': 1, // matched
              'p2': 2, // unmatched (trailing)
              'p3': 3, // unmatched (trailing)
            },
          )).called(1);
    });
  });

  group('RankedSeedingImportUseCase - Engine Delegation', () {
    test('should propagate engine failure', () async {
      when(() => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
            pinnedSeeds: any(named: 'pinnedSeeds'),
          )).thenReturn(const Left(
        ValidationFailure(userFriendlyMessage: 'Engine error'),
      ));

      final result = await useCase(tParams);

      expect(result.isLeft(), isTrue);
    });

    test('should call engine with SeedingStrategy.ranked', () async {
      setupMockEngine();
      await useCase(tParams);

      verify(() => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: SeedingStrategy.ranked,
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
            pinnedSeeds: any(named: 'pinnedSeeds'),
          )).called(1);
    });

    test('should call engine with randomSeed 0 and empty constraints',
        () async {
      setupMockEngine();
      await useCase(tParams);

      verify(() => mockEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: any(named: 'strategy'),
            constraints: const <SeedingConstraint>[],
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: 0,
            pinnedSeeds: any(named: 'pinnedSeeds'),
          )).called(1);
    });
  });
}
