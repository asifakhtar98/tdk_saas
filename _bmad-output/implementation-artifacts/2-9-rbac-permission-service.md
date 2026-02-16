# Story 2.9: RBAC Permission Service

## Epic: Epic 2 — Authentication & Organization
## Story ID: 2.9
## Title: RBAC Permission Service
## Status: ready-for-dev

---

## Story Description

**As a** developer,
**I want** a permission service that enforces role-based access control,
**So that** users can only perform actions allowed by their role (FR56, FR57).

## Acceptance Criteria

> **AC1:** `RbacPermissionService` is implemented in the domain layer as a `@lazySingleton` service with a static permission matrix for all four roles (Owner, Admin, Scorer, Viewer)
>
> **AC2:** Permission matrix defines granular `Permission` enum values covering: organizations, tournaments, divisions, participants, scoring, brackets, team management, billing, and read-only access
>
> **AC3:** `canPerform(UserRole role, Permission permission)` method returns `bool` to check if a role has a specific permission
>
> **AC4:** `assertPermission(UserRole role, Permission permission)` method returns `Either<Failure, Unit>` — returns `Right(unit)` on success, `Left(AuthorizationPermissionDeniedFailure)` on failure
>
> **AC5:** Permission assignments match architecture specification:
>   - Owner: all permissions (full CRUD, billing, delete org)
>   - Admin: all permissions except billing AND delete organization
>   - Scorer: score entry, match updates, and read-only access only
>   - Viewer: read-only access only
>
> **AC6:** `UpdateUserRoleUseCase` is implemented as `UseCase<UserEntity, UpdateUserRoleParams>` — allows Owner to change roles (FR57). Only Owner can change roles. Cannot change own role. Cannot assign Owner role. Verifies requester and target belong to same organization.
>
> **AC7:** `UpdateUserRoleParams` freezed class is created with required `targetUserId` (String), `newRole` (UserRole), and `requestingUserId` (String) fields
>
> **AC8:** `RemoveOrganizationMemberUseCase` is implemented as `UseCase<Unit, RemoveOrganizationMemberParams>` — allows Owner to remove team members (FR58). Cannot remove self. Verifies requester and target belong to same organization. Uses `UserRepository.updateUser()` to clear orgId and set role to viewer.
>
> **AC9:** `RemoveOrganizationMemberParams` freezed class is created with required `targetUserId` (String) and `requestingUserId` (String) fields
>
> **AC10:** All three use cases/services verify authenticated user matches `requestingUserId` via `AuthRepository.getCurrentAuthenticatedUser()` — consistent with `SendInvitationUseCase` and `AcceptInvitationUseCase` security pattern
>
> **AC11:** Unit tests verify permission checks for all four roles against all permissions (100% matrix coverage)
>
> **AC12:** Unit tests verify `UpdateUserRoleUseCase`: successful role change, non-owner rejection, self-change rejection, owner-role assignment rejection, auth mismatch rejection, and repository failure propagation
>
> **AC13:** Unit tests verify `RemoveOrganizationMemberUseCase`: successful removal, non-owner rejection, self-removal rejection, auth mismatch rejection, and repository failure propagation
>
> **AC14:** All new exports are added to `auth.dart` barrel file in correct sections and alphabetical order
>
> **AC15:** `flutter analyze` passes with zero new errors
>
> **AC16:** `build_runner` generates code successfully for new freezed params classes

---

## Tasks / Subtasks

- [ ] Task 1: Create `Permission` enum (AC: 2)
  - [ ] 1.1: Define enum in `domain/entities/permission.dart`
  - [ ] 1.2: Add all permission values with string representations
- [ ] Task 2: Create `RbacPermissionService` (AC: 1, 3, 4, 5)
  - [ ] 2.1: Define static permission matrix as `Map<UserRole, Set<Permission>>`
  - [ ] 2.2: Implement `canPerform()` method
  - [ ] 2.3: Implement `assertPermission()` method
- [ ] Task 3: Create `UpdateUserRoleParams` (AC: 7, 16)
  - [ ] 3.1: Define freezed params class
- [ ] Task 4: Create `UpdateUserRoleUseCase` (AC: 6, 10)
  - [ ] 4.1: Implement auth check, owner verification, validation, and role update
