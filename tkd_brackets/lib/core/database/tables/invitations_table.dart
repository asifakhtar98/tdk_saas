import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/organizations_table.dart';
import 'package:tkd_brackets/core/database/tables/users_table.dart';

/// Invitations table for team member invitations.
///
/// Tracks pending, accepted, expired, and cancelled invitations
/// for organization team building.
@DataClassName('InvitationEntry')
class Invitations extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key — UUID stored as TEXT.
  TextColumn get id => text()();

  /// Foreign key to organizations table.
  TextColumn get organizationId => text().references(Organizations, #id)();

  /// Email address of the invited user.
  TextColumn get email => text()();

  /// Role to assign on acceptance: 'admin', 'scorer', 'viewer'.
  /// Note: 'owner' role cannot be assigned via invitation.
  TextColumn get role => text().withDefault(const Constant('viewer'))();

  /// Foreign key to users table — who sent this invitation.
  TextColumn get invitedBy => text().references(Users, #id)();

  /// Status: 'pending', 'accepted', 'expired', 'cancelled'.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Unique token for invitation acceptance (UUID).
  TextColumn get token => text().unique()();

  /// When the invitation expires.
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
