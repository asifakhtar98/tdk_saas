// ignore_for_file: document_ignores

import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/tournament/data/models/tournament_model.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

void main() {
  group('TournamentModel', () {
    final now = DateTime.now();

    test('should create TournamentModel with all fields', () {
      // Arrange & Act
      final model = TournamentModel(
        id: 'test-id',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament',
        scheduledDate: now,
        federationType: 'wt',
        status: 'draft',
        isTemplate: false,
        numberOfRings: 2,
        settingsJson: {},
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      // Assert
      expect(model.id, 'test-id');
      expect(model.organizationId, 'org-id');
      expect(model.federationType, 'wt');
      expect(model.status, 'draft');
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final model = TournamentModel(
        id: 'test-id',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament',
        scheduledDate: now,
        federationType: 'wt',
        status: 'draft',
        isTemplate: false,
        numberOfRings: 2,
        settingsJson: <String, dynamic>{},
        syncVersion: 1,
        isDeleted: false,
        isDemoData: false,
        createdAtTimestamp: now,
        updatedAtTimestamp: now,
      );

      // Act
      final json = model.toJson();

      // Assert
      expect(json['id'], 'test-id');
      expect(json['federation_type'], 'wt');
      expect(json['status'], 'draft');
      expect(json['is_template'], false);
    });

    group('Entity Conversions', () {
      test('should convert from entity correctly', () {
        // Arrange
        final entity = TournamentEntity(
          id: 'test-id',
          organizationId: 'org-id',
          createdByUserId: 'user-id',
          name: 'Test Tournament',
          scheduledDate: now,
          federationType: FederationType.ata,
          status: TournamentStatus.completed,
          description: 'A test',
          venueName: 'Main Hall',
          numberOfRings: 3,
          settingsJson: <String, dynamic>{'test': 'data'},
          isTemplate: true,
          createdAt: now,
          updatedAtTimestamp: now,
        );

        // Act
        final model = TournamentModel.convertFromEntity(entity);

        // Assert
        expect(model.id, 'test-id');
        expect(model.federationType, 'ata');
        expect(model.status, 'completed');
        expect(model.isTemplate, true);
        expect(model.numberOfRings, 3);
      });

      test('should convert to entity correctly', () {
        // Arrange
        final model = TournamentModel(
          id: 'test-id',
          organizationId: 'org-id',
          createdByUserId: 'user-id',
          name: 'Test Tournament',
          scheduledDate: now,
          federationType: 'custom',
          status: 'active',
          isTemplate: false,
          numberOfRings: 2,
          settingsJson: <String, dynamic>{},
          syncVersion: 1,
          isDeleted: false,
          isDemoData: false,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        // Act
        final entity = model.convertToEntity();

        // Assert
        expect(entity.id, 'test-id');
        expect(entity.federationType, FederationType.custom);
        expect(entity.status, TournamentStatus.active);
        expect(entity.isTemplate, false);
      });

      test('should round-trip conversion preserve data', () {
        // Arrange
        final original = TournamentEntity(
          id: 'test-id',
          organizationId: 'org-id',
          createdByUserId: 'user-id',
          name: 'Test Tournament',
          scheduledDate: now,
          federationType: FederationType.wt,
          status: TournamentStatus.draft,
          numberOfRings: 2,
          settingsJson: <String, dynamic>{},
          isTemplate: false,
          createdAt: now,
          updatedAtTimestamp: now,
        );

        // Act
        final model = TournamentModel.convertFromEntity(original);
        final converted = model.convertToEntity();

        // Assert
        expect(converted.id, original.id);
        expect(converted.name, original.name);
        expect(converted.federationType, original.federationType);
        expect(converted.status, original.status);
      });
    });

    group('syncVersion and timestamps', () {
      test('should use provided syncVersion', () {
        final model = TournamentModel.convertFromEntity(
          TournamentEntity(
            id: 'id',
            organizationId: 'org',
            createdByUserId: 'user',
            name: 'Test',
            scheduledDate: now,
            federationType: FederationType.wt,
            status: TournamentStatus.draft,
            numberOfRings: 1,
            settingsJson: <String, dynamic>{},
            isTemplate: false,
            createdAt: now,
            updatedAtTimestamp: now,
          ),
          syncVersion: 5,
        );

        expect(model.syncVersion, 5);
      });

      test('should use provided isDeleted flag', () {
        final model = TournamentModel.convertFromEntity(
          TournamentEntity(
            id: 'id',
            organizationId: 'org',
            createdByUserId: 'user',
            name: 'Test',
            scheduledDate: now,
            federationType: FederationType.wt,
            status: TournamentStatus.draft,
            numberOfRings: 1,
            settingsJson: <String, dynamic>{},
            isTemplate: false,
            createdAt: now,
            updatedAtTimestamp: now,
          ),
          isDeleted: true,
        );

        expect(model.isDeleted, true);
      });

      test('should use provided isDemoData flag', () {
        final model = TournamentModel.convertFromEntity(
          TournamentEntity(
            id: 'id',
            organizationId: 'org',
            createdByUserId: 'user',
            name: 'Test',
            scheduledDate: now,
            federationType: FederationType.wt,
            status: TournamentStatus.draft,
            numberOfRings: 1,
            settingsJson: <String, dynamic>{},
            isTemplate: false,
            createdAt: now,
            updatedAtTimestamp: now,
          ),
          isDemoData: true,
        );

        expect(model.isDemoData, true);
      });
    });
  });
}
