import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/error_reporting_service.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/entities/user_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/auth_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/user_repository.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/create_organization_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/migrate_demo_data_params.dart';
import 'package:tkd_brackets/features/auth/domain/usecases/migrate_demo_data_use_case.dart';
import 'package:uuid/uuid.dart';

/// Use case to create a new organization for a newly registered
/// user.
///
/// This use case:
/// 1. Validates the organization name
/// 2. Verifies the user is authenticated and matches the authorized ID
/// 3. Generates a URL-safe slug from the name
/// 4. Creates the organization with free-tier defaults
/// 5. Persists via [OrganizationRepository]
/// 6. Updates the user's organizationId and role to 'owner'
///    via [UserRepository]
@injectable
class CreateOrganizationUseCase
    extends UseCase<OrganizationEntity, CreateOrganizationParams> {
  CreateOrganizationUseCase(
    this._organizationRepository,
    this._userRepository,
    this._authRepository,
    this._errorReportingService,
    this._migrateDemoDataUseCase,
  );

  final OrganizationRepository _organizationRepository;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;
  final ErrorReportingService _errorReportingService;
  final MigrateDemoDataUseCase _migrateDemoDataUseCase;

  /// Maximum allowed length for organization name.
  static const int maxNameLength = 255;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, OrganizationEntity>> call(
    CreateOrganizationParams params,
  ) async {
    // 0. Security Check: Verify authenticated user matches params.userId
    final authUserResult = await _authRepository.getCurrentAuthenticatedUser();

    Either<Failure, OrganizationEntity>? authFailure;

    authUserResult.fold(
      (failure) {
        authFailure = Left(failure);
      },
      (user) {
        if (user.id != params.userId) {
          authFailure = const Left(
            AuthenticationFailure(
              userFriendlyMessage: 'Unauthorized operation.',
              technicalDetails: 'User ID mismatch in CreateOrganizationParams',
            ),
          );
        }
      },
    );

    if (authFailure != null) {
      return authFailure!;
    }

    // 1. Validate organization name
    final trimmedName = params.name.trim();
    if (trimmedName.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage: 'Organization name cannot be empty.',
          fieldErrors: {'name': 'Name is required'},
        ),
      );
    }

    if (trimmedName.length > maxNameLength) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Organization name is too long '
              '(max $maxNameLength characters).',
          fieldErrors: {
            'name':
                'Name must be $maxNameLength characters '
                'or less',
          },
        ),
      );
    }

    // 2. Generate slug from name
    final slug = generateSlug(trimmedName);
    if (slug.isEmpty) {
      return const Left(
        InputValidationFailure(
          userFriendlyMessage:
              'Organization name must contain at least '
              'one letter or number.',
          fieldErrors: {'name': 'Name must contain alphanumeric characters'},
        ),
      );
    }

    // 3. Generate UUID for organization
    final orgId = _uuid.v4();

    // 4. Build entity with free-tier defaults
    final organization = OrganizationEntity(
      id: orgId,
      name: trimmedName,
      slug: slug,
      subscriptionTier: SubscriptionTier.free,
      subscriptionStatus: SubscriptionStatus.active,
      maxTournamentsPerMonth: 2,
      maxActiveBrackets: 3,
      maxParticipantsPerBracket: 32,
      maxParticipantsPerTournament: 100,
      maxScorers: 2,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // 5. Persist organization via repository
    final createResult = await _organizationRepository.createOrganization(
      organization,
    );

    return createResult.fold(Left.new, (createdOrg) async {
      // 6. Fetch and update the user's organizationId
      //    and role to 'owner'
      final userResult = await _userRepository.getUserById(params.userId);

      return userResult.fold(Left.new, (user) async {
        final updatedUser = user.copyWith(
          organizationId: createdOrg.id,
          role: UserRole.owner,
        );
        final updateResult = await _userRepository.updateUser(updatedUser);

        return updateResult.fold(
          (failure) {
            // CRITICAL: Organization created but user update failed!
            // We have an orphaned organization and a user who thinks it failed.
            _errorReportingService
              ..reportError(
                'CRITICAL DATA INCONSISTENCY: '
                'Organization created but user '
                'update failed.',
                error: failure,
                stackTrace: StackTrace.current,
              )
              ..addBreadcrumb(
                message: 'Orphaned Organization Created',
                category: 'data_integrity',
                data: {
                  'organizationId': createdOrg.id,
                  'userId': params.userId,
                  'failure': failure.toString(),
                },
              );
            return Left(failure);
          },
          (_) async {
            // 7. Migrate demo data if exists (gracefully skips if none)
            final migrationResult = await _migrateDemoDataUseCase(
              MigrateDemoDataParams(newOrganizationId: createdOrg.id),
            );

            // Migration failure is not critical - log but don't fail
            migrationResult.fold(
              (failure) {
                _errorReportingService.addBreadcrumb(
                  message: 'Demo data migration failed (non-critical)',
                  category: 'migration',
                  data: {
                    'organizationId': createdOrg.id,
                    'failure': failure.toString(),
                  },
                );
              },
              (_) {
                _errorReportingService.addBreadcrumb(
                  message: 'Demo data migration completed',
                  category: 'migration',
                  data: {'organizationId': createdOrg.id},
                );
              },
            );

            return Right(createdOrg);
          },
        );
      });
    });
  }

  /// Generate a URL-safe slug from an organization name.
  ///
  /// Rules:
  /// - Convert to lowercase
  /// - Replace spaces and underscores with hyphens
  /// - Remove all non-alphanumeric, non-hyphen characters
  /// - Collapse consecutive hyphens into one
  /// - Trim leading/trailing hyphens
  ///
  /// Example: "Dragon Martial Arts!" → "dragon-martial-arts"
  @visibleForTesting
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp('[^a-z0-9-]'), '')
        .replaceAll(RegExp('-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
