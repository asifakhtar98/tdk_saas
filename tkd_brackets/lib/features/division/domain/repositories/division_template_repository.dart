import 'package:fpdart/fpdart.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_template.dart';

abstract class DivisionTemplateRepository {
  Future<Either<Failure, List<DivisionTemplate>>> getCustomTemplates(
    String organizationId,
  );

  Future<Either<Failure, DivisionTemplate>> getCustomTemplateById(String id);

  Future<Either<Failure, DivisionTemplate>> createCustomTemplate(
    DivisionTemplate template,
  );

  Future<Either<Failure, DivisionTemplate>> updateCustomTemplate(
    DivisionTemplate template,
  );

  Future<Either<Failure, Unit>> deleteCustomTemplate(String id);
}
