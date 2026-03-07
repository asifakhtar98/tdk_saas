import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/features/bracket/data/services/hybrid_bracket_generator_service_implementation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/services/round_robin_bracket_generator_service.dart';
import 'package:tkd_brackets/features/bracket/domain/services/single_elimination_bracket_generator_service.dart';

class MockRoundRobinGeneratorService extends Mock
    implements RoundRobinBracketGeneratorService {}

class MockSingleEliminationGeneratorService extends Mock
    implements SingleEliminationBracketGeneratorService {}

void main() {
  late HybridBracketGeneratorServiceImplementation service;
  late MockRoundRobinGeneratorService mockRRGenerator;
  late MockSingleEliminationGeneratorService mockSEGenerator;

  setUp(() {
    mockRRGenerator = MockRoundRobinGeneratorService();
    mockSEGenerator = MockSingleEliminationGeneratorService();
    service = HybridBracketGeneratorServiceImplementation(
      mockRRGenerator,
      mockSEGenerator,
    );
  });

  const divisionId = 'div-1';

  BracketGenerationResult makePoolResult(String bracketId, String poolId) {
    final now = DateTime.now();
    return BracketGenerationResult(
      bracket: BracketEntity(
        id: bracketId,
        divisionId: divisionId,
        bracketType: BracketType.pool,
        totalRounds: 1,
        poolIdentifier: poolId,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      ),
      matches: [
        MatchEntity(
          id: 'm-$bracketId',
          bracketId: bracketId,
          roundNumber: 1,
          matchNumberInRound: 1,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        ),
      ],
    );
  }

  void stubGenerators() {
    when(() => mockRRGenerator.generate(
          divisionId: any(named: 'divisionId'),
          participantIds: any(named: 'participantIds'),
          bracketId: any(named: 'bracketId'),
          poolIdentifier: any(named: 'poolIdentifier'),
        )).thenAnswer((invocation) {
      final poolId = invocation.namedArguments[#poolIdentifier] as String;
      final bracketId = invocation.namedArguments[#bracketId] as String;
      return makePoolResult(bracketId, poolId);
    });

    when(() => mockSEGenerator.generate(
          divisionId: any(named: 'divisionId'),
          participantIds: any(named: 'participantIds'),
          bracketId: any(named: 'bracketId'),
        )).thenAnswer((invocation) {
      final bracketId = invocation.namedArguments[#bracketId] as String;
      return makePoolResult(bracketId, '');
    });
  }

  test('6 participants, 2 pools: splits [p1,p3,p5] and [p2,p4,p6]', () {
    stubGenerators();

    final result = service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
    );

    expect(result.poolBrackets.length, 2);
    expect(result.eliminationBracket.bracket.id, 'elim');
    expect(result.allMatches.length, 3); // 1 per pool + 1 elimination

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p1', 'p3', 'p5'],
          bracketId: 'pool-a',
          poolIdentifier: 'A',
        )).called(1);

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p2', 'p4', 'p6'],
          bracketId: 'pool-b',
          poolIdentifier: 'B',
        )).called(1);
  });

  test('4 participants, 2 pools: splits [p1,p3] and [p2,p4]', () {
    stubGenerators();

    service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
    );

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p1', 'p3'],
          bracketId: 'pool-a',
          poolIdentifier: 'A',
        )).called(1);

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p2', 'p4'],
          bracketId: 'pool-b',
          poolIdentifier: 'B',
        )).called(1);
  });

  test('8 participants, 2 pools: splits into pools of 4 each', () {
    stubGenerators();

    service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
    );

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p1', 'p3', 'p5', 'p7'],
          bracketId: 'pool-a',
          poolIdentifier: 'A',
        )).called(1);

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p2', 'p4', 'p6', 'p8'],
          bracketId: 'pool-b',
          poolIdentifier: 'B',
        )).called(1);
  });

  test('10 participants, 2 pools: splits into pools of 5 each', () {
    stubGenerators();

    service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9', 'p10'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
    );

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p1', 'p3', 'p5', 'p7', 'p9'],
          bracketId: 'pool-a',
          poolIdentifier: 'A',
        )).called(1);

    verify(() => mockRRGenerator.generate(
          divisionId: divisionId,
          participantIds: ['p2', 'p4', 'p6', 'p8', 'p10'],
          bracketId: 'pool-b',
          poolIdentifier: 'B',
        )).called(1);
  });

  test('cross-seeding: 2 pools, 2 qualifiers → A#1 vs B#2, A#2 vs B#1', () {
    stubGenerators();

    service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
    );

    verify(() => mockSEGenerator.generate(
          divisionId: divisionId,
          participantIds: ['pool_a_q1', 'pool_b_q2', 'pool_a_q2', 'pool_b_q1'],
          bracketId: 'elim',
        )).called(1);
  });

  test('configurable qualifiers: 3 per pool → 6 total qualifiers', () {
    stubGenerators();

    service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
      qualifiersPerPool: 3,
    );

    verify(() => mockSEGenerator.generate(
          divisionId: divisionId,
          participantIds: [
            'pool_a_q1', 'pool_b_q3',
            'pool_a_q2', 'pool_b_q2',
            'pool_a_q3', 'pool_b_q1',
          ],
          bracketId: 'elim',
        )).called(1);
  });

  test('stores hybrid config in elimination bracket bracketDataJson', () {
    stubGenerators();

    final result = service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
      numberOfPools: 2,
      qualifiersPerPool: 2,
    );

    final elimBracket = result.eliminationBracket.bracket;
    expect(elimBracket.bracketDataJson, isNotNull);
    expect(elimBracket.bracketDataJson!['hybrid'], true);
    expect(elimBracket.bracketDataJson!['numberOfPools'], 2);
    expect(elimBracket.bracketDataJson!['qualifiersPerPool'], 2);
    expect(elimBracket.bracketDataJson!['poolBracketIds'], ['pool-a', 'pool-b']);
  });

  test('pool bracket IDs are passed through correctly', () {
    stubGenerators();

    final result = service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4'],
      eliminationBracketId: 'elim-id',
      poolBracketIds: ['custom-pool-a', 'custom-pool-b'],
    );

    expect(result.poolBrackets[0].bracket.id, 'custom-pool-a');
    expect(result.poolBrackets[1].bracket.id, 'custom-pool-b');
    expect(result.eliminationBracket.bracket.id, 'elim-id');
  });

  test('result structure: poolBrackets.length == numberOfPools', () {
    stubGenerators();

    final result = service.generate(
      divisionId: divisionId,
      participantIds: const ['p1', 'p2', 'p3', 'p4'],
      eliminationBracketId: 'elim',
      poolBracketIds: ['pool-a', 'pool-b'],
      numberOfPools: 2,
    );

    expect(result.poolBrackets.length, 2);
    expect(result.eliminationBracket, isNotNull);
  });
}
