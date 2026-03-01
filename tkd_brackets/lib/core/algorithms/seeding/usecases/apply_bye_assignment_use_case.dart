import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/core/algorithms/seeding/models/bye_assignment_result.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_params.dart';
import 'package:tkd_brackets/core/algorithms/seeding/services/bye_assignment_service.dart';
import 'package:tkd_brackets/core/algorithms/seeding/usecases/apply_bye_assignment_params.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';

/// Use case that validates inputs and delegates to [ByeAssignmentService].
@injectable
class ApplyByeAssignmentUseCase
    extends UseCase<ByeAssignmentResult, ApplyByeAssignmentParams> {
  ApplyByeAssignmentUseCase(this._service);

  final ByeAssignmentService _service;

  @override
  Future<Either<Failure, ByeAssignmentResult>> call(
    ApplyByeAssignmentParams params,
  ) async {
    // 1. Validate divisionId
    if (params.divisionId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Division ID is required.'),
      );
    }

    // 2. Validate minimum participants
    if (params.participants.length < 2) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'At least 2 participants are required for bye assignment.',
        ),
      );
    }

    // 3. Validate no empty participant IDs
    if (params.participants.any((p) => p.id.trim().isEmpty)) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Participant list contains empty IDs.',
        ),
      );
    }

    // 4. Validate no duplicate participant IDs
    final ids = params.participants.map((p) => p.id).toSet();
    if (ids.length != params.participants.length) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage: 'Duplicate participant IDs detected.',
        ),
      );
    }

    // 5. Validate bracket format (roundRobin has no byes)
    if (params.bracketFormat == BracketFormat.roundRobin) {
      return const Left(
        ValidationFailure(
          userFriendlyMessage:
              'Round robin format does not support bye assignment.',
        ),
      );
    }

    // 6. Delegate to service
    return _service.assignByes(
      ByeAssignmentParams(
        participantCount: params.participants.length,
        seedOrder: params.participants.map((p) => p.id).toList(),
      ),
    );
  }
}
