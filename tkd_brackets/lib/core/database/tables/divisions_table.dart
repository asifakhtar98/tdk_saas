import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/tournaments_table.dart';

/// Divisions table for tournament competition categories.
///
/// Each division belongs to a tournament and defines eligibility criteria
/// such as age, weight, gender, and belt rank.
@DataClassName('DivisionEntry')
class Divisions extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT for SQLite compatibility.
  TextColumn get id => text()();

  /// Foreign key to tournaments table.
  TextColumn get tournamentId =>
      text().named('tournament_id').references(Tournaments, #id)();

  /// Division display name (e.g., "Cadets -45kg Male").
  TextColumn get name => text()();

  /// Competition category: 'sparring', 'poomsae', 'breaking', 'demo_team'.
  /// Validation enforced at application layer.
  TextColumn get category => text().withDefault(const Constant('sparring'))();

  /// Participant gender for this division: 'male', 'female', 'mixed'.
  /// Validation enforced at application layer.
  TextColumn get gender => text()();

  /// Minimum age eligibility (nullable for no minimum).
  IntColumn get ageMin => integer().named('age_min').nullable()();

  /// Maximum age eligibility (nullable for no maximum).
  IntColumn get ageMax => integer().named('age_max').nullable()();

  /// Minimum weight eligibility in kg (nullable for no minimum).
  RealColumn get weightMinKg => real().named('weight_min_kg').nullable()();

  /// Maximum weight eligibility in kg (nullable for no maximum).
  RealColumn get weightMaxKg => real().named('weight_max_kg').nullable()();

  /// Minimum belt rank eligibility (nullable for no minimum).
  TextColumn get beltRankMin => text().named('belt_rank_min').nullable()();

  /// Maximum belt rank eligibility (nullable for no maximum).
  TextColumn get beltRankMax => text().named('belt_rank_max').nullable()();

  /// Bracket format: 'single_elimination', 'double_elimination',
  /// 'round_robin', 'pool_play'.
  /// Validation enforced at application layer.
  TextColumn get bracketFormat => text()
      .named('bracket_format')
      .withDefault(const Constant('single_elimination'))();

  /// Assigned ring/court number for this division (nullable if not assigned).
  IntColumn get assignedRingNumber =>
      integer().named('assigned_ring_number').nullable()();

  /// Whether this division is combined from other divisions.
  BoolColumn get isCombined =>
      boolean().named('is_combined').withDefault(const Constant(false))();

  /// Display order for sorting divisions.
  IntColumn get displayOrder =>
      integer().named('display_order').withDefault(const Constant(0))();

  /// Division status: 'setup', 'ready', 'in_progress', 'completed'.
  /// Validation enforced at application layer.
  TextColumn get status => text().withDefault(const Constant('setup'))();

  /// Whether this division was created manually by the organizer.
  /// true = custom division (can be edited/deleted)
  /// false = template-derived division (read-only)
  BoolColumn get isCustom =>
      boolean().named('is_custom').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
