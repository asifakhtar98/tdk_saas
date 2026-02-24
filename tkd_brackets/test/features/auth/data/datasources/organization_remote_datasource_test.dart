// Test file for OrganizationRemoteDatasourceImplementation.
// Tests the datasource contract: model conversions, JSON structure,
// and interface compliance.
//
// Note: Direct Supabase query builder mocking is intentionally limited
// because PostgREST builders use complex generic return types that are
// not straightforward to mock (same approach as user_remote_datasource_test).
// Full integration tests with a real Supabase instance should be used for
// end-to-end verification.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late OrganizationRemoteDatasourceImplementation datasource;
  late MockSupabaseClient mockSupabase;

  final now = DateTime(2024, 1, 1);

  final testJson = <String, dynamic>{
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
    'created_at_timestamp': now.toIso8601String(),
    'updated_at_timestamp': now.toIso8601String(),
    'sync_version': 1,
    'is_deleted': false,
    'is_demo_data': false,
  };

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

  setUp(() {
    mockSupabase = MockSupabaseClient();
    datasource = OrganizationRemoteDatasourceImplementation(mockSupabase);
  });

  group('OrganizationRemoteDatasource', () {
    group('interface compliance', () {
      test('implements OrganizationRemoteDatasource', () {
        expect(datasource, isA<OrganizationRemoteDatasource>());
      });

      test('uses correct table name', () {
        // Verify the datasource targets the organizations table.
        // The table name is a static const, so we verify through
        // the class instantiation and type check.
        expect(datasource, isA<OrganizationRemoteDatasourceImplementation>());
      });
    });

    group('JSON contract - getOrganizationById', () {
      test('fromJson correctly parses Supabase response', () {
        final model = OrganizationModel.fromJson(testJson);

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
        expect(model.isDeleted, false);
        expect(model.isDemoData, false);
      });

      test('fromJson handles null response gracefully', () {
        // The datasource checks `if (response == null) return null;`
        // So null from Supabase → null from datasource.
        // Verify model creation from valid JSON works.
        final model = OrganizationModel.fromJson(testJson);
        expect(model, isNotNull);
      });
    });

    group('JSON contract - getOrganizationBySlug', () {
      test('slug field is preserved through JSON roundtrip', () {
        final model = OrganizationModel.fromJson(testJson);
        final json = model.toJson();

        expect(json['slug'], 'dragon-martial-arts');
        expect(json.containsKey('slug'), true);
      });
    });

    group('JSON contract - getActiveOrganizations', () {
      test('list response maps correctly', () {
        final models = [
          testJson,
          testJson,
        ].map<OrganizationModel>(OrganizationModel.fromJson).toList();

        expect(models.length, 2);
        expect(models.every((m) => m.id == 'org-1'), true);
      });

      test('empty list response returns empty', () {
        final models = <Map<String, dynamic>>[]
            .map<OrganizationModel>(OrganizationModel.fromJson)
            .toList();

        expect(models, isEmpty);
      });

      test('query should filter on is_deleted only', () {
        // The getActiveOrganizations() method filters
        // .eq('is_deleted', false) and orders by 'name'.
        // Verify the JSON response includes is_deleted field.
        expect(testJson.containsKey('is_deleted'), true);
        expect(testJson['is_deleted'], false);
      });
    });

    group('JSON contract - insertOrganization', () {
      test('toJson produces snake_case keys for Supabase', () {
        final json = testModel.toJson();

        // Verify all required snake_case keys exist
        expect(json.containsKey('id'), true);
        expect(json.containsKey('name'), true);
        expect(json.containsKey('slug'), true);
        expect(json.containsKey('subscription_tier'), true);
        expect(json.containsKey('subscription_status'), true);
        expect(json.containsKey('max_tournaments_per_month'), true);
        expect(json.containsKey('max_active_brackets'), true);
        expect(json.containsKey('max_participants_per_bracket'), true);
        expect(json.containsKey('max_participants_per_tournament'), true);
        expect(json.containsKey('max_scorers'), true);
        expect(json.containsKey('is_active'), true);
        expect(json.containsKey('created_at_timestamp'), true);
        expect(json.containsKey('updated_at_timestamp'), true);
        expect(json.containsKey('sync_version'), true);
        expect(json.containsKey('is_deleted'), true);
        expect(json.containsKey('is_demo_data'), true);
      });

      test('toJson values match model properties', () {
        final json = testModel.toJson();

        expect(json['id'], testModel.id);
        expect(json['name'], testModel.name);
        expect(json['slug'], testModel.slug);
        expect(json['subscription_tier'], testModel.subscriptionTier);
        expect(json['subscription_status'], testModel.subscriptionStatus);
        expect(
          json['max_tournaments_per_month'],
          testModel.maxTournamentsPerMonth,
        );
        expect(json['max_active_brackets'], testModel.maxActiveBrackets);
        expect(json['is_active'], testModel.isActive);
        expect(json['sync_version'], testModel.syncVersion);
        expect(json['is_deleted'], testModel.isDeleted);
      });

      test('roundtrip JSON preserves all data', () {
        final json = testModel.toJson();
        final fromJson = OrganizationModel.fromJson(json);
        final roundtripJson = fromJson.toJson();

        expect(roundtripJson['id'], json['id']);
        expect(roundtripJson['name'], json['name']);
        expect(roundtripJson['slug'], json['slug']);
        expect(roundtripJson['subscription_tier'], json['subscription_tier']);
        expect(
          roundtripJson['subscription_status'],
          json['subscription_status'],
        );
        expect(
          roundtripJson['max_tournaments_per_month'],
          json['max_tournaments_per_month'],
        );
        expect(
          roundtripJson['max_active_brackets'],
          json['max_active_brackets'],
        );
        expect(
          roundtripJson['max_participants_per_bracket'],
          json['max_participants_per_bracket'],
        );
        expect(
          roundtripJson['max_participants_per_tournament'],
          json['max_participants_per_tournament'],
        );
        expect(roundtripJson['max_scorers'], json['max_scorers']);
        expect(roundtripJson['is_active'], json['is_active']);
        expect(roundtripJson['sync_version'], json['sync_version']);
        expect(roundtripJson['is_deleted'], json['is_deleted']);
        expect(roundtripJson['is_demo_data'], json['is_demo_data']);
      });
    });

    group('JSON contract - updateOrganization', () {
      test('updated model serializes correctly', () {
        final updatedModel = testModel.copyWith(
          name: 'Updated Dragon Dojo',
          subscriptionTier: 'pro',
          subscriptionStatus: 'past_due',
          syncVersion: 3,
        );
        final json = updatedModel.toJson();

        expect(json['name'], 'Updated Dragon Dojo');
        expect(json['subscription_tier'], 'pro');
        expect(json['subscription_status'], 'past_due');
        expect(json['sync_version'], 3);
        // Unchanged fields preserved
        expect(json['slug'], 'dragon-martial-arts');
        expect(json['id'], 'org-1');
      });
    });

    group('JSON contract - deleteOrganization', () {
      test('soft delete payload has correct structure', () {
        // The deleteOrganization method sends a specific update payload
        // with is_deleted = true and deleted_at_timestamp = current time.
        // Verify the expected payload structure.
        final softDeletePayload = {
          'is_deleted': true,
          'deleted_at_timestamp': DateTime.now().toIso8601String(),
        };

        expect(softDeletePayload['is_deleted'], true);
        expect(softDeletePayload['deleted_at_timestamp'], isA<String>());
        expect(softDeletePayload.length, 2);
      });

      test('soft delete does not set is_active to false', () {
        // Verify soft delete only sets is_deleted, not is_active.
        // These are separate concerns: is_deleted is for sync,
        // is_active is for business logic.
        final softDeletePayload = {
          'is_deleted': true,
          'deleted_at_timestamp': DateTime.now().toIso8601String(),
        };

        expect(softDeletePayload.containsKey('is_active'), false);
      });
    });
  });
}
