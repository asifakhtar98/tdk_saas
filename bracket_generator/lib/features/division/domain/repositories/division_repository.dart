import 'package:fpdart/fpdart.dart';
import 'package:bracket_generator/core/error/failures.dart';
import '../../../../features/division/domain/entities/division_entity.dart';

abstract class DivisionRepository {
  Future<Either<Failure, DivisionEntity>> getDivisionById(String id);
}
