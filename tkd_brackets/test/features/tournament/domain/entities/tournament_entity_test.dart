import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

void main() {
  group('TournamentEntity', () {
    test('should create TournamentEntity with all required fields', () {
      // Arrange
      final now = DateTime.now();
      final entity = TournamentEntity(
        id: 'test-id',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament',
        scheduledDate: now,
        federationType: FederationType.wt,
        status: TournamentStatus.draft,
        numberOfRings: 2,
        settingsJson: {},
        isTemplate: false,
        createdAt: now,
      );

      // Assert
      expect(entity.id, 'test-id');
      expect(entity.organizationId, 'org-id');
      expect(entity.createdByUserId, 'user-id');
      expect(entity.name, 'Test Tournament');
      expect(entity.scheduledDate, now);
      expect(entity.federationType, FederationType.wt);
      expect(entity.status, TournamentStatus.draft);
      expect(entity.numberOfRings, 2);
      expect(entity.isTemplate, false);
    });

    test('should create TournamentEntity with optional fields', () {
      // Arrange
      final now = DateTime.now();
      final entity = TournamentEntity(
        id: 'test-id',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament',
        scheduledDate: now,
        federationType: FederationType.ata,
        status: TournamentStatus.inProgress,
        description: 'A test tournament',
        venueName: 'Main Hall',
        venueAddress: '123 Main St',
        scheduledStartTime: now,
        scheduledEndTime: now.add(const Duration(hours: 8)),
        templateId: 'template-id',
        numberOfRings: 4,
        settingsJson: {'key': 'value'},
        isTemplate: true,
        createdAt: now,
      );

      // Assert
      expect(entity.description, 'A test tournament');
      expect(entity.venueName, 'Main Hall');
      expect(entity.venueAddress, '123 Main St');
      expect(entity.scheduledStartTime, now);
      expect(entity.templateId, 'template-id');
      expect(entity.settingsJson, {'key': 'value'});
      expect(entity.isTemplate, true);
    });

    test('should support equality comparison', () {
      // Arrange
      final now = DateTime.now();
      final entity1 = TournamentEntity(
        id: 'test-id',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament',
        scheduledDate: now,
        federationType: FederationType.wt,
        status: TournamentStatus.draft,
        numberOfRings: 2,
        settingsJson: {},
        isTemplate: false,
        createdAt: now,
      );
      final entity2 = TournamentEntity(
        id: 'test-id',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament',
        scheduledDate: now,
        federationType: FederationType.wt,
        status: TournamentStatus.draft,
        numberOfRings: 2,
        settingsJson: {},
        isTemplate: false,
        createdAt: now,
      );

      // Assert
      expect(entity1, entity2);
    });

    test('should distinguish different entities', () {
      // Arrange
      final now = DateTime.now();
      final entity1 = TournamentEntity(
        id: 'test-id-1',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament 1',
        scheduledDate: now,
        federationType: FederationType.wt,
        status: TournamentStatus.draft,
        numberOfRings: 2,
        settingsJson: {},
        isTemplate: false,
        createdAt: now,
      );
      final entity2 = TournamentEntity(
        id: 'test-id-2',
        organizationId: 'org-id',
        createdByUserId: 'user-id',
        name: 'Test Tournament 2',
        scheduledDate: now,
        federationType: FederationType.wt,
        status: TournamentStatus.draft,
        numberOfRings: 2,
        settingsJson: {},
        isTemplate: false,
        createdAt: now,
      );

      // Assert
      expect(entity1, isNot(entity2));
    });
  });

  group('FederationType', () {
    test('should have correct values', () {
      expect(FederationType.wt.value, 'wt');
      expect(FederationType.itf.value, 'itf');
      expect(FederationType.ata.value, 'ata');
      expect(FederationType.custom.value, 'custom');
    });

    test('should parse from string correctly', () {
      expect(FederationType.fromString('wt'), FederationType.wt);
      expect(FederationType.fromString('itf'), FederationType.itf);
      expect(FederationType.fromString('ata'), FederationType.ata);
      expect(FederationType.fromString('custom'), FederationType.custom);
    });

    test('should default to wt for unknown values', () {
      expect(FederationType.fromString('unknown'), FederationType.wt);
      expect(FederationType.fromString(''), FederationType.wt);
    });
  });

  group('TournamentStatus', () {
    test('should have correct values', () {
      expect(TournamentStatus.draft.value, 'draft');
      expect(TournamentStatus.registrationOpen.value, 'registration_open');
      expect(TournamentStatus.registrationClosed.value, 'registration_closed');
      expect(TournamentStatus.inProgress.value, 'in_progress');
      expect(TournamentStatus.completed.value, 'completed');
      expect(TournamentStatus.cancelled.value, 'cancelled');
    });

    test('should parse from string correctly', () {
      expect(TournamentStatus.fromString('draft'), TournamentStatus.draft);
      expect(
        TournamentStatus.fromString('registration_open'),
        TournamentStatus.registrationOpen,
      );
      expect(
        TournamentStatus.fromString('registration_closed'),
        TournamentStatus.registrationClosed,
      );
      expect(
        TournamentStatus.fromString('in_progress'),
        TournamentStatus.inProgress,
      );
      expect(
        TournamentStatus.fromString('completed'),
        TournamentStatus.completed,
      );
      expect(
        TournamentStatus.fromString('cancelled'),
        TournamentStatus.cancelled,
      );
    });

    test('should default to draft for unknown values', () {
      expect(TournamentStatus.fromString('unknown'), TournamentStatus.draft);
      expect(TournamentStatus.fromString(''), TournamentStatus.draft);
    });
  });
}
