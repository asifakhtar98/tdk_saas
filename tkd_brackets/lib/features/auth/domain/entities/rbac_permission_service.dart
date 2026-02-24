import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

@lazySingleton
class RbacPermissionService {
  /// All permissions available in the system.
  static const Set<Permission> _allPermissions = {...Permission.values};

  /// Permissions shared by Owner and Admin (full CRUD minus billing).
  static const Set<Permission> _adminPermissions = {
    Permission.manageOrganization,
    Permission.manageTeamMembers,
    Permission.changeUserRoles,
    Permission.sendInvitations,
    Permission.createTournament,
    Permission.editTournament,
    Permission.deleteTournament,
    Permission.archiveTournament,
    Permission.manageDivisions,
    Permission.manageParticipants,
    Permission.manageBrackets,
    Permission.enterScores,
    Permission.editScores,
    Permission.viewData,
  };

  /// Scorer permissions: score entry + read.
  static const Set<Permission> _scorerPermissions = {
    Permission.enterScores,
    Permission.editScores,
    Permission.viewData,
  };

  /// Viewer permissions: read-only.
  static const Set<Permission> _viewerPermissions = {Permission.viewData};

  /// Static permission matrix mapping roles to their allowed permissions.
  ///
  /// This is the single source of truth for RBAC in the application.
  static const Map<UserRole, Set<Permission>> permissionMatrix = {
    UserRole.owner: _allPermissions,
    UserRole.admin: _adminPermissions,
    UserRole.scorer: _scorerPermissions,
    UserRole.viewer: _viewerPermissions,
  };

  /// Check if the given [role] has the specified [permission].
  ///
  /// Returns `true` if the role is allowed to perform the action,
  /// `false` otherwise.
  bool canPerform(UserRole role, Permission permission) {
    return permissionMatrix[role]?.contains(permission) ?? false;
  }

  /// Assert that the given [role] has the specified [permission].
  ///
  /// Returns [Right(unit)] if allowed, or
  /// [Left(AuthorizationPermissionDeniedFailure)] if denied.
  Either<Failure, Unit> assertPermission(UserRole role, Permission permission) {
    if (canPerform(role, permission)) {
      return const Right(unit);
    }
    return Left(
      AuthorizationPermissionDeniedFailure(
        userFriendlyMessage:
            'You do not have permission to perform this action.',
        technicalDetails:
            'Role ${role.value} lacks ${permission.value} permission',
      ),
    );
  }
}
