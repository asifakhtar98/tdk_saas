import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_params.dart';

@injectable
class UpdateUserRoleUseCase extends UseCase<UserEntity, UpdateUserRoleParams> {
  UpdateUserRoleUseCase(
    this._userRepository,
    this._authRepository,
  );

  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, UserEntity>> call(
    UpdateUserRoleParams params,
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
                'User ID mismatch in UpdateUserRoleParams',
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
                  'Only organization owners can change user roles.',
              technicalDetails:
                  'Non-owner attempted to change user role',
            ),
          );
        }

        // 3. Cannot change own role
        if (params.targetUserId == params.requestingUserId) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage:
                  'You cannot change your own role.',
              fieldErrors: {
                'targetUserId': 'Cannot target yourself',
              },
            ),
          );
        }

        // 4. Cannot assign Owner role
        if (params.newRole == UserRole.owner) {
          return const Left(
            InputValidationFailure(
              userFriendlyMessage:
                  'Owner role cannot be assigned to other users.',
              fieldErrors: {
                'newRole':
                    'Owner role cannot be assigned',
              },
            ),
          );
        }

        // 5. Get and validate target user
        final targetResult = await _userRepository.getUserById(
          params.targetUserId,
        );
        return targetResult.fold(Left.new, (targetUser) async {
          // 6. Validate target has organization
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

          // 7. Validate same organization
          if (requester.organizationId != targetUser.organizationId) {
            return const Left(
              AuthorizationPermissionDeniedFailure(
                userFriendlyMessage:
                    'You cannot modify users from other organizations.',
                technicalDetails: 'Organization ID mismatch',
              ),
            );
          }

          // 8. Update target user's role
          final updatedUser = targetUser.copyWith(
            role: params.newRole,
          );
          return _userRepository.updateUser(updatedUser);
        });
      });
    });
  }
}
