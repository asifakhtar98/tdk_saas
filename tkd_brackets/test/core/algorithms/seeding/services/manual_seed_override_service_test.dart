import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/participant_placement.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraint_satisfying_seeding_engine.dart';
import 'package:tkd_brackets/core/algorithms/seeding/seeding_strategy.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockSeedingEngine extends Mock implements SeedingEngine {}

void main() {
  late ManualSeedOverrideService service;
  late MockSeedingEngine mockSeedingEngine;

  setUp(() {
    mockSeedingEngine = MockSeedingEngine();
    service = ManualSeedOverrideService(mockSeedingEngine);
  });

  group('ManualSeedOverrideService', () {
    final participants = [
      const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
      const SeedingParticipant(id: '2', dojangName: 'Dojang B'),
    ];

    const currentResult = SeedingResult(
      placements: [
        ParticipantPlacement(
          participantId: '1',
          seedPosition: 1,
          bracketSlot: 1,
        ),
        ParticipantPlacement(
          participantId: '2',
          seedPosition: 2,
          bracketSlot: 2,
        ),
      ],
      appliedConstraints: ['dojang'],
      randomSeed: 123,
      isFullySatisfied: true,
    );

    group('swapParticipants', () {
      test('swaps two participants exchange positions', () {
        final result = service.swapParticipants(
          currentResult: currentResult,
          participantIdA: '1',
          participantIdB: '2',
          participants: participants,
          constraints: [],
          bracketSize: 2,
        );

        final updated = result.getOrElse((_) => throw Exception('Failed'));

        final p1 = updated.placements.firstWhere((p) => p.participantId == '1');
        final p2 = updated.placements.firstWhere((p) => p.participantId == '2');

        expect(p1.seedPosition, 2);
        expect(p2.seedPosition, 1);
        expect(updated.isFullySatisfied, true);
      });

      test('invalid participantIdA returns ValidationFailure', () {
        final result = service.swapParticipants(
          currentResult: currentResult,
          participantIdA: 'NON-EXISTENT',
          participantIdB: '2',
          participants: participants,
          constraints: [],
          bracketSize: 2,
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should be failure'),
        );
      });

      test('same participant for both returns ValidationFailure', () {
        final result = service.swapParticipants(
          currentResult: currentResult,
          participantIdA: '1',
          participantIdB: '1',
          participants: participants,
          constraints: [],
          bracketSize: 2,
        );

        expect(result.isLeft(), true);
      });

      test('constraint violations produce warnings but not error', () {
        final participantsViolent = [
          const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
          const SeedingParticipant(id: '2', dojangName: 'Dojang A'),
          const SeedingParticipant(id: '3', dojangName: 'Dojang B'),
          const SeedingParticipant(id: '4', dojangName: 'Dojang C'),
        ];
        const currentRes = SeedingResult(
          placements: [
            ParticipantPlacement(
              participantId: '1',
              seedPosition: 1,
              bracketSlot: 1,
            ),
            ParticipantPlacement(
              participantId: '2',
              seedPosition: 3,
              bracketSlot: 3,
            ),
            ParticipantPlacement(
              participantId: '3',
              seedPosition: 2,
              bracketSlot: 2,
            ),
            ParticipantPlacement(
              participantId: '4',
              seedPosition: 4,
              bracketSlot: 4,
            ),
          ],
          appliedConstraints: [],
          randomSeed: 0,
        );
        // Swapping 2(A) with 3(B).
        // Initial: 1(A)@1, 2(A)@3, 3(B)@2, 4(C)@4
        // Result:  1(A)@1, 2(A)@2, 3(B)@3, 4(C)@4
        // 1(A) and 2(A) meet in Round 1 (slots 1 and 2).
        final res = service.swapParticipants(
          currentResult: currentRes,
          participantIdA: '2',
          participantIdB: '3',
          participants: participantsViolent,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
          bracketSize: 4,
        );

        final updated = res.getOrElse((_) => throw Exception());
        expect(updated.isFullySatisfied, false);
        expect(updated.constraintViolationCount, 1);
        expect(updated.warnings.isNotEmpty, true);
      });
    });

    group('pinParticipant', () {
      test('adds to pin map correctly', () {
        final currentPins = <String, int>{'Existing': 4};
        final result = service.pinParticipant(
          currentPins: currentPins,
          participantId: '1',
          seedPosition: 1,
          bracketSize: 4,
        );

        final updated = result.getOrElse((_) => throw Exception());
        expect(updated['Existing'], 4);
        expect(updated['1'], 1);
      });

      test('duplicate position returns ValidationFailure', () {
        final currentPins = <String, int>{'Existing': 1};
        final result = service.pinParticipant(
          currentPins: currentPins,
          participantId: '1',
          seedPosition: 1,
          bracketSize: 4,
        );

        expect(result.isLeft(), true);
      });

      test('empty participantId returns ValidationFailure', () {
        final result = service.pinParticipant(
          currentPins: {},
          participantId: '',
          seedPosition: 1,
          bracketSize: 4,
        );
        expect(result.isLeft(), true);
      });

      test('position < 1 returns ValidationFailure', () {
        final result = service.pinParticipant(
          currentPins: {},
          participantId: '1',
          seedPosition: 0,
          bracketSize: 4,
        );
        expect(result.isLeft(), true);
      });

      test('position > bracketSize returns ValidationFailure', () {
        final result = service.pinParticipant(
          currentPins: {},
          participantId: '1',
          seedPosition: 5,
          bracketSize: 4,
        );
        expect(result.isLeft(), true);
      });
    });

    group('reseedAroundPins', () {
      setUpAll(() {
        registerFallbackValue(SeedingStrategy.manual);
        registerFallbackValue(BracketFormat.singleElimination);
      });

      test('delegates to engine correctly', () {
        final params = ManualSeedOverrideParams(
          participants: participants,
          constraints: const [],
          pinnedSeeds: const {'1': 1},
        );

        when(
          () => mockSeedingEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: SeedingStrategy.manual,
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
            pinnedSeeds: any(named: 'pinnedSeeds'),
          ),
        ).thenReturn(const Right(currentResult));

        service.reseedAroundPins(params);

        verify(
          () => mockSeedingEngine.generateSeeding(
            participants: participants,
            strategy: SeedingStrategy.manual,
            constraints: [],
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: any(named: 'randomSeed'),
            pinnedSeeds: {'1': 1},
          ),
        ).called(1);
      });

      test('all pinned returns as-is without engine invocation', () {
        final params = ManualSeedOverrideParams(
          participants: participants,
          constraints: const [],
          pinnedSeeds: const {'1': 1, '2': 2},
        );

        final result = service.reseedAroundPins(params);

        verifyZeroInteractions(mockSeedingEngine);
        expect(result.isRight(), true);
        final val = result.getOrElse((l) => throw Exception());
        expect(val.placements.length, 2);
      });

      test('performance - 64 participants completes in < 100ms', () {
        final sixtyFourParticipants = List.generate(
          64,
          (i) => SeedingParticipant(id: '$i', dojangName: 'Dojang ${i % 8}'),
        );

        final pinnedSeeds = <String, int>{};
        for (var i = 0; i < 8; i++) {
          pinnedSeeds['$i'] = i + 1;
        }

        final params = ManualSeedOverrideParams(
          participants: sixtyFourParticipants,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 2)],
          pinnedSeeds: pinnedSeeds,
          randomSeed: 123,
        );

        final realEngine = ConstraintSatisfyingSeedingEngine();
        final realService = ManualSeedOverrideService(realEngine);

        final stopwatch = Stopwatch()..start();
        final result = realService.reseedAroundPins(params);
        stopwatch.stop();

        expect(result.isRight(), true);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('no pins equivalent to normal seeding', () {
        final params = ManualSeedOverrideParams(
          participants: participants,
          constraints: const [],
          pinnedSeeds: const {},
          randomSeed: 42,
        );

        when(
          () => mockSeedingEngine.generateSeeding(
            participants: any(named: 'participants'),
            strategy: SeedingStrategy.manual,
            constraints: any(named: 'constraints'),
            bracketFormat: any(named: 'bracketFormat'),
            randomSeed: any(named: 'randomSeed'),
            pinnedSeeds: any(named: 'pinnedSeeds'),
          ),
        ).thenReturn(const Right(currentResult));

        final result = service.reseedAroundPins(params);

        expect(result.isRight(), true);
        verify(
          () => mockSeedingEngine.generateSeeding(
            participants: participants,
            strategy: SeedingStrategy.manual,
            constraints: [],
            bracketFormat: BracketFormat.singleElimination,
            randomSeed: 42,
            pinnedSeeds: {},
          ),
        ).called(1);
      });

      test('constraint violations produce warnings not errors', () {
        // Use real engine to test actual behavior
        final realEngine = ConstraintSatisfyingSeedingEngine();
        final realService = ManualSeedOverrideService(realEngine);

        // 4 participants, pin same-dojang athletes adjacent (violates separation)
        final fourParticipants = [
          const SeedingParticipant(id: '1', dojangName: 'Dojang A'),
          const SeedingParticipant(id: '2', dojangName: 'Dojang A'),
          const SeedingParticipant(id: '3', dojangName: 'Dojang B'),
          const SeedingParticipant(id: '4', dojangName: 'Dojang B'),
        ];

        // Pin same-dojang athletes adjacent → forces violations
        final params = ManualSeedOverrideParams(
          participants: fourParticipants,
          constraints: [DojangSeparationConstraint(minimumRoundsSeparation: 1)],
          pinnedSeeds: const {'1': 1, '2': 2, '3': 3, '4': 4},
        );

        final result = realService.reseedAroundPins(params);

        // Should return Right (not Left) — violations are warnings, not errors
        expect(result.isRight(), true);
        final seeding = result.getOrElse((_) => throw Exception());
        expect(seeding.isFullySatisfied, false);
        expect(seeding.constraintViolationCount, greaterThan(0));
        expect(seeding.warnings, isNotEmpty);
      });
    });
  });
}
