import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_params.dart';

@injectable
class LockBracketUseCase extends UseCase<BracketEntity, LockBracketParams> {
  LockBracketUseCase(this._bracketRepository);

  final BracketRepository _bracketRepository;

  @override
  Future<Either<Failure, BracketEntity>> call(
    LockBracketParams params,
  ) async {
    // 1. Validate bracketId
    if (params.bracketId.trim().isEmpty) {
      return const Left(
        ValidationFailure(userFriendlyMessage: 'Bracket ID is required.'),
      );
    }

    // 2. Fetch the bracket
    final bracketResult = await _bracketRepository.getBracketById(
      params.bracketId,
    );

    return bracketResult.fold(Left.new, (bracket) async {
      // 3. Check not already finalized
      if (bracket.isFinalized) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Bracket is already locked (finalized). '
                'No action needed.',
          ),
        );
      }

      // 4. Update with isFinalized = true
      final updatedBracket = bracket.copyWith(
        isFinalized: true,
        finalizedAtTimestamp: DateTime.now(),
      );

      return _bracketRepository.updateBracket(updatedBracket);
    });
  }
}
