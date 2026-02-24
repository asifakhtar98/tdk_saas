import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

void main() {
  group('DivisionEntity', () {
    final testDate = DateTime(2024, 1, 1);

    test('should create DivisionEntity with all required fields', () {
      final entity = DivisionEntity(
        id: 'division-id',
        tournamentId: 'tournament-id',
        name: 'Cadets Male -45kg',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        bracketFormat: BracketFormat.singleElimination,
        status: DivisionStatus.setup,
        createdAtTimestamp: testDate,
        updatedAtTimestamp: testDate,
      );

      expect(entity.id, 'division-id');
      expect(entity.tournamentId, 'tournament-id');
      expect(entity.name, 'Cadets Male -45kg');
      expect(entity.category, DivisionCategory.sparring);
      expect(entity.gender, DivisionGender.male);
      expect(entity.bracketFormat, BracketFormat.singleElimination);
      expect(entity.status, DivisionStatus.setup);
      expect(entity.isCombined, false);
      expect(entity.displayOrder, 0);
      expect(entity.isDeleted, false);
      expect(entity.syncVersion, 1);
    });

    test('should create DivisionEntity with optional fields', () {
      final entity = DivisionEntity(
        id: 'division-id',
        tournamentId: 'tournament-id',
        name: 'Cadets Male -45kg',
        category: DivisionCategory.sparring,
        gender: DivisionGender.male,
        ageMin: 12,
        ageMax: 14,
        weightMinKg: 40,
        weightMaxKg: 45,
        beltRankMin: 'yellow',
        beltRankMax: 'red',
        bracketFormat: BracketFormat.doubleElimination,
        assignedRingNumber: 1,
        isCombined: true,
        displayOrder: 2,
        status: DivisionStatus.ready,
        createdAtTimestamp: testDate,
        updatedAtTimestamp: testDate,
      );

      expect(entity.ageMin, 12);
      expect(entity.ageMax, 14);
      expect(entity.weightMinKg, 40.0);
      expect(entity.weightMaxKg, 45.0);
      expect(entity.beltRankMin, 'yellow');
      expect(entity.beltRankMax, 'red');
      expect(entity.assignedRingNumber, 1);
      expect(entity.isCombined, true);
      expect(entity.displayOrder, 2);
      expect(entity.status, DivisionStatus.ready);
    });
  });

  group('DivisionCategory', () {
    test('fromString should return correct category', () {
      expect(
        DivisionCategory.fromString('sparring'),
        DivisionCategory.sparring,
      );
      expect(DivisionCategory.fromString('poomsae'), DivisionCategory.poomsae);
      expect(
        DivisionCategory.fromString('breaking'),
        DivisionCategory.breaking,
      );
      expect(
        DivisionCategory.fromString('demo_team'),
        DivisionCategory.demoTeam,
      );
    });

    test('fromString should return sparring for unknown value', () {
      expect(DivisionCategory.fromString('unknown'), DivisionCategory.sparring);
    });

    test('value should return correct string', () {
      expect(DivisionCategory.sparring.value, 'sparring');
      expect(DivisionCategory.poomsae.value, 'poomsae');
      expect(DivisionCategory.breaking.value, 'breaking');
      expect(DivisionCategory.demoTeam.value, 'demo_team');
    });
  });

  group('DivisionGender', () {
    test('fromString should return correct gender', () {
      expect(DivisionGender.fromString('male'), DivisionGender.male);
      expect(DivisionGender.fromString('female'), DivisionGender.female);
      expect(DivisionGender.fromString('mixed'), DivisionGender.mixed);
    });

    test('fromString should return mixed for unknown value', () {
      expect(DivisionGender.fromString('unknown'), DivisionGender.mixed);
    });
  });

  group('BracketFormat', () {
    test('fromString should return correct format', () {
      expect(
        BracketFormat.fromString('single_elimination'),
        BracketFormat.singleElimination,
      );
      expect(
        BracketFormat.fromString('double_elimination'),
        BracketFormat.doubleElimination,
      );
      expect(BracketFormat.fromString('round_robin'), BracketFormat.roundRobin);
      expect(BracketFormat.fromString('pool_play'), BracketFormat.poolPlay);
    });

    test('fromString should return singleElimination for unknown value', () {
      expect(
        BracketFormat.fromString('unknown'),
        BracketFormat.singleElimination,
      );
    });
  });

  group('DivisionStatus', () {
    test('fromString should return correct status', () {
      expect(DivisionStatus.fromString('setup'), DivisionStatus.setup);
      expect(DivisionStatus.fromString('ready'), DivisionStatus.ready);
      expect(
        DivisionStatus.fromString('in_progress'),
        DivisionStatus.inProgress,
      );
      expect(DivisionStatus.fromString('completed'), DivisionStatus.completed);
    });

    test('fromString should return setup for unknown value', () {
      expect(DivisionStatus.fromString('unknown'), DivisionStatus.setup);
    });
  });
}
