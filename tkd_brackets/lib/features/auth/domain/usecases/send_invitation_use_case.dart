import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/send_invitation_params.dart';
import 'package:uuid/uuid.dart';

/// Use case to send an invitation to join an organization.
///
/// This use case:
/// 1. Validates the authenticated user matches invitedByUserId
/// 2. Validates the inviter has Owner role
/// 3. Validates email format
/// 4. Validates role is not 'owner' (cannot invite as owner)
/// 5. Checks for existing pending invitation for same email+org
/// 6. Creates InvitationEntity with generated token and expiry
/// 7. Persists via InvitationRepository (local + remote)
@injectable
class SendInvitationUseCase
    extends UseCase<InvitationEntity, SendInvitationParams> {
  SendInvitationUseCase(
    this._invitationRepository,
    this._userRepository,
    this._authRepository,
  );

  final InvitationRepository _invitationRepository;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  static const _uuid = Uuid();

  /// Default invitation expiry: 7 days.
  static const int expiryDays = 7;

  /// Simple email regex for client-side validation.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<Either<Failure, InvitationEntity>> call(
    SendInvitationParams params,
  ) async {
    // 1. Security: Verify authenticated user matches params
    final authResult = await _authRepository.getCurrentAuthenticatedUser();

    return authResult.fold(Left.new, (authUser) async {
      if (authUser.id != params.invitedByUserId) {
        return const Left(
          AuthenticationFailure(
            userFriendlyMessage: 'Unauthorized operation.',
            technicalDetails: 'User ID mismatch in SendInvitationParams',
          ),
        );
      }

      // 2. Verify inviter is Owner
      final userResult = await _userRepository.getUserById(
        params.invitedByUserId,
      );
      return userResult.fold(Left.new, (inviter) async {
        if (inviter.role != UserRole.owner) {
          return const Left(
            AuthorizationPermissionDeniedFailure(
              userFriendlyMessage:
                  'Only organization owners can send invitations.',
              technicalDetails: 'Non-owner attempted to send invitation',
            ),
          );
        }

        // 3. Validate email
        final trimmedEmail = params.email.trim().toLowerCase();
        if (trimmedEmail.isEmpty || !_emailRegex.hasMatch(trimmedEmail)) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage: 'Please enter a valid email address.',
              fieldErrors: {'email': 'Invalid email format'},
            ),
          );
        }

        // 4. Cannot invite as owner
        if (params.role == UserRole.owner) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage: 'Cannot assign owner role via invitation.',
              fieldErrors: {
                'role': 'Owner role cannot be assigned via invitation',
              },
            ),
          );
        }

        // 5. Check for existing pending invitation
        final existingResult = await _invitationRepository
            .getExistingPendingInvitation(trimmedEmail, params.organizationId);
        return existingResult.fold(Left.new, (existing) async {
          if (existing != null) {
            return const Left(
              InputValidationFailure(
                userFriendlyMessage:
                    'An invitation has already been sent to this email.',
                fieldErrors: {'email': 'Pending invitation already exists'},
              ),
            );
          }

          // 6. Build invitation entity
          final now = DateTime.now();
          final invitation = InvitationEntity(
            id: _uuid.v4(),
            organizationId: params.organizationId,
            email: trimmedEmail,
            role: params.role,
            invitedBy: params.invitedByUserId,
            status: InvitationStatus.pending,
            token: _uuid.v4(),
            expiresAt: now.add(const Duration(days: expiryDays)),
            createdAt: now,
            updatedAt: now,
          );

          // 7. Persist invitation
          return _invitationRepository.createInvitation(invitation);
        });
      });
    });
  }
}
