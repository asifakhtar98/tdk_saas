import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tkd_brackets/core/algorithms/seeding/constraints/dojang_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/constraints/regional_separation_constraint.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/manual_seed_override_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_manual_seed_override_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_manual_seed_override_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockManualSeedOverrideService extends Mock implements ManualSeedOverrideService {}

void main() {
  late ApplyManualSeedOverrideUseCase useCase;
  late MockManualSeedOverrideService mockService;

  setUp(() {
    mockService = MockManualSeedOverrideService();
    useCase = ApplyManualSeedOverrideUseCase(mockService);
  });

  group('ApplyManualSeedOverrideUseCase', () {
    final participants = [
      const SeedingParticipant(id: '1', dojangName: 'A'),
      const SeedingParticipant(id: '2', dojangName: 'B'),
    ];

    group('validation', () {
      test('empty divisionId returns ValidationFailure', () async {
        final result = await useCase(ApplyManualSeedOverrideParams(
          divisionId: '',
          participants: participants,
        ));
        
        expect(result.isLeft(), true);
      });

      test('< 2 participants returns ValidationFailure', () async {
        final result = await useCase(const ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: [SeedingParticipant(id: '1', dojangName: 'A')],
        ));
        
        expect(result.isLeft(), true);
      });

      test('empty participantId returns ValidationFailure', () async {
        final result = await useCase(const ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: [
            SeedingParticipant(id: '', dojangName: 'A'),
            SeedingParticipant(id: '2', dojangName: 'B'),
          ],
        ));
        
        expect(result.isLeft(), true);
      });

      test('empty dojangName returns ValidationFailure', () async {
        final result = await useCase(const ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: [
            SeedingParticipant(id: '1', dojangName: ''),
            SeedingParticipant(id: '2', dojangName: 'B'),
          ],
        ));
        
        expect(result.isLeft(), true);
      });

      test('duplicate IDs returns ValidationFailure', () async {
        final result = await useCase(const ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: [
            SeedingParticipant(id: '1', dojangName: 'A'),
            SeedingParticipant(id: '1', dojangName: 'B'),
          ],
        ));
        
        expect(result.isLeft(), true);
      });

      test('pin position out of range returns ValidationFailure', () async {
        final result = await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
          pinnedSeeds: const {'1': 3}, // Only 2 participants, bracketSize should be 2.
        ));
        
        expect(result.isLeft(), true);
      });

      test('duplicate pin positions returns ValidationFailure', () async {
        final result = await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
          pinnedSeeds: const {'1': 1, '2': 1},
        ));
        
        expect(result.isLeft(), true);
      });

      test('pinned ID not in participants returns ValidationFailure', () async {
        final result = await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
          pinnedSeeds: const {'NON-EXISTENT': 1},
        ));
        
        expect(result.isLeft(), true);
      });
    });

    group('successful delegation', () {
      setUp(() {
        registerFallbackValue(const ManualSeedOverrideParams(
          participants: [],
          constraints: [],
        ));
      });

      test('constructs constraints correctly and calls service', () async {
        const resultObj = SeedingResult(
          placements: [],
          appliedConstraints: [],
          randomSeed: 0,
        );
        
        when(() => mockService.reseedAroundPins(any()))
            .thenReturn(const Right(resultObj));

        final result = await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
          enableDojangSeparation: true,
          enableRegionalSeparation: false,
          pinnedSeeds: const {'1': 1},
        ));

        expect(result.isRight(), true);
        
        final paramsInCall = verify(() => mockService.reseedAroundPins(captureAny()))
            .captured.last as ManualSeedOverrideParams;
            
        expect(paramsInCall.constraints.length, 1);
        expect(paramsInCall.constraints.first.name, 'dojang_separation');
        expect(paramsInCall.pinnedSeeds, {'1': 1});
      });

      test('can disable all constraints and still seed', () async {
         const resultObj = SeedingResult(
          placements: [],
          appliedConstraints: [],
          randomSeed: 0,
        );
        
        when(() => mockService.reseedAroundPins(any()))
            .thenReturn(const Right(resultObj));

        await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
          enableDojangSeparation: false,
          enableRegionalSeparation: false,
        ));

        final paramsInCall = verify(() => mockService.reseedAroundPins(captureAny()))
            .captured.last as ManualSeedOverrideParams;
            
        expect(paramsInCall.constraints, isEmpty);
      });

      test('both dojang and regional enabled constructs 2 constraints in order', () async {
        const resultObj = SeedingResult(
          placements: [],
          appliedConstraints: [],
          randomSeed: 0,
        );

        when(() => mockService.reseedAroundPins(any()))
            .thenReturn(const Right(resultObj));

        await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
          enableDojangSeparation: true,
          enableRegionalSeparation: true,
        ));

        final paramsInCall = verify(() => mockService.reseedAroundPins(captureAny()))
            .captured.last as ManualSeedOverrideParams;

        expect(paramsInCall.constraints.length, 2);
        expect(paramsInCall.constraints[0], isA<DojangSeparationConstraint>());
        expect(paramsInCall.constraints[1], isA<RegionalSeparationConstraint>());
      });

      test('SeedingFailure propagated from service', () async {
        when(() => mockService.reseedAroundPins(any()))
            .thenReturn(const Left(SeedingFailure(
              userFriendlyMessage: 'Engine failed',
            )));

        final result = await useCase(ApplyManualSeedOverrideParams(
          divisionId: 'D1',
          participants: participants,
        ));

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<SeedingFailure>()),
          (_) => fail('Expected failure'),
        );
      });
    });
  });
}
