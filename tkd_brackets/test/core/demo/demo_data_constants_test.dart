import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/demo/demo_data_constants.dart';

void main() {
  group('DemoDataConstants', () {
    group('UUID validation', () {
      /// Regex for validating UUID v4 format.
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      test('demoUserId is valid UUID format', () {
        expect(
          uuidRegex.hasMatch(DemoDataConstants.demoUserId),
          isTrue,
          reason: 'demoUserId should be valid UUID',
        );
      });

      test('demoOrganizationId is valid UUID format', () {
        expect(
          uuidRegex.hasMatch(DemoDataConstants.demoOrganizationId),
          isTrue,
          reason: 'demoOrganizationId should be valid UUID',
        );
      });

      test('demoTournamentId is valid UUID format', () {
        expect(
          uuidRegex.hasMatch(DemoDataConstants.demoTournamentId),
          isTrue,
          reason: 'demoTournamentId should be valid UUID',
        );
      });

      test('demoDivisionId is valid UUID format', () {
        expect(
          uuidRegex.hasMatch(DemoDataConstants.demoDivisionId),
          isTrue,
          reason: 'demoDivisionId should be valid UUID',
        );
      });

      test('all participant UUIDs are valid format', () {
        for (final id in DemoDataConstants.demoParticipantIds) {
          expect(
            uuidRegex.hasMatch(id),
            isTrue,
            reason: 'Participant ID $id should be valid UUID',
          );
        }
      });
    });

    group('UUID uniqueness', () {
      test('no duplicate UUIDs across all constants', () {
        final allUuids = <String>[
          DemoDataConstants.demoUserId,
          DemoDataConstants.demoOrganizationId,
          DemoDataConstants.demoTournamentId,
          DemoDataConstants.demoDivisionId,
          ...DemoDataConstants.demoParticipantIds,
        ];

        final uniqueUuids = allUuids.toSet();

        expect(
          uniqueUuids.length,
          equals(allUuids.length),
          reason: 'All UUIDs should be unique',
        );
      });
    });

    group('participant constants', () {
      test('has exactly 8 participant IDs', () {
        expect(DemoDataConstants.demoParticipantIds, hasLength(8));
      });

      test('has exactly 4 sample dojangs', () {
        expect(DemoDataConstants.sampleDojangs, hasLength(4));
      });

      test('all dojang names are non-empty', () {
        for (final dojang in DemoDataConstants.sampleDojangs) {
          expect(dojang.isNotEmpty, isTrue);
        }
      });
    });

    group('demo user constants', () {
      test('demoUserEmail has valid local domain', () {
        expect(DemoDataConstants.demoUserEmail, contains('@tkdbrackets.local'));
      });

      test('demoUserDisplayName is non-empty', () {
        expect(DemoDataConstants.demoUserDisplayName.isNotEmpty, isTrue);
      });

      test('demoUserRole is owner', () {
        expect(DemoDataConstants.demoUserRole, equals('owner'));
      });
    });

    group('demo organization constants', () {
      test('demoOrganizationName is non-empty', () {
        expect(DemoDataConstants.demoOrganizationName.isNotEmpty, isTrue);
      });

      test('demoOrganizationSlug is lowercase kebab-case', () {
        expect(
          DemoDataConstants.demoOrganizationSlug,
          matches(RegExp(r'^[a-z0-9-]+$')),
        );
      });

      test('demoOrganizationTier is free', () {
        expect(DemoDataConstants.demoOrganizationTier, equals('free'));
      });
    });

    group('demo tournament constants', () {
      test('demoTournamentName is non-empty', () {
        expect(DemoDataConstants.demoTournamentName.isNotEmpty, isTrue);
      });

      test('demoTournamentFederation is valid type', () {
        expect([
          'wt',
          'itf',
          'ata',
          'custom',
        ], contains(DemoDataConstants.demoTournamentFederation));
      });

      test('demoTournamentStatus is valid status', () {
        final validStatuses = [
          'draft',
          'registration_open',
          'registration_closed',
          'in_progress',
          'completed',
          'cancelled',
        ];
        expect(validStatuses, contains(DemoDataConstants.demoTournamentStatus));
      });

      test('demoTournamentDaysFromNow is positive', () {
        expect(DemoDataConstants.demoTournamentDaysFromNow, greaterThan(0));
      });
    });

    group('demo division constants', () {
      test('demoDivisionName is non-empty', () {
        expect(DemoDataConstants.demoDivisionName.isNotEmpty, isTrue);
      });

      test('demoDivisionCategory is valid category', () {
        final validCategories = [
          'sparring',
          'poomsae',
          'breaking',
          'demo_team',
        ];
        expect(
          validCategories,
          contains(DemoDataConstants.demoDivisionCategory),
        );
      });

      test('demoDivisionGender is valid gender', () {
        expect([
          'male',
          'female',
          'mixed',
        ], contains(DemoDataConstants.demoDivisionGender));
      });

      test('demoDivisionAgeMin is less than demoDivisionAgeMax', () {
        expect(
          DemoDataConstants.demoDivisionAgeMin,
          lessThan(DemoDataConstants.demoDivisionAgeMax),
        );
      });

      test('demoDivisionWeightMin is less than demoDivisionWeightMax', () {
        expect(
          DemoDataConstants.demoDivisionWeightMin,
          lessThan(DemoDataConstants.demoDivisionWeightMax),
        );
      });

      test('demoDivisionBracketFormat is valid format', () {
        final validFormats = [
          'single_elimination',
          'double_elimination',
          'round_robin',
          'pool_play',
        ];
        expect(
          validFormats,
          contains(DemoDataConstants.demoDivisionBracketFormat),
        );
      });

      test('demoDivisionStatus is valid status', () {
        final validStatuses = ['setup', 'ready', 'in_progress', 'completed'];
        expect(validStatuses, contains(DemoDataConstants.demoDivisionStatus));
      });
    });

    group('demo participant gender constant', () {
      test('demoParticipantGender is valid gender', () {
        expect([
          'male',
          'female',
        ], contains(DemoDataConstants.demoParticipantGender));
      });
    });
  });
}
