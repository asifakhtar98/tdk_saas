import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/divisions_table.dart';

/// Participants table for tournament competitors.
///
/// Each participant belongs to a division and contains personal/athletic data.
/// The schoolOrDojangName field is CRITICAL for dojang separation seeding.
@DataClassName('ParticipantEntry')
class Participants extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT for SQLite compatibility.
  TextColumn get id => text()();

  /// Foreign key to divisions table.
  TextColumn get divisionId =>
      text().named('division_id').references(Divisions, #id)();

  /// Participant's first name.
  TextColumn get firstName => text().named('first_name')();

  /// Participant's last name.
  TextColumn get lastName => text().named('last_name')();

  /// Date of birth for age verification.
  DateTimeColumn get dateOfBirth =>
      dateTime().named('date_of_birth').nullable()();

  /// Gender: 'male', 'female'.
  /// Validation enforced at application layer.
  TextColumn get gender => text().nullable()();

  /// Weight in kilograms.
  RealColumn get weightKg => real().named('weight_kg').nullable()();

  /// School or dojang name - CRITICAL for dojang separation seeding algorithm.
  TextColumn get schoolOrDojangName =>
      text().named('school_or_dojang_name').nullable()();

  /// Belt rank (e.g., "black 1dan", "red").
  TextColumn get beltRank => text().named('belt_rank').nullable()();

  /// Seed number for bracket placement (nullable if not seeded).
  IntColumn get seedNumber => integer().named('seed_number').nullable()();

  /// Registration number from external system.
  TextColumn get registrationNumber =>
      text().named('registration_number').nullable()();

  /// Whether this is a bye slot (placeholder for bracket structure).
  BoolColumn get isBye =>
      boolean().named('is_bye').withDefault(const Constant(false))();

  /// Check-in status: 'pending', 'checked_in', 'no_show', 'withdrawn'.
  /// Validation enforced at application layer.
  TextColumn get checkInStatus =>
      text().named('check_in_status').withDefault(const Constant('pending'))();

  /// When the participant checked in (nullable if not checked in).
  DateTimeColumn get checkInAtTimestamp =>
      dateTime().named('check_in_at_timestamp').nullable()();

  /// Optional photo URL.
  TextColumn get photoUrl => text().named('photo_url').nullable()();

  /// Additional notes about the participant.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
