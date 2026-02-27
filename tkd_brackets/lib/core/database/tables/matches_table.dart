import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/brackets_table.dart';

/// Matches table for tracking individual bout matchups within a bracket.
///
/// Each match belongs to a bracket and tracks:
/// - Position: round_number + match_number_in_round
/// - Participants: red/blue corner assignments (TKD convention)
/// - Result: winner, status, result_type
/// - Tree navigation: winner_advances_to / loser_advances_to (self-referential FKs)
///
/// Self-referential FKs enable bracket tree traversal:
/// ```text
/// Round 1, Match 1 ──winner──→ Round 2, Match 1
/// Round 1, Match 2 ──winner──→ Round 2, Match 1
///                   ──loser──→ Losers Bracket Match X (double elim only)
/// ```
@DataClassName('MatchEntry')
class Matches extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT.
  TextColumn get id => text()();

  /// Foreign key to brackets table.
  TextColumn get bracketId =>
      text().named('bracket_id').references(Brackets, #id)();

  /// Round number within the bracket (1-indexed).
  IntColumn get roundNumber => integer().named('round_number')();

  /// Match position within the round (1-indexed).
  IntColumn get matchNumberInRound =>
      integer().named('match_number_in_round')();

  /// Red corner participant (nullable - may not be assigned yet).
  TextColumn get participantRedId =>
      text().named('participant_red_id').nullable()();

  /// Blue corner participant (nullable - may not be assigned yet).
  TextColumn get participantBlueId =>
      text().named('participant_blue_id').nullable()();

  /// Winner of the match (nullable - set when match completes).
  TextColumn get winnerId => text().named('winner_id').nullable()();

  /// Self-referential FK: which match the winner advances to.
  TextColumn get winnerAdvancesToMatchId => text()
      .named('winner_advances_to_match_id')
      .nullable()
      .references(Matches, #id)();

  /// Self-referential FK: which match the loser goes to (double elim only).
  TextColumn get loserAdvancesToMatchId => text()
      .named('loser_advances_to_match_id')
      .nullable()
      .references(Matches, #id)();

  /// Scheduled ring number for this match (nullable).
  IntColumn get scheduledRingNumber =>
      integer().named('scheduled_ring_number').nullable()();

  /// Scheduled time for this match (nullable).
  DateTimeColumn get scheduledTime =>
      dateTime().named('scheduled_time').nullable()();

  /// Match lifecycle status: pending, ready, in_progress, completed, cancelled.
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  /// How the match was decided (nullable - set on completion).
  TextColumn get resultType => text().named('result_type').nullable()();

  /// Additional notes about the match.
  TextColumn get notes => text().nullable()();

  /// When the match started (nullable).
  DateTimeColumn get startedAtTimestamp =>
      dateTime().named('started_at_timestamp').nullable()();

  /// When the match completed (nullable).
  DateTimeColumn get completedAtTimestamp =>
      dateTime().named('completed_at_timestamp').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