- [ ] Task 5: Create `RemoveOrganizationMemberParams` (AC: 9, 16)
  - [ ] 5.1: Define freezed params class
- [ ] Task 6: Create `RemoveOrganizationMemberUseCase` (AC: 8, 10)
  - [ ] 6.1: Implement auth check, owner verification, validation, and user removal
- [ ] Task 7: Write unit tests for `RbacPermissionService` (AC: 11)
  - [ ] 7.1: Verify Owner has all 17 permissions via Permission.values
  - [ ] 7.2: Verify Admin has all except billing and deleteOrganization
  - [ ] 7.3: Verify Scorer has only enterScores, editScores, viewData
  - [ ] 7.4: Verify Viewer has only viewData
  - [ ] 7.5: Verify permission matrix structure is complete
  - [ ] 7.6: Test `assertPermission()` returns correct Either values
- [ ] Task 8: Write unit tests for `UpdateUserRoleUseCase` (AC: 12)
  - [ ] 8.1: Test successful role change
  - [ ] 8.2: Test non-owner rejection
  - [ ] 8.3: Test self-change rejection
  - [ ] 8.4: Test owner-role assignment rejection
  - [ ] 8.5: Test auth mismatch rejection
  - [ ] 8.6: Test organization mismatch rejection
  - [ ] 8.7: Test empty organization rejection
  - [ ] 8.8: Test repository failure propagation
- [ ] Task 9: Write unit tests for `RemoveOrganizationMemberUseCase` (AC: 13)
  - [ ] 9.1: Test successful removal
  - [ ] 9.2: Test non-owner rejection
  - [ ] 9.3: Test self-removal rejection
  - [ ] 9.4: Test auth mismatch rejection
  - [ ] 9.5: Test organization mismatch rejection
  - [ ] 9.6: Test empty organization rejection
  - [ ] 9.7: Test repository failure propagation
- [ ] Task 10: Update `auth.dart` barrel file (AC: 14)
  - [ ] 10.1: Add all new exports in correct sections
- [ ] Task 11: Run `build_runner` (AC: 16)
- [ ] Task 12: Run `flutter analyze` (AC: 15)
- [ ] Task 13: Run full test suite — regression check

---

## Dev Notes

### Task 1: Create `Permission` Enum — AC2

**File:** `lib/features/auth/domain/entities/permission.dart`

