import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';

/// Organizations table for multi-tenant data isolation.
///
/// Each organization represents a dojang or tournament organizing body.
/// Subscription limits are enforced at the organization level.
@DataClassName('OrganizationEntry')
class Organizations extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT for SQLite compatibility.
  TextColumn get id => text()();

  /// Organization display name (e.g., "Dragon Martial Arts").
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// URL-safe slug, unique across all organizations.
  TextColumn get slug => text().unique()();

  /// Subscription tier: 'free', 'pro', 'enterprise'.
  TextColumn get subscriptionTier =>
      text().withDefault(const Constant('free'))();

  /// Subscription status: 'active', 'past_due', 'cancelled'.
  TextColumn get subscriptionStatus =>
      text().withDefault(const Constant('active'))();

  /// Free tier: 2 tournaments per month.
  IntColumn get maxTournamentsPerMonth =>
      integer().withDefault(const Constant(2))();

  /// Free tier: 3 active brackets.
  IntColumn get maxActiveBrackets => integer().withDefault(const Constant(3))();

  /// Free tier: 32 participants per bracket.
  IntColumn get maxParticipantsPerBracket =>
      integer().withDefault(const Constant(32))();

  /// Soft cap for performance.
  IntColumn get maxParticipantsPerTournament =>
      integer().withDefault(const Constant(100))();

  /// Free tier: 2 scorers.
  IntColumn get maxScorers => integer().withDefault(const Constant(2))();

  /// Whether organization is active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
