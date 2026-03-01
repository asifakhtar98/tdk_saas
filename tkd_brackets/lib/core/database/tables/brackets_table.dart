import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/divisions_table.dart';

/// Brackets table for tournament bracket structures.
///
/// Each bracket belongs to a division. Multiple brackets per division
/// are possible (e.g., winners + losers for double elimination).
@DataClassName('BracketEntry')
class Brackets extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT.
  TextColumn get id => text()();

  /// Foreign key to divisions table.
  TextColumn get divisionId =>
      text().named('division_id').references(Divisions, #id)();

  /// Bracket type: 'winners', 'losers', 'pool'.
  TextColumn get bracketType => text().named('bracket_type')();

  /// Pool identifier: A-H (nullable, only for pool brackets).
  TextColumn get poolIdentifier => text().named('pool_identifier').nullable()();

  /// Total number of rounds in this bracket.
  IntColumn get totalRounds => integer().named('total_rounds')();

  /// Whether the bracket has been finalized.
  BoolColumn get isFinalized =>
      boolean().named('is_finalized').withDefault(const Constant(false))();

  /// When the bracket was generated (nullable).
  DateTimeColumn get generatedAtTimestamp =>
      dateTime().named('generated_at_timestamp').nullable()();

  /// When the bracket was finalized (nullable).
  DateTimeColumn get finalizedAtTimestamp =>
      dateTime().named('finalized_at_timestamp').nullable()();

  /// JSONB bracket data stored as TEXT in SQLite.
  TextColumn get bracketDataJson =>
      text().named('bracket_data_json').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