```dart
/// Granular permissions for RBAC enforcement.
///
/// Each value represents a specific action that can be checked
/// against a [UserRole] via [RbacPermissionService].
enum Permission {
  // Organization management
  manageOrganization('manage_organization'),
  deleteOrganization('delete_organization'),

  // Team management
  manageTeamMembers('manage_team_members'),
  changeUserRoles('change_user_roles'),
  sendInvitations('send_invitations'),

  // Tournament management
  createTournament('create_tournament'),
  editTournament('edit_tournament'),
  deleteTournament('delete_tournament'),
  archiveTournament('archive_tournament'),

  // Division management
  manageDivisions('manage_divisions'),

  // Participant management
  manageParticipants('manage_participants'),

  // Bracket management
  manageBrackets('manage_brackets'),

  // Scoring
  enterScores('enter_scores'),
  editScores('edit_scores'),

  // Billing
  manageBilling('manage_billing'),

  // Read-only
  viewData('view_data');

  const Permission(this.value);

  final String value;
}
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **Naming:** Enum values use `camelCase` per Dart conventions. The `value` string uses `snake_case` for potential serialization/logging.
2. **Granularity:** Permissions are grouped by resource area. This matches the architecture's FR mapping and the permission matrix in architecture.md.
3. **This is NOT a freezed class.** Simple enums do not use freezed — same pattern as `UserRole` and `InvitationStatus`.

**Permission Usage by Future Epic:**

| Permission                                                                    | Used By (Future Implementation)                  |
| ----------------------------------------------------------------------------- | ------------------------------------------------ |
| `manageOrganization`, `deleteOrganization`                                    | Epic 2 completion - organization settings        |
| `manageTeamMembers`, `changeUserRoles`, `sendInvitations`                     | Epic 2 completion - team management UI           |
| `createTournament`, `editTournament`, `deleteTournament`, `archiveTournament` | Epic 3: Tournament Management                    |
| `manageDivisions`                                                             | Epic 3: Division Management                      |
| `manageParticipants`                                                          | Epic 4: Participant Management                   |
| `manageBrackets`                                                              | Epic 5: Bracket Generation                       |
| `enterScores`, `editScores`                                                   | Epic 6: Scoring System                           |
| `manageBilling`                                                               | Epic 8: Billing & Subscriptions                  |
| `viewData`                                                                    | All epics - read-only access across all features |

---

### Task 2: Create `RbacPermissionService` — AC1, AC3, AC4, AC5

**File:** `lib/features/auth/domain/entities/rbac_permission_service.dart`

> **NOTE:** This is placed in `domain/entities/` because it is a pure domain service with no external dependencies. It is a stateless service that operates purely on domain types (`UserRole`, `Permission`). It does NOT depend on repositories or data layer. If it needed repositories, it would be a use case instead.

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

/// Service that enforces role-based access control (RBAC).
///
/// Provides a static permission matrix mapping [UserRole] to allowed
/// [Permission] sets. Used by use cases and BLoCs to check/enforce
/// permissions before executing privileged operations.
///
/// Permission hierarchy (from architecture.md):
/// - **Owner:** Full CRUD, billing, delete org
/// - **Admin:** Full CRUD except billing
/// - **Scorer:** Score entry, match updates only
/// - **Viewer:** Read-only access
@lazySingleton
class RbacPermissionService {
  /// All permissions available in the system.
  static const Set<Permission> _allPermissions = Permission.values;

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
  static const Set<Permission> _viewerPermissions = {
    Permission.viewData,
  };

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
  Either<Failure, Unit> assertPermission(
    UserRole role,
    Permission permission,
  ) {
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
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **`@lazySingleton` not `@injectable`**: This is a stateless service, not a use case. It should be a singleton — one instance shared across the app. Use cases are `@injectable` (new instance per call). DI manages instantiation — do NOT manually instantiate with `const RbacPermissionService()`.
2. **Static `permissionMatrix`**: The matrix is `static const` so it can also be used without DI if needed (e.g., in tests).
3. **`Set<Permission>` for O(1) lookups**: Using `Set` ensures `contains()` is O(1) instead of O(n) for lists.
4. **Owner gets `_allPermissions`** which is `Permission.values` — this automatically includes ANY future permissions added to the enum, ensuring Owner always has full access.
5. **Admin does NOT have `deleteOrganization` or `manageBilling`**: This matches architecture.md which states: "Admin: Full CRUD except billing" and only Owner can "delete org".
6. **`unit` (lowercase)** from fpdart, NOT `Unit()`. This is the correct fpdart pattern used throughout the codebase.

**When to Use RbacPermissionService:**

- **BLoC/UI Layer:** Use `canPerform()` for conditional UI rendering (show/hide buttons, enable/disable features)
- **General Use Cases:** Use `assertPermission()` when implementing features that require granular permission checks
- **Owner-Only Use Cases:** Direct role checks (`user.role == UserRole.owner`) are acceptable when the entire use case is Owner-only by design (like `UpdateUserRoleUseCase`, `RemoveOrganizationMemberUseCase`). These check role identity, not permissions.
- **Future Integration:** When Epic 3+ features are implemented, their use cases will call `RbacPermissionService.assertPermission()` to enforce permission-based access control

---

### Task 3: Create `UpdateUserRoleParams` — AC7, AC16

**File:** `lib/features/auth/domain/usecases/update_user_role_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

part 'update_user_role_params.freezed.dart';

/// Parameters for the [UpdateUserRoleUseCase].
///
/// [targetUserId] — The user whose role will be changed.
/// [newRole] — The new role to assign.
/// [requestingUserId] — The authenticated user performing the change (must be Owner).
@freezed
class UpdateUserRoleParams with _$UpdateUserRoleParams {
  const factory UpdateUserRoleParams({
    /// The ID of the user whose role is being changed.
    required String targetUserId,

    /// The new role to assign to the target user.
    required UserRole newRole,

    /// The ID of the authenticated user making the request.
    required String requestingUserId,
  }) = _UpdateUserRoleParams;
}
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **`UserRole` is imported from `user_entity.dart`** — the enum is defined there, NOT duplicated.
2. **Three fields required**: `targetUserId`, `newRole`, `requestingUserId`. All three are needed for the security checks.
3. **`part` directive MUST use `.freezed.dart`** extension — NOT `.g.dart`. Freezed generates `.freezed.dart` files.

