import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Immutable domain entity representing a user.
///
/// This entity contains only business-relevant fields and is independent
/// of data layer concerns (serialization, database columns).
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    /// Unique identifier (UUID from Supabase auth.users.id).
    required String id,

    /// User's email address.
    required String email,

    /// Display name shown in UI.
    required String displayName,

    /// Organization this user belongs to.
    required String organizationId,

    /// User's role for RBAC: 'owner', 'admin', 'scorer', 'viewer'.
    required UserRole role,

    /// Whether the user account is active.
    required bool isActive,

    /// When the user was created.
    required DateTime createdAt,

    /// Optional avatar URL.
    String? avatarUrl,

    /// Last successful login timestamp.
    DateTime? lastLoginAt,
  }) = _UserEntity;
}

/// Enum for user roles with RBAC permissions.
enum UserRole {
  owner('owner'),
  admin('admin'),
  scorer('scorer'),
  viewer('viewer');

  const UserRole(this.value);

  final String value;

  /// Parse role from database string value.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.viewer,
    );
  }
}
