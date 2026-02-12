import 'package:flutter_test/flutter_test.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';

void main() {
  group('OrganizationEntity', () {
    test('creates entity with all required fields', () {
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
        createdAt: DateTime(2024, 1, 1),
      );

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
      expect(entity.createdAt, DateTime(2024, 1, 1));
    });

    test('supports equality via freezed', () {
      final entity1 = OrganizationEntity(
        id: 'org-1',
        name: 'Test Org',
        slug: 'test-org',
        subscriptionTier: SubscriptionTier.free,
        subscriptionStatus: SubscriptionStatus.active,
        maxTournamentsPerMonth: 2,
        maxActiveBrackets: 3,
        maxParticipantsPerBracket: 32,
        maxParticipantsPerTournament: 100,
        maxScorers: 2,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final entity2 = OrganizationEntity(
        id: 'org-1',
        name: 'Test Org',
        slug: 'test-org',
        subscriptionTier: SubscriptionTier.free,
        subscriptionStatus: SubscriptionStatus.active,
        maxTournamentsPerMonth: 2,
        maxActiveBrackets: 3,
        maxParticipantsPerBracket: 32,
        maxParticipantsPerTournament: 100,
        maxScorers: 2,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(entity1, equals(entity2));
    });

    test('supports copyWith', () {
      final entity = OrganizationEntity(
        id: 'org-1',
        name: 'Test Org',
        slug: 'test-org',
        subscriptionTier: SubscriptionTier.free,
        subscriptionStatus: SubscriptionStatus.active,
        maxTournamentsPerMonth: 2,
        maxActiveBrackets: 3,
        maxParticipantsPerBracket: 32,
        maxParticipantsPerTournament: 100,
        maxScorers: 2,
        isActive: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = entity.copyWith(
        name: 'Updated Org',
        subscriptionTier: SubscriptionTier.pro,
      );

      expect(updated.name, 'Updated Org');
      expect(updated.subscriptionTier, SubscriptionTier.pro);
      expect(updated.id, 'org-1'); // unchanged
    });
  });

  group('SubscriptionTier', () {
    test('has correct string values', () {
      expect(SubscriptionTier.free.value, 'free');
      expect(SubscriptionTier.pro.value, 'pro');
      expect(SubscriptionTier.enterprise.value, 'enterprise');
    });

    test('fromString parses valid values', () {
      expect(SubscriptionTier.fromString('free'), SubscriptionTier.free);
      expect(SubscriptionTier.fromString('pro'), SubscriptionTier.pro);
      expect(
        SubscriptionTier.fromString('enterprise'),
        SubscriptionTier.enterprise,
      );
    });

    test('fromString defaults to free for unknown values', () {
      expect(SubscriptionTier.fromString('unknown'), SubscriptionTier.free);
      expect(SubscriptionTier.fromString(''), SubscriptionTier.free);
    });
  });

  group('SubscriptionStatus', () {
    test('has correct string values', () {
      expect(SubscriptionStatus.active.value, 'active');
      expect(SubscriptionStatus.pastDue.value, 'past_due');
      expect(SubscriptionStatus.cancelled.value, 'cancelled');
    });

    test('fromString parses valid values', () {
      expect(
        SubscriptionStatus.fromString('active'),
        SubscriptionStatus.active,
      );
      expect(
        SubscriptionStatus.fromString('past_due'),
        SubscriptionStatus.pastDue,
      );
      expect(
        SubscriptionStatus.fromString('cancelled'),
        SubscriptionStatus.cancelled,
      );
    });

    test('fromString defaults to active for unknown values', () {
      expect(
        SubscriptionStatus.fromString('unknown'),
        SubscriptionStatus.active,
      );
      expect(SubscriptionStatus.fromString(''), SubscriptionStatus.active);
    });
  });
}
