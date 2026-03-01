import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';
import 'package:tkd_brackets/features/division/domain/repositories/division_repository.dart';
import 'package:tkd_brackets/features/division/domain/usecases/apply_federation_template_params.dart';
import 'package:tkd_brackets/features/division/services/federation_template_registry.dart';
import 'package:uuid/uuid.dart';

@injectable
class ApplyFederationTemplateUseCase
    extends UseCase<List<DivisionEntity>, ApplyFederationTemplateParams> {
  ApplyFederationTemplateUseCase(this._divisionRepository, this._registry);

  final DivisionRepository _divisionRepository;
  final FederationTemplateRegistry _registry;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<DivisionEntity>>> call(
    ApplyFederationTemplateParams params,
  ) async {
    try {
      final divisions = <DivisionEntity>[];
      final now = DateTime.now();

      for (final templateId in params.templateIds) {
        final template = _registry.getTemplateById(templateId);
        if (template == null) {
          return Left(
            NotFoundFailure(
              userFriendlyMessage: 'Template not found: $templateId',
            ),
          );
        }

        final division = DivisionEntity(
          id: _uuid.v4(),
          tournamentId: params.tournamentId,
          name: template.name,
          category: template.category,
          gender: template.gender,
          ageMin: template.ageMin,
          ageMax: template.ageMax,
          weightMinKg: template.weightMinKg,
          weightMaxKg: template.weightMaxKg,
          beltRankMin: template.beltRankMin,
          beltRankMax: template.beltRankMax,
          bracketFormat: template.defaultBracketFormat,
          displayOrder: template.displayOrder,
          status: DivisionStatus.setup,
          createdAtTimestamp: now,
          updatedAtTimestamp: now,
        );

        final result = await _divisionRepository.createDivision(division);
        result.fold((failure) => divisions.add(division), divisions.add);
      }

      return Right(divisions);
    } on Exception catch (e) {
      return Left(
        ServerResponseFailure(
          userFriendlyMessage: 'Failed to apply templates: $e',
        ),
      );
    }
  }
}
