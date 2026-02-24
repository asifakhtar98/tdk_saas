import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/organization_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/organization_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/organization_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/organization_repository.dart';

/// Implementation of [OrganizationRepository] with offline-first
/// strategy.
///
/// - Read: Try local first, fallback to remote if not found
/// - Write: Write to local, queue for sync if offline
/// - Sync: Last-Write-Wins based on sync_version
@LazySingleton(as: OrganizationRepository)
class OrganizationRepositoryImplementation implements OrganizationRepository {
  OrganizationRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final OrganizationLocalDatasource _localDatasource;
  final OrganizationRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, OrganizationEntity>> getOrganizationById(
    String id,
  ) async {
    try {
      // Try local first
      final localOrg = await _localDatasource.getOrganizationById(id);
      if (localOrg != null) {
        return Right(localOrg.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteOrg = await _remoteDatasource.getOrganizationById(id);
        if (remoteOrg != null) {
          // Cache locally
          await _localDatasource.insertOrganization(remoteOrg);
          return Right(remoteOrg.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Organization not found.',
          technicalDetails:
              'No organization found with the given ID '
              'in local or remote.',
        ),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>> getOrganizationBySlug(
    String slug,
  ) async {
    try {
      // Try local first (offline-first)
      final localOrg = await _localDatasource.getOrganizationBySlug(slug);
      if (localOrg != null) {
        return Right(localOrg.convertToEntity());
      }

      // Fallback to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        final remoteOrg = await _remoteDatasource.getOrganizationBySlug(slug);
        if (remoteOrg != null) {
          // Cache locally
          await _localDatasource.insertOrganization(remoteOrg);
          return Right(remoteOrg.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Organization not found.',
          technicalDetails:
              'No organization found with the given '
              'slug.',
        ),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<OrganizationEntity>>>
  getActiveOrganizations() async {
    try {
      // Try local first
      var organizations = await _localDatasource.getActiveOrganizations();

      // If online, fetch from remote and update local
      // cache
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteOrgs = await _remoteDatasource.getActiveOrganizations();
          // Sync remote to local
          for (final org in remoteOrgs) {
            final existing = await _localDatasource.getOrganizationById(org.id);
            if (existing == null) {
              await _localDatasource.insertOrganization(org);
            } else if (org.syncVersion > existing.syncVersion) {
              await _localDatasource.updateOrganization(org);
            }
          }
          organizations = remoteOrgs;
        } on Exception catch (_) {
          // Use local data if remote fails
        }
      }

      return Right(organizations.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve organizations.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>> createOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      final model = OrganizationModel.convertFromEntity(organization);

      // Always save locally first
      await _localDatasource.insertOrganization(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertOrganization(model);
        } on Exception catch (_) {
          // Queued for sync — continue with local
          // success
        }
      }

      return Right(organization);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to create organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, OrganizationEntity>> updateOrganization(
    OrganizationEntity organization,
  ) async {
    try {
      // Read existing record to get current
      // syncVersion for the remote sync.
      // AppDatabase.updateOrganization() will
      // independently compute syncVersion + 1
      // inside its transaction for the local write,
      // but we need to send the correct version
      // to Supabase as well.
      final existing = await _localDatasource.getOrganizationById(
        organization.id,
      );
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = OrganizationModel.convertFromEntity(
        organization,
        syncVersion: newSyncVersion,
      );

      await _localDatasource.updateOrganization(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateOrganization(model);
        } on Exception catch (_) {
          // Queued for sync — continue with local
          // success
        }
      }

      return Right(organization);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to update organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOrganization(String id) async {
    try {
      await _localDatasource.deleteOrganization(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteOrganization(id);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to delete organization.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }
}