---

### Task 4: Create `UpdateUserRoleUseCase` — AC6, AC10

**File:** `lib/features/auth/domain/usecases/update_user_role_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_params.dart';

/// Use case to update a user's role within an organization.
///
/// This use case:
/// 1. Validates the authenticated user matches requestingUserId
/// 2. Validates the requesting user has Owner role
/// 3. Validates target user is not the requesting user (cannot change own role)
/// 4. Validates the new role is not Owner (cannot assign owner via this action)
/// 5. Validates both users belong to the same organization
/// 6. Validates target user has a valid organization
/// 7. Updates the target user's role via UserRepository
@injectable
class UpdateUserRoleUseCase
    extends UseCase<UserEntity, UpdateUserRoleParams> {
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
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **`@injectable` NOT `@lazySingleton`**: Use cases are always `@injectable` — new instance per call.
2. **Auth check pattern**: Exactly matches `SendInvitationUseCase` and `AcceptInvitationUseCase` — call `_authRepository.getCurrentAuthenticatedUser()` and compare with params ID.
3. **Nested `fold` pattern**: Same pattern used in `CreateOrganizationUseCase` and `SendInvitationUseCase`. Each step can fail, so we chain `fold` calls.
4. **Owner check reads from UserRepository**: We don't trust the auth state alone — we verify the requester's role from the user record in the database.
5. **Organization validation is CRITICAL**: Steps 6-7 prevent cross-organization attacks. An Owner of Org A cannot modify users in Org B even if they know the user IDs.
6. **Empty organizationId check**: Prevents edge cases with orphaned users who don't belong to any organization.
7. **`copyWith` on UserEntity**: UserEntity is freezed, so `copyWith` is auto-generated. We only update `role`.
8. **Return type is `UserEntity`**: Returns the updated target user entity on success.

---

### Task 5: Create `RemoveOrganizationMemberParams` — AC9, AC16

**File:** `lib/features/auth/domain/usecases/remove_organization_member_params.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'remove_organization_member_params.freezed.dart';

/// Parameters for the [RemoveOrganizationMemberUseCase].
///
/// [targetUserId] — The user to remove from the organization.
/// [requestingUserId] — The authenticated user performing the removal (must be Owner).
@freezed
class RemoveOrganizationMemberParams
    with _$RemoveOrganizationMemberParams {
  const factory RemoveOrganizationMemberParams({
    /// The ID of the user being removed from the organization.
    required String targetUserId,

    /// The ID of the authenticated user making the request.
    required String requestingUserId,
  }) = _RemoveOrganizationMemberParams;
}
```

---

### Task 6: Create `RemoveOrganizationMemberUseCase` — AC8, AC10

**File:** `lib/features/auth/domain/usecases/remove_organization_member_use_case.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_params.dart';

/// Use case to remove a user from an organization.
///
/// This use case:
/// 1. Validates the authenticated user matches requestingUserId
/// 2. Validates the requesting user has Owner role
/// 3. Validates the target user is not the requester (cannot remove self)
/// 4. Validates both users belong to the same organization
/// 5. Validates target user has a valid organization
/// 6. Clears the target user's organizationId and sets role to viewer
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
```

**CRITICAL IMPLEMENTATION NOTES:**

1. **Return type is `Unit`**: Removal doesn't need to return the user — `Unit` is sufficient to signal success. This matches `deleteUser` and `signOut` return patterns.
2. **Organization validation is CRITICAL**: Steps 5-6 prevent cross-organization attacks. An Owner of Org A cannot remove users from Org B even if they know the user IDs.
3. **Empty organizationId check**: Prevents edge cases where the user is already orphaned or was never assigned to an organization.
4. **`organizationId: ''`**: Setting to empty string — same pattern as the initial user state before organization creation. Do NOT use `null` because `organizationId` is `required String` in `UserEntity` (not nullable).
5. **`role: UserRole.viewer`**: Reset to viewer (lowest privilege) — the user becomes unaffiliated, so viewer is the safe default.
6. **This does NOT call `UserRepository.deleteUser()`**: Removing from org is NOT the same as deleting the user. The user's account persists — they just lose organization access and need a new invitation to join.

---

### Task 10: Update Auth Barrel File — AC14

**File:** `lib/features/auth/auth.dart`

Add these exports in the correct sections, maintaining alphabetical order:

**In `// Domain - Entities` section, add:**
```dart
export 'domain/entities/permission.dart';
export 'domain/entities/rbac_permission_service.dart';
```

