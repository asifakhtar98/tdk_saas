import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/organizations_table.dart';
import 'package:tkd_brackets/core/database/tables/users_table.dart';

/// Tournaments table for tournament event management.
///
/// Each tournament belongs to an organization and contains divisions
/// with participants and brackets.
@DataClassName('TournamentEntry')
class Tournaments extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - UUID stored as TEXT for SQLite compatibility.
  TextColumn get id => text()();

  /// Foreign key to organizations table.
  TextColumn get organizationId =>
      text().named('organization_id').references(Organizations, #id)();

  /// Foreign key to users table - who created this tournament (nullable).
  TextColumn get createdByUserId =>
      text().named('created_by_user_id').nullable().references(Users, #id)();

  /// Tournament display name.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// Optional tournament description.
  TextColumn get description => text().nullable()();

  /// Venue name for the tournament location.
  TextColumn get venueName => text().named('venue_name').nullable()();

  /// Venue address for the tournament location.
  TextColumn get venueAddress => text().named('venue_address').nullable()();

  /// Scheduled date for the tournament.
  DateTimeColumn get scheduledDate => dateTime().named('scheduled_date')();

  /// Optional start time for the tournament.
  DateTimeColumn get scheduledStartTime =>
      dateTime().named('scheduled_start_time').nullable()();

  /// Optional end time for the tournament.
  DateTimeColumn get scheduledEndTime =>
      dateTime().named('scheduled_end_time').nullable()();

  /// Federation type: 'wt', 'itf', 'ata', 'custom'.
  /// Validation enforced at application layer.
  TextColumn get federationType =>
      text().named('federation_type').withDefault(const Constant('wt'))();

  /// Tournament status: 'draft', 'registration_open', 'registration_closed',
  /// 'in_progress', 'completed', 'cancelled'.
  /// Validation enforced at application layer.
  TextColumn get status => text().withDefault(const Constant('draft'))();

  /// Whether this tournament is a template for creating new tournaments.
  BoolColumn get isTemplate =>
      boolean().named('is_template').withDefault(const Constant(false))();

  /// Foreign key to template tournament if created from template (nullable).
  TextColumn get templateId =>
      text().named('template_id').nullable().references(Tournaments, #id)();

  /// Number of rings/courts available for the tournament.
  IntColumn get numberOfRings =>
      integer().named('number_of_rings').withDefault(const Constant(1))();

  /// JSON blob for additional tournament settings.
  TextColumn get settingsJson =>
      text().named('settings_json').withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
