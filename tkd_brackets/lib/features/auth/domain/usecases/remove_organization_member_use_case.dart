import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_params.dart';

@injectable
class RemoveOrganizationMemberUseCase
    extends UseCase<Unit, RemoveOrganizationMemberParams> {
  RemoveOrganizationMemberUseCase(
    this._userRepository,
    this._authRepository,
  );

  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, Unit>> call(
    RemoveOrganizationMemberParams params,
  ) async {
    // 1. Security: Verify authenticated user matches params
    final authResult =
        await _authRepository.getCurrentAuthenticatedUser();

    return authResult.fold(Left.new, (authUser) async {
      if (authUser.id != params.requestingUserId) {
        return const Left(
          AuthenticationFailure(
            userFriendlyMessage: 'Unauthorized operation.',
            technicalDetails:
                'User ID mismatch in RemoveOrganizationMemberParams',
          ),
        );
      }

      // 2. Verify requesting user is Owner
      final requesterResult = await _userRepository.getUserById(
        params.requestingUserId,
      );
      return requesterResult.fold(Left.new, (requester) async {
        if (requester.role != UserRole.owner) {
          return const Left(
            AuthorizationPermissionDeniedFailure(
              userFriendlyMessage:
                  'Only organization owners can remove team members.',
              technicalDetails:
                  'Non-owner attempted to remove team member',
            ),
          );
        }

        // 3. Cannot remove self
        if (params.targetUserId == params.requestingUserId) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage:
                  'You cannot remove yourself from the organization.',
              fieldErrors: {
                'targetUserId': 'Cannot target yourself',
              },
            ),
          );
        }

        // 4. Get and validate target user
        final targetResult = await _userRepository.getUserById(
          params.targetUserId,
        );
        return targetResult.fold(Left.new, (targetUser) async {
          // 5. Validate target has organization
          if (targetUser.organizationId.isEmpty) {
            return const Left(
              InputValidationFailure(
                userFriendlyMessage:
                    'This user does not belong to any organization.',
                fieldErrors: {
                  'targetUserId': 'User has no organization',
                },
              ),
            );
          }

          // 6. Validate same organization
          if (requester.organizationId != targetUser.organizationId) {
            return const Left(
              AuthorizationPermissionDeniedFailure(
                userFriendlyMessage:
                    'You cannot modify users from other organizations.',
                technicalDetails: 'Organization ID mismatch',
              ),
            );
          }

          // 7. Clear target user's organization and reset role
          final updatedUser = targetUser.copyWith(
            organizationId: '',
            role: UserRole.viewer,
          );
          final updateResult =
              await _userRepository.updateUser(updatedUser);

          return updateResult.fold(
            Left.new,
            (_) => const Right(unit),
          );
        });
      });
    });
  }
}