Insert in alphabetical order:
```dart
// Domain - Entities
export 'domain/entities/invitation_entity.dart';
export 'domain/entities/organization_entity.dart';
export 'domain/entities/permission.dart';
export 'domain/entities/rbac_permission_service.dart';
export 'domain/entities/user_entity.dart';
```

**In `// Domain - Use Cases` section, add:**
```dart
export 'domain/usecases/remove_organization_member_params.dart';
export 'domain/usecases/remove_organization_member_use_case.dart';
export 'domain/usecases/update_user_role_params.dart';
export 'domain/usecases/update_user_role_use_case.dart';
```

Insert in alphabetical order:
```dart
// Domain - Use Cases
export 'domain/usecases/accept_invitation_params.dart';
export 'domain/usecases/accept_invitation_use_case.dart';
export 'domain/usecases/create_organization_params.dart';
export 'domain/usecases/create_organization_use_case.dart';
export 'domain/usecases/get_current_user_use_case.dart';
export 'domain/usecases/remove_organization_member_params.dart';
export 'domain/usecases/remove_organization_member_use_case.dart';
export 'domain/usecases/send_invitation_params.dart';
export 'domain/usecases/send_invitation_use_case.dart';
export 'domain/usecases/sign_in_with_email_params.dart';
export 'domain/usecases/sign_in_with_email_use_case.dart';
export 'domain/usecases/sign_out_use_case.dart';
export 'domain/usecases/sign_up_with_email_params.dart';
export 'domain/usecases/sign_up_with_email_use_case.dart';
export 'domain/usecases/update_user_role_params.dart';
export 'domain/usecases/update_user_role_use_case.dart';
export 'domain/usecases/verify_magic_link_params.dart';
export 'domain/usecases/verify_magic_link_use_case.dart';
```

---

### Task 11: Run `build_runner` — AC16

```bash
cd tkd_brackets && dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `update_user_role_params.freezed.dart`
- `remove_organization_member_params.freezed.dart`
- Updated `injection.config.dart` (auto-registers `RbacPermissionService` as lazySingleton, `UpdateUserRoleUseCase` and `RemoveOrganizationMemberUseCase` as injectable)

---

### Task 12: Run `flutter analyze` — AC15

```bash
cd tkd_brackets && flutter analyze
```

Must pass with zero new errors from the code in this story.

---

### Task 13: Run full test suite — Regression check

```bash
cd tkd_brackets && flutter test
```

All existing tests must continue to pass. Zero new failures allowed.

---

### Task 7: Write Unit Tests for `RbacPermissionService` — AC11

#### Test File: `test/features/auth/domain/entities/rbac_permission_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/permission.dart';
import 'package:tkd_brackets/features/auth/domain/entities/rbac_permission_service.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';

