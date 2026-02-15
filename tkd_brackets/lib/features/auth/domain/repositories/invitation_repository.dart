import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';

/// Repository interface for invitation operations.
abstract class InvitationRepository {
  /// Create a new invitation (local + remote sync).
  Future<Either<Failure, InvitationEntity>> createInvitation(
    InvitationEntity invitation,
  );

  /// Get invitation by token.
  Future<Either<Failure, InvitationEntity>> getInvitationByToken(String token);

  /// Get pending invitations for an organization.
  Future<Either<Failure, List<InvitationEntity>>>
  getPendingInvitationsForOrganization(String organizationId);

  /// Update invitation status (e.g., accepted, cancelled).
  Future<Either<Failure, InvitationEntity>> updateInvitation(
    InvitationEntity invitation,
  );

  /// Check if a pending invitation already exists for email+org.
  Future<Either<Failure, InvitationEntity?>> getExistingPendingInvitation(
    String email,
    String organizationId,
  );
}
