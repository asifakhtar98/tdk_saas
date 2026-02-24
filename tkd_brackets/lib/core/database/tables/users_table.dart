import 'package:drift/drift.dart';
import 'package:tkd_brackets/core/database/tables/base_tables.dart';
import 'package:tkd_brackets/core/database/tables/organizations_table.dart';

/// Users table for authentication and authorization.
///
/// Users belong to exactly one organization and have a role that
/// determines their permissions (RBAC).
@DataClassName('UserEntry')
class Users extends Table with BaseSyncMixin, BaseAuditMixin {
  /// Primary key - matches Supabase auth.users.id (UUID as TEXT).
  TextColumn get id => text()();

  /// Foreign key to organizations table.
  TextColumn get organizationId => text().references(Organizations, #id)();

  /// User's email address, unique across all users.
  TextColumn get email => text().unique()();

  /// Display name shown in UI.
  TextColumn get displayName => text().withLength(min: 1, max: 255)();

  /// Role: 'owner', 'admin', 'scorer', 'viewer'.
  TextColumn get role => text().withDefault(const Constant('viewer'))();

  /// Optional avatar URL (Supabase Storage or external).
  TextColumn get avatarUrl => text().nullable()();

  /// Whether user account is active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Last successful sign-in timestamp.
  DateTimeColumn get lastSignInAtTimestamp => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
