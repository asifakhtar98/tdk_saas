import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_entity.freezed.dart';

/// Immutable domain entity representing an organization.
///
/// An organization is the top-level tenant in the multi-tenancy model.
/// All tournaments, divisions, and participants belong to an organization.
@freezed
class OrganizationEntity with _$OrganizationEntity {
  const factory OrganizationEntity({
    /// Unique identifier (UUID).
    required String id,

    /// Organization display name (e.g., "Dragon Martial Arts").
    required String name,

    /// URL-safe slug, unique across all organizations.
    required String slug,

    /// Subscription tier: 'free', 'pro', 'enterprise'.
    required SubscriptionTier subscriptionTier,

    /// Subscription status: 'active', 'past_due', 'cancelled'.
    required SubscriptionStatus subscriptionStatus,

    /// Max tournaments per month for this tier.
    required int maxTournamentsPerMonth,

    /// Max active brackets for this tier.
    required int maxActiveBrackets,

    /// Max participants per bracket for this tier.
    required int maxParticipantsPerBracket,

    /// Max participants per tournament (soft cap).
    required int maxParticipantsPerTournament,

    /// Max scorers for this tier.
    required int maxScorers,

    /// Whether the organization is active.
    required bool isActive,

    /// When the organization was created.
    required DateTime createdAt,
  }) = _OrganizationEntity;
}

/// Enum for subscription tiers.
enum SubscriptionTier {
  free('free'),
  pro('pro'),
  enterprise('enterprise');

  const SubscriptionTier(this.value);

  final String value;

  /// Parse tier from database string value.
  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }
}

/// Enum for subscription statuses.
enum SubscriptionStatus {
  active('active'),
  pastDue('past_due'),
  cancelled('cancelled');

  const SubscriptionStatus(this.value);

  final String value;

  /// Parse status from database string value.
  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}
