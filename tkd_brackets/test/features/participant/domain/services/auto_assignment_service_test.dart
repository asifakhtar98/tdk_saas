import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/services/auto_assignment_service.dart';

void main() {
  late AutoAssignmentService service;

  setUp(() {
    service = AutoAssignmentService();
  });

  DivisionEntity createTestDivision({
    required String id,
    DivisionGender gender = DivisionGender.male,
    int? ageMin,
    int? ageMax,
    double? weightMinKg,
    double? weightMaxKg,
    String? beltRankMin,
    String? beltRankMax,
    DivisionStatus status = DivisionStatus.ready,
  }) {
    return DivisionEntity(
      id: id,
      tournamentId: 'tournament-1',
      name: 'Test Division $id',
      category: DivisionCategory.sparring,
      gender: gender,
      ageMin: ageMin,
      ageMax: ageMax,
      weightMinKg: weightMinKg,
      weightMaxKg: weightMaxKg,
      beltRankMin: beltRankMin,
      beltRankMax: beltRankMax,
      bracketFormat: BracketFormat.singleElimination,
      status: status,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  ParticipantEntity createTestParticipant({
    required String id,
    Gender? gender,
    DateTime? dateOfBirth,
    double? weightKg,
    String? beltRank,
  }) {
    return ParticipantEntity(
      id: id,
      divisionId: 'division-1',
      firstName: 'Test',
      lastName: 'Participant',
      gender: gender,
      dateOfBirth: dateOfBirth,
      weightKg: weightKg,
      beltRank: beltRank,
      checkInStatus: ParticipantStatus.pending,
      createdAtTimestamp: DateTime.now(),
      updatedAtTimestamp: DateTime.now(),
    );
  }

  DateTime dateAtAge(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }

  group('evaluateMatch - age criteria', () {
    test('matches when age within range', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(10),
      );
      final division = createTestDivision(id: 'd1', ageMin: 8, ageMax: 12);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched['age'], true);
    });

    test('matches when age equals min boundary', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(8),
      );
      final division = createTestDivision(id: 'd1', ageMin: 8, ageMax: 12);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('matches when age equals max boundary', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(12),
      );
      final division = createTestDivision(id: 'd1', ageMin: 8, ageMax: 12);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('returns null when age below min', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(7),
      );
      final division = createTestDivision(id: 'd1', ageMin: 8, ageMax: 12);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNull);
    });

    test('returns null when age above max', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(13),
      );
      final division = createTestDivision(id: 'd1', ageMin: 8, ageMax: 12);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNull);
    });

    test('matches when age null (no age constraint on participant)', () {
      final participant = createTestParticipant(id: 'p1', dateOfBirth: null);
      final division = createTestDivision(id: 'd1', ageMin: 8, ageMax: 12);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('matches when division has no age constraints', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(10),
      );
      final division = createTestDivision(id: 'd1');

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });
  });

  group('evaluateMatch - gender criteria', () {
    test('matches when gender matches', () {
      final participant = createTestParticipant(id: 'p1', gender: Gender.male);
      final division = createTestDivision(
        id: 'd1',
        gender: DivisionGender.male,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched['gender'], true);
    });

    test('returns null when gender mismatch', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.female,
      );
      final division = createTestDivision(
        id: 'd1',
        gender: DivisionGender.male,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNull);
    });

    test('matches when division is mixed (any gender)', () {
      final maleParticipant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
      );
      final femaleParticipant = createTestParticipant(
        id: 'p2',
        gender: Gender.female,
      );
      final division = createTestDivision(
        id: 'd1',
        gender: DivisionGender.mixed,
      );

      expect(service.evaluateMatch(maleParticipant, division), isNotNull);
      expect(service.evaluateMatch(femaleParticipant, division), isNotNull);
    });

    test('matches when participant has null gender', () {
      final participant = createTestParticipant(id: 'p1', gender: null);
      final division = createTestDivision(
        id: 'd1',
        gender: DivisionGender.male,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });
  });

  group('evaluateMatch - weight criteria', () {
    test('matches when weight within range', () {
      final participant = createTestParticipant(id: 'p1', weightKg: 35);
      final division = createTestDivision(
        id: 'd1',
        weightMinKg: 30,
        weightMaxKg: 40,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched['weight'], true);
    });

    test('returns null when weight below min', () {
      final participant = createTestParticipant(id: 'p1', weightKg: 25);
      final division = createTestDivision(
        id: 'd1',
        weightMinKg: 30,
        weightMaxKg: 40,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNull);
    });

    test('returns null when weight above max', () {
      final participant = createTestParticipant(id: 'p1', weightKg: 45);
      final division = createTestDivision(
        id: 'd1',
        weightMinKg: 30,
        weightMaxKg: 40,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNull);
    });

    test('matches when participant weight is null (counts as matching)', () {
      final participant = createTestParticipant(id: 'p1', weightKg: null);
      final division = createTestDivision(
        id: 'd1',
        weightMinKg: 30,
        weightMaxKg: 40,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched['weight'], true);
    });

    test('matches when division has no weight constraints', () {
      final participant = createTestParticipant(id: 'p1', weightKg: 35);
      final division = createTestDivision(id: 'd1');

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched.containsKey('weight'), false);
    });
  });

  group('evaluateMatch - belt rank criteria', () {
    test('matches when belt within range', () {
      final participant = createTestParticipant(id: 'p1', beltRank: 'blue');
      final division = createTestDivision(
        id: 'd1',
        beltRankMin: 'green',
        beltRankMax: 'red',
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched['belt'], true);
    });

    test(
      'belt rank ordering: black > red > blue > green > orange > yellow > white',
      () {
        final blackParticipant = createTestParticipant(
          id: 'p1',
          beltRank: 'black',
        );
        final whiteParticipant = createTestParticipant(
          id: 'p2',
          beltRank: 'white',
        );

        final blackBeltDivision = createTestDivision(
          id: 'd1',
          beltRankMin: 'black',
          beltRankMax: 'black',
        );
        final beginnerDivision = createTestDivision(
          id: 'd2',
          beltRankMin: 'white',
          beltRankMax: 'yellow',
        );

        expect(
          service.evaluateMatch(blackParticipant, blackBeltDivision),
          isNotNull,
        );
        expect(
          service.evaluateMatch(whiteParticipant, beginnerDivision),
          isNotNull,
        );
        expect(
          service.evaluateMatch(whiteParticipant, blackBeltDivision),
          isNull,
        );
        expect(
          service.evaluateMatch(blackParticipant, beginnerDivision),
          isNull,
        );
      },
    );

    test('matches when participant belt is null', () {
      final participant = createTestParticipant(id: 'p1', beltRank: null);
      final division = createTestDivision(
        id: 'd1',
        beltRankMin: 'green',
        beltRankMax: 'red',
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('matches when division has no belt constraints', () {
      final participant = createTestParticipant(id: 'p1', beltRank: 'blue');
      final division = createTestDivision(id: 'd1');

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.criteriaMatched.containsKey('belt'), false);
    });

    test('handles belt at min boundary', () {
      final participant = createTestParticipant(id: 'p1', beltRank: 'green');
      final division = createTestDivision(
        id: 'd1',
        beltRankMin: 'green',
        beltRankMax: 'blue',
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('handles belt at max boundary', () {
      final participant = createTestParticipant(id: 'p1', beltRank: 'blue');
      final division = createTestDivision(
        id: 'd1',
        beltRankMin: 'green',
        beltRankMax: 'blue',
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });
  });

  group('evaluateMatch - matchScore calculation', () {
    test('matchScore increases for each matching criteria', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
        dateOfBirth: dateAtAge(10),
        weightKg: 35,
        beltRank: 'blue',
      );
      final division = createTestDivision(
        id: 'd1',
        gender: DivisionGender.male,
        ageMin: 8,
        ageMax: 12,
        weightMinKg: 30,
        weightMaxKg: 40,
        beltRankMin: 'green',
        beltRankMax: 'red',
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.matchScore, 4);
      expect(match.criteriaMatched['age'], true);
      expect(match.criteriaMatched['gender'], true);
      expect(match.criteriaMatched['weight'], true);
      expect(match.criteriaMatched['belt'], true);
    });

    test('matchScore only counts criteria with constraints', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
        dateOfBirth: dateAtAge(10),
      );
      final division = createTestDivision(
        id: 'd1',
        gender: DivisionGender.male,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
      expect(match!.matchScore, 2);
      expect(match.criteriaMatched['age'], true);
      expect(match.criteriaMatched['gender'], true);
    });
  });

  group('determineUnmatchedReason', () {
    test('returns "No divisions exist in tournament" when empty', () {
      final participant = createTestParticipant(id: 'p1');
      final reason = service.determineUnmatchedReason(participant, []);

      expect(reason, 'No divisions exist in tournament');
    });

    test('returns gender reason when no matching gender', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.female,
      );
      final divisions = [
        createTestDivision(id: 'd1', gender: DivisionGender.male),
      ];

      final reason = service.determineUnmatchedReason(participant, divisions);

      expect(reason, 'No divisions with matching gender criteria');
    });

    test('returns age reason when no matching age range', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
        dateOfBirth: dateAtAge(20),
      );
      final divisions = [
        createTestDivision(
          id: 'd1',
          gender: DivisionGender.male,
          ageMin: 8,
          ageMax: 12,
        ),
      ];

      final reason = service.determineUnmatchedReason(participant, divisions);

      expect(reason, 'No divisions with matching age range');
    });

    test('returns weight reason when no matching weight class', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
        weightKg: 50,
      );
      final divisions = [
        createTestDivision(
          id: 'd1',
          gender: DivisionGender.male,
          weightMinKg: 30,
          weightMaxKg: 40,
        ),
      ];

      final reason = service.determineUnmatchedReason(participant, divisions);

      expect(reason, 'No divisions with matching weight class');
    });

    test('returns belt reason when no matching belt rank', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
        beltRank: 'white',
      );
      final divisions = [
        createTestDivision(
          id: 'd1',
          gender: DivisionGender.male,
          beltRankMin: 'black',
          beltRankMax: 'black',
        ),
      ];

      final reason = service.determineUnmatchedReason(participant, divisions);

      expect(reason, 'No divisions with matching belt rank');
    });

    test('returns generic reason when criteria pass but still no match', () {
      final participant = createTestParticipant(
        id: 'p1',
        gender: Gender.male,
        dateOfBirth: dateAtAge(10),
      );
      final divisions = [
        createTestDivision(
          id: 'd1',
          gender: DivisionGender.male,
          ageMin: 8,
          ageMax: 12,
          weightMinKg: 50,
          weightMaxKg: 60,
        ),
      ];

      final reason = service.determineUnmatchedReason(participant, divisions);

      expect(reason, 'No suitable division found');
    });
  });

  group('edge cases', () {
    test(
      'handles null age, weight, belt, gender on participant with constraints',
      () {
        final participant = createTestParticipant(
          id: 'p1',
          gender: null,
          dateOfBirth: null,
          weightKg: null,
          beltRank: null,
        );
        final division = createTestDivision(
          id: 'd1',
          gender: DivisionGender.male,
          ageMin: 8,
          ageMax: 12,
          weightMinKg: 30,
          weightMaxKg: 40,
          beltRankMin: 'green',
          beltRankMax: 'red',
        );

        final match = service.evaluateMatch(participant, division);

        expect(match, isNotNull);
        expect(match!.matchScore, 4);
        expect(match.criteriaMatched['age'], true);
        expect(match.criteriaMatched['gender'], true);
        expect(match.criteriaMatched['weight'], true);
        expect(match.criteriaMatched['belt'], true);
      },
    );

    test('handles division with only min constraints', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(10),
        weightKg: 35,
      );
      final division = createTestDivision(id: 'd1', ageMin: 8, weightMinKg: 30);

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('handles division with only max constraints', () {
      final participant = createTestParticipant(
        id: 'p1',
        dateOfBirth: dateAtAge(10),
        weightKg: 35,
      );
      final division = createTestDivision(
        id: 'd1',
        ageMax: 12,
        weightMaxKg: 40,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });
  });

  group('division status filtering', () {
    test('matches setup status division', () {
      final participant = createTestParticipant(id: 'p1');
      final division = createTestDivision(
        id: 'd1',
        status: DivisionStatus.setup,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test('matches ready status division', () {
      final participant = createTestParticipant(id: 'p1');
      final division = createTestDivision(
        id: 'd1',
        status: DivisionStatus.ready,
      );

      final match = service.evaluateMatch(participant, division);

      expect(match, isNotNull);
    });

    test(
      'still evaluates match for in_progress division (filtering happens in use case)',
      () {
        final participant = createTestParticipant(id: 'p1');
        final division = createTestDivision(
          id: 'd1',
          status: DivisionStatus.inProgress,
        );

        final match = service.evaluateMatch(participant, division);

        expect(match, isNotNull);
      },
    );
  });
}
