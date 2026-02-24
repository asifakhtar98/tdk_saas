import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';

/// Repository interface for organization operations.
///
/// Implementations handle data source coordination
/// (local Drift, remote Supabase).
abstract class OrganizationRepository {
  /// Get organization by ID.
  /// Returns [Left(Failure)] if not found or error occurs.
  Future<Either<Failure, OrganizationEntity>> getOrganizationById(String id);

  /// Get organization by slug.
  /// Returns [Left(Failure)] if not found or error occurs.
  Future<Either<Failure, OrganizationEntity>> getOrganizationBySlug(
    String slug,
  );

  /// Get all active (non-deleted) organizations.
  Future<Either<Failure, List<OrganizationEntity>>> getActiveOrganizations();

  /// Create a new organization (local + remote sync).
  /// Returns created organization on success.
  Future<Either<Failure, OrganizationEntity>> createOrganization(
    OrganizationEntity organization,
  );

  /// Update an existing organization.
  /// Returns updated organization on success.
  Future<Either<Failure, OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  );

  /// Delete an organization (soft delete).
  Future<Either<Failure, Unit>> deleteOrganization(String id);
}
