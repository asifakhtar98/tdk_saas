import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/seeding_participant.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_bye_assignment_use_case.dart';
import 'package:tkd_brackets/core/error/failures.dart';

class MockByeAssignmentService extends Mock implements ByeAssignmentService {}

void main() {
  late MockByeAssignmentService mockService;
  late ApplyByeAssignmentUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const ByeAssignmentParams(participantCount: 2));
  });

  setUp(() {
    mockService = MockByeAssignmentService();
    useCase = ApplyByeAssignmentUseCase(mockService);
  });

  // Reusable test participants
  const participants = [
    SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
    SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
    SeedingParticipant(id: 'p3', dojangName: 'Eagle'),
  ];

  group('ApplyByeAssignmentUseCase', () {
    group('Validation (no service calls)', () {
      test('empty divisionId → ValidationFailure', () async {
        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: '',
          participants: participants,
        ));
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<ValidationFailure>()),
          (_) => throw Exception('unexpected'),
        );
        verifyNever(() => mockService.assignByes(any()));
      });

      test('< 2 participants → ValidationFailure', () async {
        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: 'div1',
          participants: [
            SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
          ],
        ));
        expect(result.isLeft(), isTrue);
        verifyNever(() => mockService.assignByes(any()));
      });

      test('empty participant IDs → ValidationFailure', () async {
        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: 'div1',
          participants: [
            SeedingParticipant(id: '', dojangName: 'Tiger'),
            SeedingParticipant(id: 'p2', dojangName: 'Dragon'),
          ],
        ));
        expect(result.isLeft(), isTrue);
        verifyNever(() => mockService.assignByes(any()));
      });

      test('duplicate participant IDs → ValidationFailure', () async {
        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: 'div1',
          participants: [
            SeedingParticipant(id: 'p1', dojangName: 'Tiger'),
            SeedingParticipant(id: 'p1', dojangName: 'Dragon'),
          ],
        ));
        expect(result.isLeft(), isTrue);
        verifyNever(() => mockService.assignByes(any()));
      });

      test('roundRobin format → ValidationFailure', () async {
        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: 'div1',
          participants: participants,
          bracketFormat: BracketFormat.roundRobin,
        ));
        expect(result.isLeft(), isTrue);
        verifyNever(() => mockService.assignByes(any()));
      });
    });

    group('Delegation', () {
      test('valid params → delegates to service with correct ByeAssignmentParams', () async {
        const byeResult = ByeAssignmentResult(
          byeCount: 1,
          bracketSize: 4,
          totalRounds: 2,
          byePlacements: [],
          byeSlots: <int>{},
        );
        when(() => mockService.assignByes(any()))
            .thenReturn(const Right(byeResult));

        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: 'div1',
          participants: participants,
        ));

        expect(result.isRight(), isTrue);
        final captured = verify(() => mockService.assignByes(captureAny()))
            .captured
            .single as ByeAssignmentParams;
        expect(captured.participantCount, equals(3));
        expect(captured.seedOrder, equals(['p1', 'p2', 'p3']));
      });

      test('service failure is propagated', () async {
        when(() => mockService.assignByes(any())).thenReturn(
          const Left(ValidationFailure(userFriendlyMessage: 'Too few')),
        );

        final result = await useCase(const ApplyByeAssignmentParams(
          divisionId: 'div1',
          participants: participants,
        ));
        expect(result.isLeft(), isTrue);
      });
    });
  });
}
