// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/core/database/app_database.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';

void main() {
  final now = DateTime(2024, 1, 1);

  final testModel = OrganizationModel(
    id: 'org-1',
    name: 'Dragon Martial Arts',
    slug: 'dragon-martial-arts',
    subscriptionTier: 'free',
    subscriptionStatus: 'active',
    maxTournamentsPerMonth: 2,
    maxActiveBrackets: 3,
    maxParticipantsPerBracket: 32,
    maxParticipantsPerTournament: 100,
    maxScorers: 2,
    isActive: true,
    createdAtTimestamp: now,
    updatedAtTimestamp: now,
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
  );

  final testEntry = OrganizationEntry(
    id: 'org-1',
    name: 'Dragon Martial Arts',
    slug: 'dragon-martial-arts',
    subscriptionTier: 'free',
    subscriptionStatus: 'active',
    maxTournamentsPerMonth: 2,
    maxActiveBrackets: 3,
    maxParticipantsPerBracket: 32,
    maxParticipantsPerTournament: 100,
    maxScorers: 2,
    isActive: true,
    createdAtTimestamp: now,
    updatedAtTimestamp: now,
    syncVersion: 1,
    isDeleted: false,
    isDemoData: false,
    deletedAtTimestamp: null,
  );

  group('OrganizationModel', () {
    group('fromJson', () {
      test('parses valid JSON with snake_case keys', () {
        final json = {
          'id': 'org-1',
          'name': 'Dragon Martial Arts',
          'slug': 'dragon-martial-arts',
          'subscription_tier': 'free',
          'subscription_status': 'active',
          'max_tournaments_per_month': 2,
          'max_active_brackets': 3,
          'max_participants_per_bracket': 32,
          'max_participants_per_tournament': 100,
          'max_scorers': 2,
          'is_active': true,
          'created_at_timestamp': '2024-01-01T00:00:00.000',
          'updated_at_timestamp': '2024-01-01T00:00:00.000',
          'sync_version': 1,
          'is_deleted': false,
          'is_demo_data': false,
        };

        final model = OrganizationModel.fromJson(json);

        expect(model.id, 'org-1');
        expect(model.name, 'Dragon Martial Arts');
        expect(model.slug, 'dragon-martial-arts');
        expect(model.subscriptionTier, 'free');
        expect(model.subscriptionStatus, 'active');
        expect(model.maxTournamentsPerMonth, 2);
        expect(model.maxActiveBrackets, 3);
        expect(model.maxParticipantsPerBracket, 32);
        expect(model.maxParticipantsPerTournament, 100);
        expect(model.maxScorers, 2);
        expect(model.isActive, true);
        expect(model.syncVersion, 1);
        expect(model.isDeleted, false);
        expect(model.isDemoData, false);
        expect(model.deletedAtTimestamp, isNull);
      });
    });

    group('toJson', () {
      test('serializes to snake_case keys', () {
        final json = testModel.toJson();

        expect(json['id'], 'org-1');
        expect(json['name'], 'Dragon Martial Arts');
        expect(json['subscription_tier'], 'free');
        expect(json['subscription_status'], 'active');
        expect(json['max_tournaments_per_month'], 2);
        expect(json['max_active_brackets'], 3);
        expect(json['max_participants_per_bracket'], 32);
        expect(json['max_participants_per_tournament'], 100);
        expect(json['max_scorers'], 2);
        expect(json['is_active'], true);
        expect(json['sync_version'], 1);
        expect(json['is_deleted'], false);
        expect(json['is_demo_data'], false);
      });
    });

    group('fromDriftEntry', () {
      test('maps OrganizationEntry fields to model fields', () {
        final model = OrganizationModel.fromDriftEntry(testEntry);

        expect(model.id, testEntry.id);
        expect(model.name, testEntry.name);
        expect(model.slug, testEntry.slug);
        expect(model.subscriptionTier, testEntry.subscriptionTier);
        expect(model.subscriptionStatus, testEntry.subscriptionStatus);
        expect(model.maxTournamentsPerMonth, testEntry.maxTournamentsPerMonth);
        expect(model.maxActiveBrackets, testEntry.maxActiveBrackets);
        expect(
          model.maxParticipantsPerBracket,
          testEntry.maxParticipantsPerBracket,
        );
        expect(
          model.maxParticipantsPerTournament,
          testEntry.maxParticipantsPerTournament,
        );
        expect(model.maxScorers, testEntry.maxScorers);
        expect(model.isActive, testEntry.isActive);
        expect(model.createdAtTimestamp, testEntry.createdAtTimestamp);
        expect(model.updatedAtTimestamp, testEntry.updatedAtTimestamp);
        expect(model.syncVersion, testEntry.syncVersion);
        expect(model.isDeleted, testEntry.isDeleted);
        expect(model.isDemoData, testEntry.isDemoData);
        expect(model.deletedAtTimestamp, testEntry.deletedAtTimestamp);
      });
    });

    group('convertToEntity', () {
      test('maps model fields to entity fields with enum parsing', () {
        final entity = testModel.convertToEntity();

        expect(entity.id, 'org-1');
        expect(entity.name, 'Dragon Martial Arts');
        expect(entity.slug, 'dragon-martial-arts');
        expect(entity.subscriptionTier, SubscriptionTier.free);
        expect(entity.subscriptionStatus, SubscriptionStatus.active);
        expect(entity.maxTournamentsPerMonth, 2);
        expect(entity.maxActiveBrackets, 3);
        expect(entity.maxParticipantsPerBracket, 32);
        expect(entity.maxParticipantsPerTournament, 100);
        expect(entity.maxScorers, 2);
        expect(entity.isActive, true);
        expect(entity.createdAt, now);
      });

      test('correctly parses pro tier', () {
        final proModel = testModel.copyWith(subscriptionTier: 'pro');
        final entity = proModel.convertToEntity();
        expect(entity.subscriptionTier, SubscriptionTier.pro);
      });

      test('correctly parses past_due status', () {
        final pastDueModel = testModel.copyWith(subscriptionStatus: 'past_due');
        final entity = pastDueModel.convertToEntity();
        expect(entity.subscriptionStatus, SubscriptionStatus.pastDue);
      });
    });

    group('convertFromEntity', () {
      test('maps entity fields to model fields with enum values', () {
        final entity = OrganizationEntity(
          id: 'org-1',
          name: 'Dragon Martial Arts',
          slug: 'dragon-martial-arts',
          subscriptionTier: SubscriptionTier.free,
          subscriptionStatus: SubscriptionStatus.active,
          maxTournamentsPerMonth: 2,
          maxActiveBrackets: 3,
          maxParticipantsPerBracket: 32,
          maxParticipantsPerTournament: 100,
          maxScorers: 2,
          isActive: true,
          createdAt: now,
        );

        final model = OrganizationModel.convertFromEntity(entity);

        expect(model.id, 'org-1');
        expect(model.name, 'Dragon Martial Arts');
        expect(model.slug, 'dragon-martial-arts');
        expect(model.subscriptionTier, 'free');
        expect(model.subscriptionStatus, 'active');
        expect(model.maxTournamentsPerMonth, 2);
        expect(model.maxActiveBrackets, 3);
        expect(model.maxParticipantsPerBracket, 32);
        expect(model.maxParticipantsPerTournament, 100);
        expect(model.maxScorers, 2);
        expect(model.isActive, true);
        expect(model.createdAtTimestamp, now);
        expect(model.syncVersion, 1);
        expect(model.isDeleted, false);
        expect(model.isDemoData, false);
      });

      test('respects optional parameters', () {
        final entity = testModel.convertToEntity();
        final model = OrganizationModel.convertFromEntity(
          entity,
          syncVersion: 5,
          isDeleted: true,
          isDemoData: true,
        );

        expect(model.syncVersion, 5);
        expect(model.isDeleted, true);
        expect(model.isDemoData, true);
      });
    });

    group('toDriftCompanion', () {
      test('creates OrganizationsCompanion with correct values', () {
        final companion = testModel.toDriftCompanion();

        expect(companion.id.value, 'org-1');
        expect(companion.name.value, 'Dragon Martial Arts');
        expect(companion.slug.value, 'dragon-martial-arts');
        expect(companion.subscriptionTier.value, 'free');
        expect(companion.subscriptionStatus.value, 'active');
        expect(companion.maxTournamentsPerMonth.value, 2);
        expect(companion.maxActiveBrackets.value, 3);
        expect(companion.maxParticipantsPerBracket.value, 32);
        expect(companion.maxParticipantsPerTournament.value, 100);
        expect(companion.maxScorers.value, 2);
        expect(companion.isActive.value, true);
        expect(companion.syncVersion.value, 1);
        expect(companion.isDeleted.value, false);
        expect(companion.isDemoData.value, false);
      });
    });

    group('roundtrip', () {
      test('entity -> model -> entity preserves data', () {
        final entity = testModel.convertToEntity();
        final roundtripModel = OrganizationModel.convertFromEntity(entity);
        final roundtripEntity = roundtripModel.convertToEntity();

        expect(roundtripEntity.id, entity.id);
        expect(roundtripEntity.name, entity.name);
        expect(roundtripEntity.slug, entity.slug);
        expect(roundtripEntity.subscriptionTier, entity.subscriptionTier);
        expect(roundtripEntity.subscriptionStatus, entity.subscriptionStatus);
        expect(
          roundtripEntity.maxTournamentsPerMonth,
          entity.maxTournamentsPerMonth,
        );
        expect(roundtripEntity.maxActiveBrackets, entity.maxActiveBrackets);
        expect(
          roundtripEntity.maxParticipantsPerBracket,
          entity.maxParticipantsPerBracket,
        );
        expect(
          roundtripEntity.maxParticipantsPerTournament,
          entity.maxParticipantsPerTournament,
        );
        expect(roundtripEntity.maxScorers, entity.maxScorers);
        expect(roundtripEntity.isActive, entity.isActive);
        expect(roundtripEntity.createdAt, entity.createdAt);
      });

      test('JSON -> model -> JSON preserves snake_case keys', () {
        final json = testModel.toJson();
        final fromJson = OrganizationModel.fromJson(json);
        final roundtripJson = fromJson.toJson();

        expect(roundtripJson['id'], json['id']);
        expect(roundtripJson['subscription_tier'], json['subscription_tier']);
        expect(
          roundtripJson['subscription_status'],
          json['subscription_status'],
        );
        expect(
          roundtripJson['max_tournaments_per_month'],
          json['max_tournaments_per_month'],
        );
      });
    });
  });
}
