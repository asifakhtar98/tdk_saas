import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'invitation_entity.freezed.dart';

/// Immutable domain entity representing a team invitation.
///
/// An invitation allows an organization owner to invite team members
/// with specific roles. Invitations expire after a configurable period.
@freezed
class InvitationEntity with _$InvitationEntity {
  const factory InvitationEntity({
    /// Unique identifier (UUID).
    required String id,

    /// Organization this invitation is for.
    required String organizationId,

    /// Email address of the invitee.
    required String email,

    /// Role assigned to invitee upon acceptance.
    required UserRole role,

    /// User ID of the person who sent the invitation.
    required String invitedBy,

    /// Current status of the invitation.
    required InvitationStatus status,

    /// Unique token for invitation acceptance (UUID).
    required String token,

    /// When the invitation expires.
    required DateTime expiresAt,

    /// When the invitation was created.
    required DateTime createdAt,

    /// When the invitation was last updated.
    required DateTime updatedAt,
  }) = _InvitationEntity;
}

/// Enum for invitation statuses.
enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  expired('expired'),
  cancelled('cancelled');

  const InvitationStatus(this.value);

  final String value;

  /// Parse status from database string value.
  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}