void main() {
  late RbacPermissionService service;

  setUp(() {
    service = RbacPermissionService();
  });

  group('RbacPermissionService', () {
    group('Owner permissions', () {
      test('has all permissions', () {
        for (final permission in Permission.values) {
          expect(
            service.canPerform(UserRole.owner, permission),
            isTrue,
            reason:
                'Owner should have ${permission.value}',
          );
        }
      });
    });

    group('Admin permissions', () {
      test('has all permissions except billing and delete org', () {
        // Admin SHOULD have
        const adminHas = [
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
        ];

        for (final permission in adminHas) {
          expect(
            service.canPerform(UserRole.admin, permission),
            isTrue,
            reason:
                'Admin should have ${permission.value}',
          );
        }

        // Admin should NOT have
        expect(
          service.canPerform(
            UserRole.admin,
            Permission.manageBilling,
          ),
          isFalse,
        );
        expect(
          service.canPerform(
            UserRole.admin,
            Permission.deleteOrganization,
          ),
          isFalse,
        );
      });
    });

    group('Scorer permissions', () {
      test('has only score and read permissions', () {
        // Scorer SHOULD have
        expect(
          service.canPerform(
            UserRole.scorer,
            Permission.enterScores,
          ),
          isTrue,
        );
        expect(
          service.canPerform(
            UserRole.scorer,
            Permission.editScores,
          ),
          isTrue,
        );
        expect(
          service.canPerform(
            UserRole.scorer,
            Permission.viewData,
          ),
          isTrue,
        );

        // Scorer should NOT have
        const scorerShouldNotHave = [
          Permission.manageOrganization,
          Permission.deleteOrganization,
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
          Permission.manageBilling,
        ];

        for (final permission in scorerShouldNotHave) {
          expect(
            service.canPerform(
              UserRole.scorer,
              permission,
            ),
            isFalse,
            reason:
                'Scorer should NOT have '
                '${permission.value}',
          );
        }
      });
    });

    group('Viewer permissions', () {
      test('has only read permission', () {
        expect(
          service.canPerform(
            UserRole.viewer,
            Permission.viewData,
          ),
          isTrue,
        );

        // Viewer should NOT have anything else
        for (final permission in Permission.values) {
          if (permission == Permission.viewData) continue;
          expect(
            service.canPerform(
              UserRole.viewer,
              permission,
            ),
            isFalse,
            reason:
                'Viewer should NOT have '
                '${permission.value}',
          );
        }
      });
    });

    group('assertPermission', () {
      test(
        'returns Right(unit) when permission is granted',
        () {
          final result = service.assertPermission(
            UserRole.owner,
            Permission.manageBilling,
          );
          expect(result, const Right<Failure, Unit>(unit));
        },
      );

      test(
        'returns Left(AuthorizationPermissionDeniedFailure) '
        'when permission is denied',
        () {
          final result = service.assertPermission(
            UserRole.viewer,
            Permission.manageBilling,
          );
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(
              failure,
              isA<AuthorizationPermissionDeniedFailure>(),
            ),
            (_) => fail('Expected Left'),
          );
        },
      );
    });
  });
}
```

---

### Task 12: Write Unit Tests for `UpdateUserRoleUseCase` — AC12

#### Test File: `test/features/auth/domain/usecases/update_user_role_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/update_user_role_use_case.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late UpdateUserRoleUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = UpdateUserRoleUseCase(
      mockUserRepository,
      mockAuthRepository,
    );
  });

  // Fixtures
  final ownerUser = UserEntity(
    id: 'owner-123',
    email: 'owner@example.com',
    displayName: 'Owner',
    organizationId: 'org-1',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final targetUser = UserEntity(
    id: 'target-456',
    email: 'target@example.com',
    displayName: 'Target User',
    organizationId: 'org-1',
    role: UserRole.viewer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final adminUser = UserEntity(
    id: 'admin-789',
    email: 'admin@example.com',
    displayName: 'Admin User',
    organizationId: 'org-1',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('UpdateUserRoleUseCase', () {
    test(
      'successfully changes user role when requester is Owner',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('target-456'),
        ).thenAnswer(
          (_) async => Right(targetUser),
        );
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer((invocation) async {
          final user = invocation.positionalArguments
              .first as UserEntity;
          return Right(user);
        });

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (updatedUser) {
            expect(updatedUser.role, UserRole.scorer);
            expect(updatedUser.id, 'target-456');
          },
        );
        verify(
          () => mockUserRepository.updateUser(any()),
        ).called(1);
      },
    );

    test(
      'returns AuthenticationFailure when auth user does '
      'not match requestingUserId',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<AuthenticationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockUserRepository);
      },
    );

    test(
      'returns AuthorizationPermissionDeniedFailure when '
      'requester is not Owner',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );
        when(
          () => mockUserRepository
              .getUserById('admin-789'),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'admin-789',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<AuthorizationPermissionDeniedFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns InputValidationFailure when trying to '
      'change own role',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'owner-123',
            newRole: UserRole.admin,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<InputValidationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns InputValidationFailure when trying to '
      'assign Owner role',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.owner,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<InputValidationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'propagates repository failure when updateUser fails',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('target-456'),
        ).thenAnswer(
          (_) async => Right(targetUser),
        );
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer(
          (_) async => const Left(
            ServerConnectionFailure(),
          ),
        );

        final result = await useCase(
          const UpdateUserRoleParams(
            targetUserId: 'target-456',
            newRole: UserRole.scorer,
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<ServerConnectionFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
```

---

### Task 13: Write Unit Tests for `RemoveOrganizationMemberUseCase` — AC13

#### Test File: `test/features/auth/domain/usecases/remove_organization_member_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/remove_organization_member_use_case.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUserEntity extends Fake implements UserEntity {}

void main() {
  late RemoveOrganizationMemberUseCase useCase;
  late MockUserRepository mockUserRepository;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserEntity());
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthRepository = MockAuthRepository();
    useCase = RemoveOrganizationMemberUseCase(
      mockUserRepository,
      mockAuthRepository,
    );
  });

  // Fixtures
  final ownerUser = UserEntity(
    id: 'owner-123',
    email: 'owner@example.com',
    displayName: 'Owner',
    organizationId: 'org-1',
    role: UserRole.owner,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final targetUser = UserEntity(
    id: 'target-456',
    email: 'target@example.com',
    displayName: 'Target User',
    organizationId: 'org-1',
    role: UserRole.scorer,
    isActive: true,
    createdAt: DateTime(2024),
  );

  final adminUser = UserEntity(
    id: 'admin-789',
    email: 'admin@example.com',
    displayName: 'Admin User',
    organizationId: 'org-1',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime(2024),
  );

  group('RemoveOrganizationMemberUseCase', () {
    test(
      'successfully removes user from organization',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('target-456'),
        ).thenAnswer(
          (_) async => Right(targetUser),
        );

        late UserEntity capturedUser;
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer((invocation) async {
          capturedUser = invocation.positionalArguments
              .first as UserEntity;
          return Right(capturedUser);
        });

        final result = await useCase(
          const RemoveOrganizationMemberParams(
            targetUserId: 'target-456',
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isRight(), isTrue);

        // Verify user was cleared
        expect(capturedUser.organizationId, '');
        expect(capturedUser.role, UserRole.viewer);
        expect(capturedUser.id, 'target-456');

        verify(
          () => mockUserRepository.updateUser(any()),
        ).called(1);
      },
    );

    test(
      'returns AuthenticationFailure when auth user '
      'does not match requestingUserId',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );

        final result = await useCase(
          const RemoveOrganizationMemberParams(
            targetUserId: 'target-456',
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<AuthenticationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
        verifyZeroInteractions(mockUserRepository);
      },
    );

    test(
      'returns AuthorizationPermissionDeniedFailure '
      'when requester is not Owner',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );
        when(
          () => mockUserRepository
              .getUserById('admin-789'),
        ).thenAnswer(
          (_) async => Right(adminUser),
        );

        final result = await useCase(
          const RemoveOrganizationMemberParams(
            targetUserId: 'target-456',
            requestingUserId: 'admin-789',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<AuthorizationPermissionDeniedFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'returns InputValidationFailure when trying to '
      'remove self',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );

        final result = await useCase(
          const RemoveOrganizationMemberParams(
            targetUserId: 'owner-123',
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<InputValidationFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );

    test(
      'propagates repository failure when updateUser fails',
      () async {
        when(
          () => mockAuthRepository
              .getCurrentAuthenticatedUser(),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('owner-123'),
        ).thenAnswer(
          (_) async => Right(ownerUser),
        );
        when(
          () => mockUserRepository
              .getUserById('target-456'),
        ).thenAnswer(
          (_) async => Right(targetUser),
        );
        when(
          () => mockUserRepository.updateUser(any()),
        ).thenAnswer(
          (_) async => const Left(
            ServerConnectionFailure(),
          ),
        );

        final result = await useCase(
          const RemoveOrganizationMemberParams(
            targetUserId: 'target-456',
            requestingUserId: 'owner-123',
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure,
            isA<ServerConnectionFailure>(),
          ),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
```

---

## Architecture Constraints

### Security Requirements

- **Auth verification:** All use cases MUST verify authenticated user matches requesting user ID via `AuthRepository.getCurrentAuthenticatedUser()`
- **Organization isolation:** Cross-organization actions are FORBIDDEN. Verify requester and target share same `organizationId`
- **Orphan user check:** Validate target users have non-empty `organizationId` before operations

### RBAC Usage Patterns

- **Permission matrix is static:** Defined at compile time in `RbacPermissionService.permissionMatrix`
- **Owner auto-inherits:** Owner role gets `Permission.values` so any future permissions are automatically granted
- **Service vs. direct role checks:** Use `RbacPermissionService` for granular permission checks; direct `UserRole` equality is acceptable for owner-only operations

### Error Handling

- `InputValidationFailure` — validation errors (with `fieldErrors` map)
- `AuthenticationFailure` — auth errors (user ID mismatch)
- `AuthorizationPermissionDeniedFailure` — permission errors (wrong role or org)
- Repository failures propagate as-is (e.g., `ServerConnectionFailure`)

---

### Project Structure Notes

**New files created by this story:**

| Layer  | File                                                       | Type             |
| ------ | ---------------------------------------------------------- | ---------------- |
| Domain | `domain/entities/permission.dart`                          | Enum             |
| Domain | `domain/entities/rbac_permission_service.dart`             | Service          |
| Domain | `domain/usecases/update_user_role_params.dart`             | Params (freezed) |
| Domain | `domain/usecases/update_user_role_use_case.dart`           | Use Case         |
| Domain | `domain/usecases/remove_organization_member_params.dart`   | Params (freezed) |
| Domain | `domain/usecases/remove_organization_member_use_case.dart` | Use Case         |

**Generated files (by `build_runner`):**

| File                                             | Generator  |
| ------------------------------------------------ | ---------- |
| `update_user_role_params.freezed.dart`           | freezed    |
| `remove_organization_member_params.freezed.dart` | freezed    |
| Updated `injection.config.dart`                  | injectable |

**Test files:**

| File                                                                               |
| ---------------------------------------------------------------------------------- |
| `test/features/auth/domain/entities/rbac_permission_service_test.dart`             |
| `test/features/auth/domain/usecases/update_user_role_use_case_test.dart`           |
| `test/features/auth/domain/usecases/remove_organization_member_use_case_test.dart` |

**Modified files:**

| File                          | Change Description                          |
| ----------------------------- | ------------------------------------------- |
| `lib/features/auth/auth.dart` | Add 6 new exports (2 entities, 4 use cases) |
| `lib/injection.config.dart`   | Auto-updated by build_runner                |

### Pattern References

| What                     | Reference File                         |
| ------------------------ | -------------------------------------- |
| Entity with enum         | `user_entity.dart` (UserRole)          |
| Domain service           | N/A — first domain service in codebase |
| Use case with auth check | `send_invitation_use_case.dart`        |
| Params class             | `send_invitation_params.dart`          |
| Unit test pattern        | `send_invitation_use_case_test.dart`   |
| Failure types            | `core/error/failures.dart`             |
| fpdart Either pattern    | `accept_invitation_use_case.dart`      |
| UseCase base class       | `core/usecases/use_case.dart`          |

### Naming Conventions (from architecture.md)

- **Files:** `snake_case` — e.g., `rbac_permission_service.dart`
- **Classes:** `PascalCase` — e.g., `RbacPermissionService`
- **Enums:** `PascalCase` with `camelCase` values — e.g., `Permission.enterScores`
- **Test files:** Mirror source structure — e.g., `test/features/auth/domain/entities/rbac_permission_service_test.dart`

### Error Handling Pattern

All use cases return `Either<Failure, T>` using fpdart:
- `InputValidationFailure` for validation errors (with `fieldErrors` map)
- `AuthenticationFailure` for auth errors (user ID mismatch)
- `AuthorizationPermissionDeniedFailure` for permission errors (non-owner)
- Repository failures are propagated as-is (e.g., `ServerConnectionFailure`)

### Dependencies

- `fpdart` (already in pubspec.yaml)
- `injectable` (already in pubspec.yaml)
- `freezed_annotation` (already in pubspec.yaml)
- `mocktail` (dev dependency, already in pubspec.yaml)
- NO new packages required

### What This Story Does NOT Include

- UI/BLoC integration for RBAC — future story
- Route guards based on RBAC — future story (referenced in architecture.md `route_guards.dart`)
- RLS policy updates in Supabase — server-side concern
- Admin's ability to change roles — acceptance criteria specifies Owner-only (FR57)
- Organization deletion use case — separate from member removal
- Integration with specific feature BLoCs (tournament, scoring, etc.) — those features will call `RbacPermissionService.canPerform()` when implemented

## Dev Agent Record

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
