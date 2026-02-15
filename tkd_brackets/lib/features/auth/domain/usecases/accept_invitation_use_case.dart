import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/accept_invitation_params.dart';

/// Use case to accept an invitation to join an organization.
///
/// This use case:
/// 1. Validates the authenticated user matches params.userId
/// 2. Looks up invitation by token
/// 3. Validates invitation is still pending and not expired
/// 4. Updates the user's organizationId and role
/// 5. Marks invitation as accepted
@injectable
class AcceptInvitationUseCase
    extends UseCase<InvitationEntity, AcceptInvitationParams> {
  AcceptInvitationUseCase(
    this._invitationRepository,
    this._userRepository,
    this._authRepository,
  );

  final InvitationRepository _invitationRepository;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, InvitationEntity>> call(
    AcceptInvitationParams params,
  ) async {
    // 1. Security check
    final authResult = await _authRepository.getCurrentAuthenticatedUser();

    return authResult.fold(Left.new, (authUser) async {
      if (authUser.id != params.userId) {
        return const Left(
          AuthenticationFailure(
            userFriendlyMessage: 'Unauthorized operation.',
            technicalDetails: 'User ID mismatch in AcceptInvitationParams',
          ),
        );
      }

      // 2. Look up invitation by token
      final invitationResult = await _invitationRepository.getInvitationByToken(
        params.token,
      );
      return invitationResult.fold(Left.new, (invitation) async {
        // 3. Validate status
        if (invitation.status != InvitationStatus.pending) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage: 'This invitation is no longer valid.',
              fieldErrors: {'token': 'Invitation is not pending'},
            ),
          );
        }

        // 4. Validate not expired
        if (DateTime.now().isAfter(invitation.expiresAt)) {
          // Mark as expired
          final expiredInvitation = invitation.copyWith(
            status: InvitationStatus.expired,
            updatedAt: DateTime.now(),
          );
          await _invitationRepository.updateInvitation(expiredInvitation);

          return const Left(
            InputValidationFailure(
              userFriendlyMessage: 'This invitation has expired.',
              fieldErrors: {'token': 'Invitation expired'},
            ),
          );
        }

        // 5. Update user's organization and role
        final userResult = await _userRepository.getUserById(params.userId);
        return userResult.fold(Left.new, (user) async {
          final updatedUser = user.copyWith(
            organizationId: invitation.organizationId,
            role: invitation.role,
          );
          final updateResult = await _userRepository.updateUser(updatedUser);

          return updateResult.fold(Left.new, (_) async {
            // 6. Mark invitation as accepted
            final acceptedInvitation = invitation.copyWith(
              status: InvitationStatus.accepted,
              updatedAt: DateTime.now(),
            );
            return _invitationRepository.updateInvitation(acceptedInvitation);
          });
        });
      });
    });
  }
}
