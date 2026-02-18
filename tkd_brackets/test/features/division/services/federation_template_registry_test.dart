import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/division/services/federation_template_registry.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_template.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

void main() {
  late FederationTemplateRegistry registry;

  setUp(() {
    registry = FederationTemplateRegistry(null);
  });

  group('FederationTemplateRegistry', () {
    group('getStaticTemplates', () {
      test('should return all WT static templates', () {
        final templates = registry.getStaticTemplates(FederationType.wt);

        expect(templates, isNotEmpty);
        expect(
          templates.every((t) => t.federation == FederationType.wt),
          isTrue,
        );
        expect(templates.length, greaterThanOrEqualTo(52));

        final weightClasses = templates
            .where((t) => t.category == DivisionCategory.sparring)
            .map((t) => t.weightMaxKg)
            .toSet();
        expect(weightClasses, contains(33.0));
        expect(weightClasses, contains(54.0));
        expect(weightClasses, contains(87.0));
      });

      test('should return all ITF static templates (Pattern + Sparring)', () {
        final templates = registry.getStaticTemplates(FederationType.itf);

        expect(templates, isNotEmpty);

        final categories = templates.map((t) => t.category).toSet();
        expect(categories, contains(DivisionCategory.poomsae));
        expect(categories, contains(DivisionCategory.sparring));

        final patterns = templates
            .where((t) => t.category == DivisionCategory.poomsae)
            .toList();
        expect(patterns.length, greaterThanOrEqualTo(20));

        final sparring = templates
            .where((t) => t.category == DivisionCategory.sparring)
            .toList();
        expect(sparring.length, greaterThanOrEqualTo(20));
      });

      test('should return all ATA static templates (Forms + Combat)', () {
        final templates = registry.getStaticTemplates(FederationType.ata);

        expect(templates, isNotEmpty);

        final categories = templates.map((t) => t.category).toSet();
        expect(categories, contains(DivisionCategory.poomsae));
        expect(categories, contains(DivisionCategory.sparring));

        final forms = templates
            .where((t) => t.category == DivisionCategory.poomsae)
            .toList();
        expect(forms.length, greaterThanOrEqualTo(42));

        final combat = templates
            .where((t) => t.category == DivisionCategory.sparring)
            .toList();
        expect(combat.length, greaterThanOrEqualTo(6));
      });
    });

    group('getTemplatesByCategory', () {
      test('should filter WT templates by sparring category', () {
        final templates = registry.getTemplatesByCategory(
          FederationType.wt,
          DivisionCategory.sparring,
        );

        expect(templates, isNotEmpty);
        expect(
          templates.every((t) => t.category == DivisionCategory.sparring),
          isTrue,
        );
      });

      test('should filter ITF templates by poomsae category', () {
        final templates = registry.getTemplatesByCategory(
          FederationType.itf,
          DivisionCategory.poomsae,
        );

        expect(templates, isNotEmpty);
        expect(
          templates.every((t) => t.category == DivisionCategory.poomsae),
          isTrue,
        );
      });

      test('should filter ATA templates by sparring category', () {
        final templates = registry.getTemplatesByCategory(
          FederationType.ata,
          DivisionCategory.sparring,
        );

        expect(templates, isNotEmpty);
        expect(
          templates.every((t) => t.category == DivisionCategory.sparring),
          isTrue,
        );
      });
    });

    group('getTemplatesByGender', () {
      test('should filter templates by male gender', () {
        final templates = registry.getTemplatesByGender(
          FederationType.wt,
          DivisionGender.male,
        );

        expect(templates, isNotEmpty);
        expect(templates.every((t) => t.gender == DivisionGender.male), isTrue);
      });

      test('should filter templates by female gender', () {
        final templates = registry.getTemplatesByGender(
          FederationType.wt,
          DivisionGender.female,
        );

        expect(templates, isNotEmpty);
        expect(
          templates.every((t) => t.gender == DivisionGender.female),
          isTrue,
        );
      });

      test('should filter templates by mixed gender', () {
        final templates = registry.getTemplatesByGender(
          FederationType.itf,
          DivisionGender.mixed,
        );

        expect(templates, isNotEmpty);
        expect(
          templates.every((t) => t.gender == DivisionGender.mixed),
          isTrue,
        );
      });
    });

    group('getTemplateById', () {
      test('should return template by ID', () {
        final template = registry.getTemplateById('wt-cadet-male-33');

        expect(template, isNotNull);
        expect(template!.id, equals('wt-cadet-male-33'));
        expect(template.name, equals('Cadet Male -33kg'));
        expect(template.federation, equals(FederationType.wt));
      });

      test('should return null for non-existent ID', () {
        final template = registry.getTemplateById('non-existent-id');

        expect(template, isNull);
      });
    });

    group('getAllTemplates', () {
      test('should return all templates for federation', () {
        final templates = registry.getAllTemplates(FederationType.wt);

        expect(templates, isNotEmpty);
        expect(
          templates.length,
          equals(registry.getStaticTemplates(FederationType.wt).length),
        );
      });
    });

    group('Performance', () {
      test('should return WT templates in < 50ms', () {
        final stopwatch = Stopwatch()..start();
        final templates = registry.getStaticTemplates(FederationType.wt);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(templates, isNotEmpty);
      });

      test('should return ITF templates in < 50ms', () {
        final stopwatch = Stopwatch()..start();
        final templates = registry.getStaticTemplates(FederationType.itf);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(templates, isNotEmpty);
      });

      test('should return ATA templates in < 50ms', () {
        final stopwatch = Stopwatch()..start();
        final templates = registry.getStaticTemplates(FederationType.ata);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
        expect(templates, isNotEmpty);
      });

      test('should handle getAllTemplates in < 100ms', () {
        final stopwatch = Stopwatch()..start();
        final templates = registry.getAllTemplates(FederationType.wt);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(templates, isNotEmpty);
      });
    });

    group('Template Properties', () {
      test('WT templates should have correct age ranges', () {
        final templates = registry.getStaticTemplates(FederationType.wt);
        final cadet = templates.where((t) => t.name.contains('Cadet')).toList();

        expect(cadet, isNotEmpty);
        expect(cadet.every((t) => t.ageMin == 12 && t.ageMax == 14), isTrue);
      });

      test('ITF Pattern templates should have correct structure', () {
        final templates = registry.getStaticTemplates(FederationType.itf);
        final patterns = templates
            .where((t) => t.category == DivisionCategory.poomsae)
            .toList();

        expect(patterns, isNotEmpty);
        final hasMale = patterns.any((t) => t.gender == DivisionGender.male);
        final hasFemale = patterns.any(
          (t) => t.gender == DivisionGender.female,
        );
        expect(hasMale, isTrue);
        expect(hasFemale, isTrue);
      });

      test('ATA Forms templates should have belt rank ranges', () {
        final templates = registry.getStaticTemplates(FederationType.ata);
        final forms = templates
            .where((t) => t.category == DivisionCategory.poomsae)
            .toList();

        expect(forms, isNotEmpty);
        final withBelts = forms.where((t) => t.beltRankMin != null).toList();
        expect(withBelts, isNotEmpty);
      });

      test('All templates should have isStaticTemplate = true', () {
        final wtTemplates = registry.getStaticTemplates(FederationType.wt);
        final itfTemplates = registry.getStaticTemplates(FederationType.itf);
        final ataTemplates = registry.getStaticTemplates(FederationType.ata);

        expect(wtTemplates.every((t) => t.isStaticTemplate), isTrue);
        expect(itfTemplates.every((t) => t.isStaticTemplate), isTrue);
        expect(ataTemplates.every((t) => t.isStaticTemplate), isTrue);
      });
    });

    group('WT Weight Classes Verification', () {
      test('should have all Cadet Male weight classes', () {
        final templates = registry.getStaticTemplates(FederationType.wt);
        final cadetMale = templates
            .where((t) => t.name.contains('Cadet') && t.name.contains('Male'))
            .toList();

        expect(cadetMale.length, equals(10));

        final maxWeights = cadetMale.map((t) => t.weightMaxKg).toSet();
        expect(maxWeights, contains(33.0));
        expect(maxWeights, contains(37.0));
        expect(maxWeights, contains(41.0));
        expect(maxWeights, contains(45.0));
        expect(maxWeights, contains(49.0));
        expect(maxWeights, contains(53.0));
        expect(maxWeights, contains(57.0));
        expect(maxWeights, contains(61.0));
        expect(maxWeights, contains(65.0));
        expect(maxWeights, contains(999.0));
      });

      test('should have all Cadet Female weight classes', () {
        final templates = registry.getStaticTemplates(FederationType.wt);
        final cadetFemale = templates
            .where((t) => t.name.contains('Cadet') && t.name.contains('Female'))
            .toList();

        expect(cadetFemale.length, equals(10));
      });

      test('should have all Senior Male weight classes', () {
        final templates = registry.getStaticTemplates(FederationType.wt);
        final seniorMale = templates
            .where((t) => t.name.contains('Senior') && t.name.contains('Male'))
            .toList();

        expect(seniorMale.length, equals(8));

        final maxWeights = seniorMale.map((t) => t.weightMaxKg).toSet();
        expect(maxWeights, contains(54.0));
        expect(maxWeights, contains(58.0));
        expect(maxWeights, contains(63.0));
        expect(maxWeights, contains(68.0));
        expect(maxWeights, contains(74.0));
        expect(maxWeights, contains(80.0));
        expect(maxWeights, contains(87.0));
        expect(maxWeights, contains(999.0));
      });
    });

    group('ITF Categories Verification', () {
      test('should have Pattern (Poomsae) divisions', () {
        final templates = registry.getStaticTemplates(FederationType.itf);
        final patterns = templates
            .where((t) => t.category == DivisionCategory.poomsae)
            .toList();

        expect(patterns.length, greaterThanOrEqualTo(20));

        final individual = patterns
            .where((t) => t.name.contains('Pattern'))
            .toList();
        expect(individual.length, greaterThanOrEqualTo(18));

        final team = patterns.where((t) => t.name.contains('Team')).toList();
        expect(team.length, equals(3));
      });

      test('should have Sparring divisions', () {
        final templates = registry.getStaticTemplates(FederationType.itf);
        final sparring = templates
            .where((t) => t.category == DivisionCategory.sparring)
            .toList();

        expect(sparring.length, greaterThanOrEqualTo(20));

        final u21 = sparring.where((t) => t.name.contains('U21')).toList();
        expect(u21.length, greaterThanOrEqualTo(14));

        final senior = sparring
            .where((t) => t.name.contains('Senior'))
            .toList();
        expect(senior.length, greaterThanOrEqualTo(10));
      });
    });

    group('ATA Categories Verification', () {
      test('should have Songahm Forms 1-20', () {
        final templates = registry.getStaticTemplates(FederationType.ata);
        final forms = templates
            .where(
              (t) =>
                  t.category == DivisionCategory.poomsae &&
                  t.name.contains('Songahm'),
            )
            .toList();

        expect(forms.length, greaterThanOrEqualTo(40));
      });

      test('should have Weapons Forms', () {
        final templates = registry.getStaticTemplates(FederationType.ata);
        final weapons = templates
            .where((t) => t.name.contains('Weapons'))
            .toList();

        expect(weapons.length, equals(2));
        expect(weapons.any((t) => t.gender == DivisionGender.male), isTrue);
        expect(weapons.any((t) => t.gender == DivisionGender.female), isTrue);
      });

      test('should have Combat Sparring divisions', () {
        final templates = registry.getStaticTemplates(FederationType.ata);
        final combat = templates
            .where(
              (t) =>
                  t.category == DivisionCategory.sparring &&
                  t.name.contains('Combat'),
            )
            .toList();

        expect(combat.length, equals(6));

        final male = combat
            .where((t) => t.gender == DivisionGender.male)
            .toList();
        final female = combat
            .where((t) => t.gender == DivisionGender.female)
            .toList();

        expect(male.length, equals(3));
        expect(female.length, equals(3));
      });
    });
  });
}
