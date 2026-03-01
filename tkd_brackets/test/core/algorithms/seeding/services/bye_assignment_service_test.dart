import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';

void main() {
  late ByeAssignmentService service;

  setUp(() {
    service = ByeAssignmentService();
  });

  ByeAssignmentResult extractResult(Either<Failure, ByeAssignmentResult> result) =>
      result.getOrElse((_) => throw Exception('Expected Right, got Left'));

  group('ByeAssignmentService', () {
    group('validation', () {
      test('0 participants → Left(ValidationFailure)', () {
        final result = service.assignByes(
          const ByeAssignmentParams(participantCount: 0),
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<ValidationFailure>()),
          (_) => throw Exception('unexpected'),
        );
      });

      test('1 participant → Left(ValidationFailure)', () {
        final result = service.assignByes(
          const ByeAssignmentParams(participantCount: 1),
        );
        expect(result.isLeft(), isTrue);
      });

      test('seedOrder length mismatch → Left(ValidationFailure)', () {
        final result = service.assignByes(
          const ByeAssignmentParams(
            participantCount: 3,
            seedOrder: ['a', 'b'], // length 2 != 3
          ),
        );
        expect(result.isLeft(), isTrue);
      });
    });

    group('zero byes (power of 2)', () {
      test('2 participants → 0 byes, bracketSize 2', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 2),
        ));
        expect(r.byeCount, equals(0));
        expect(r.bracketSize, equals(2));
        expect(r.totalRounds, equals(1));
        expect(r.byePlacements, isEmpty);
        expect(r.byeSlots, isEmpty);
      });

      test('8 participants → 0 byes, bracketSize 8', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 8),
        ));
        expect(r.byeCount, equals(0));
        expect(r.bracketSize, equals(8));
        expect(r.totalRounds, equals(3));
        expect(r.byePlacements, isEmpty);
        expect(r.byeSlots, isEmpty);
      });
    });

    group('bye distribution', () {
      test('3 participants → 1 bye, seed 1 gets bye', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 3),
        ));
        expect(r.byeCount, equals(1));
        expect(r.bracketSize, equals(4));
        expect(r.totalRounds, equals(2));
        expect(r.byePlacements, hasLength(1));
        expect(r.byePlacements[0].seedPosition, equals(1));
      });

      test('5 participants → 3 byes distributed across halves', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 5),
        ));
        expect(r.byeCount, equals(3));
        expect(r.bracketSize, equals(8));
        // Verify distribution: byes should appear in multiple halves
        final topHalf = r.byeSlots.where((s) => s <= 4).length;
        final bottomHalf = r.byeSlots.where((s) => s > 4).length;
        expect(topHalf, greaterThan(0), reason: 'At least 1 bye in top half');
        expect(bottomHalf, greaterThan(0), reason: 'At least 1 bye in bottom half');
      });

      test('7 participants → 1 bye', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 7),
        ));
        expect(r.byeCount, equals(1));
        expect(r.bracketSize, equals(8));
        expect(r.byePlacements[0].seedPosition, equals(1));
      });

      test('6 participants → 2 byes, bracketSize 8', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 6),
        ));
        expect(r.byeCount, equals(2));
        expect(r.bracketSize, equals(8));
        expect(r.totalRounds, equals(3));
      });

      test('9 participants → 7 byes, bracketSize 16', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 9),
        ));
        expect(r.byeCount, equals(7));
        expect(r.bracketSize, equals(16));
        expect(r.totalRounds, equals(4));
      });

      test('15 participants → 1 bye, bracketSize 16', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 15),
        ));
        expect(r.byeCount, equals(1));
        expect(r.bracketSize, equals(16));
        expect(r.totalRounds, equals(4));
      });

      test('17 participants → 15 byes, bracketSize 32', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 17),
        ));
        expect(r.byeCount, equals(15));
        expect(r.bracketSize, equals(32));
        expect(r.totalRounds, equals(5));
      });

      test('33 participants → 31 byes, bracketSize 64', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 33),
        ));
        expect(r.byeCount, equals(31));
        expect(r.bracketSize, equals(64));
        expect(r.totalRounds, equals(6));
      });

      test('all bye seeds are top seeds (1, 2, 3, ...)', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 5),
        ));
        final seeds = r.byePlacements.map((p) => p.seedPosition).toList()..sort();
        expect(seeds, equals([1, 2, 3]));
      });
    });

    group('invariants for all sizes', () {
      test('bye slots and participant slots never overlap', () {
        for (final n in [3, 5, 6, 7, 9, 15, 17, 33]) {
          final r = extractResult(service.assignByes(
            ByeAssignmentParams(participantCount: n),
          ));
          for (final p in r.byePlacements) {
            expect(p.bracketSlot, isNot(equals(p.byeSlot)),
                reason: 'n=$n: participant slot and bye slot must differ');
            expect(r.byeSlots.contains(p.byeSlot), isTrue,
                reason: 'n=$n: byeSlot must be in byeSlots set');
            expect(r.byeSlots.contains(p.bracketSlot), isFalse,
                reason: 'n=$n: participant slot must NOT be a bye slot');
          }
          // Verify byeCount matches
          expect(r.byeCount, equals(r.byePlacements.length),
              reason: 'n=$n: byeCount must equal byePlacements length');
          expect(r.byeCount, equals(r.byeSlots.length),
              reason: 'n=$n: byeCount must equal byeSlots size');
        }
      });
    });

    group('seedOrder', () {
      test('with seedOrder → participantIds populated', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(
            participantCount: 3,
            seedOrder: ['alice', 'bob', 'charlie'],
          ),
        ));
        expect(r.byePlacements[0].participantId, equals('alice'));
        expect(r.byePlacements[0].seedPosition, equals(1));
      });

      test('without seedOrder → participantIds null', () {
        final r = extractResult(service.assignByes(
          const ByeAssignmentParams(participantCount: 3),
        ));
        expect(r.byePlacements[0].participantId, isNull);
      });
    });

    group('performance', () {
      test('128 participants completes in < 50ms', () {
        final sw = Stopwatch()..start();
        final result = service.assignByes(
          const ByeAssignmentParams(participantCount: 128),
        );
        sw.stop();
        expect(result.isRight(), isTrue);
        expect(sw.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
