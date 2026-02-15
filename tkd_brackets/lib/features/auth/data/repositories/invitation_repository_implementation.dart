import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/core/sync/sync_queue.dart';
import 'package:tkd_brackets/features/auth/data/datasources/invitation_local_datasource.dart';
import 'package:tkd_brackets/features/auth/data/datasources/invitation_remote_datasource.dart';
import 'package:tkd_brackets/features/auth/data/models/invitation_model.dart';
import 'package:tkd_brackets/features/auth/domain/entities/invitation_entity.dart';
import 'package:tkd_brackets/features/auth/domain/repositories/invitation_repository.dart';

const _invitationsTableName = 'invitations';

@LazySingleton(as: InvitationRepository)
class InvitationRepositoryImplementation implements InvitationRepository {
  InvitationRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
    this._syncQueue,
  );

  final InvitationLocalDatasource _localDatasource;
  final InvitationRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;

  @override
  Future<Either<Failure, InvitationEntity>> createInvitation(
    InvitationEntity invitation,
  ) async {
    try {
      final model = InvitationModel.convertFromEntity(invitation);

      // 1. Write to local database first (offline-first)
      await _localDatasource.insertInvitation(model);

      // 2. Attempt remote sync if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          // Sync invitation to Supabase
          await _remoteDatasource.upsertInvitation(model);
        } on Exception catch (_) {
          // Enqueue for later sync if remote fails
          await _syncQueue.enqueue(
            tableName: _invitationsTableName,
            recordId: invitation.id,
            operation: 'insert',
          );
        }

        // Send invitation email separately - don't fail entire operation if email fails
        try {
          await _remoteDatasource.sendInvitationEmail(model);
        } on Exception catch (_) {
          // Email failed - log but don't fail the invitation creation
          // The invitation is created, just no email sent
          // Future: Add email retry queue or notify user
        }
      } else {
        // Offline - enqueue for sync when online
        await _syncQueue.enqueue(
          tableName: _invitationsTableName,
          recordId: invitation.id,
          operation: 'insert',
        );
      }

      return Right(invitation);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to create invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InvitationEntity>> getInvitationByToken(
    String token,
  ) async {
    try {
      // Try local first
      final localModel = await _localDatasource.getInvitationByToken(token);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }

      // Try remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteModel = await _remoteDatasource.getInvitationByToken(
            token,
          );
          if (remoteModel != null) {
            // Cache locally
            await _localDatasource.insertInvitation(remoteModel);
            return Right(remoteModel.convertToEntity());
          }
        } on Exception catch (_) {
          // Remote failed, return not found
          return const Left(
            LocalCacheAccessFailure(
              userFriendlyMessage: 'Invitation not found.',
            ),
          );
        }
      }

      return const Left(
        LocalCacheAccessFailure(userFriendlyMessage: 'Invitation not found.'),
      );
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<InvitationEntity>>>
  getPendingInvitationsForOrganization(String organizationId) async {
    try {
      final models = await _localDatasource
          .getPendingInvitationsForOrganization(organizationId);
      return Right(models.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to retrieve invitations.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InvitationEntity>> updateInvitation(
    InvitationEntity invitation,
  ) async {
    try {
      // Read existing record to get current syncVersion
      final existing = await _localDatasource.getInvitationById(invitation.id);
      final newSyncVersion = (existing?.syncVersion ?? 0) + 1;

      final model = InvitationModel.convertFromEntity(
        invitation,
        syncVersion: newSyncVersion,
      );

      // Update local first
      await _localDatasource.updateInvitation(model);

      // Sync to remote if online
      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.upsertInvitation(model);
        } on Exception catch (_) {
          await _syncQueue.enqueue(
            tableName: _invitationsTableName,
            recordId: invitation.id,
            operation: 'update',
          );
        }
      } else {
        await _syncQueue.enqueue(
          tableName: _invitationsTableName,
          recordId: invitation.id,
          operation: 'update',
        );
      }

      return Right(invitation);
    } on Exception catch (e) {
      return Left(
        LocalCacheWriteFailure(
          userFriendlyMessage: 'Failed to update invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, InvitationEntity?>> getExistingPendingInvitation(
    String email,
    String organizationId,
  ) async {
    try {
      final model = await _localDatasource.getInvitationByEmailAndOrganization(
        email,
        organizationId,
      );
      if (model == null) return const Right(null);
      return Right(model.convertToEntity());
    } on Exception catch (e) {
      return Left(
        LocalCacheAccessFailure(
          userFriendlyMessage: 'Failed to check for existing invitation.',
          technicalDetails: e.toString(),
        ),
      );
    }
  }
}
