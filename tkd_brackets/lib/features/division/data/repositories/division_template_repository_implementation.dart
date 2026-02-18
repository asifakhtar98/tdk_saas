import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/network/connectivity_service.dart';
import 'package:tkd_brackets/features/division/data/datasources/division_template_local_datasource.dart';
import 'package:tkd_brackets/features/division/data/datasources/division_template_remote_datasource.dart';
import 'package:tkd_brackets/features/division/data/models/division_template_model.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_template.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_template_repository.dart';

@LazySingleton(as: DivisionTemplateRepository)
class DivisionTemplateRepositoryImplementation
    implements DivisionTemplateRepository {
  DivisionTemplateRepositoryImplementation(
    this._localDatasource,
    this._remoteDatasource,
    this._connectivityService,
  );

  final DivisionTemplateLocalDatasource _localDatasource;
  final DivisionTemplateRemoteDatasource _remoteDatasource;
  final ConnectivityService _connectivityService;

  @override
  Future<Either<Failure, List<DivisionTemplate>>> getCustomTemplates(
    String organizationId,
  ) async {
    try {
      final localModels = await _localDatasource
          .getCustomTemplatesForOrganization(organizationId);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          final remoteModels = await _remoteDatasource
              .getCustomTemplatesForOrganization(organizationId);
          for (final model in remoteModels) {
            try {
              await _localDatasource.insertTemplate(model);
            } catch (_) {
              // Already exists, try update
              try {
                await _localDatasource.updateTemplate(model);
              } catch (_) {}
            }
          }
          return Right(remoteModels.map((m) => m.convertToEntity()).toList());
        } on Exception catch (_) {
          // Use local data if remote fails
        }
      }

      return Right(localModels.map((m) => m.convertToEntity()).toList());
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DivisionTemplate>> getCustomTemplateById(
    String id,
  ) async {
    try {
      final localModel = await _localDatasource.getTemplateById(id);
      if (localModel != null) {
        return Right(localModel.convertToEntity());
      }

      if (await _connectivityService.hasInternetConnection()) {
        final remoteModel = await _remoteDatasource.getTemplateById(id);
        if (remoteModel != null) {
          await _localDatasource.insertTemplate(remoteModel);
          return Right(remoteModel.convertToEntity());
        }
      }

      return const Left(
        LocalCacheAccessFailure(userFriendlyMessage: 'Template not found.'),
      );
    } on Exception catch (e) {
      return Left(LocalCacheAccessFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DivisionTemplate>> createCustomTemplate(
    DivisionTemplate template,
  ) async {
    try {
      final model = DivisionTemplateModel.convertFromEntity(template);

      await _localDatasource.insertTemplate(model);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.insertTemplate(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(template);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DivisionTemplate>> updateCustomTemplate(
    DivisionTemplate template,
  ) async {
    try {
      final model = DivisionTemplateModel.convertFromEntity(template);

      await _localDatasource.updateTemplate(model);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.updateTemplate(model);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return Right(template);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCustomTemplate(String id) async {
    try {
      await _localDatasource.deleteTemplate(id);

      if (await _connectivityService.hasInternetConnection()) {
        try {
          await _remoteDatasource.deleteTemplate(id);
        } on Exception catch (_) {
          // Queued for sync
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(LocalCacheWriteFailure(technicalDetails: e.toString()));
    }
  }
}
