import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:tkd_brackets/core/error/failures.dart';
import 'package:tkd_brackets/core/usecases/use_case.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/repositories/bracket_repository.dart';
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_params.dart';

@injectable
class UnlockBracketUseCase extends UseCase<BracketEntity, UnlockBracketParams> {
  UnlockBracketUseCase(this._bracketRepository);

  final BracketRepository _bracketRepository;

  @override
  Future<Either<Failure, BracketEntity>> call(
    UnlockBracketParams params,
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
      // 3. Check IS finalized (can't unlock what isn't locked)
      if (!bracket.isFinalized) {
        return const Left(
          ValidationFailure(
            userFriendlyMessage:
                'Bracket is not locked (not finalized). '
                'Cannot unlock a bracket that is not locked.',
          ),
        );
      }

      // 4. Update with isFinalized = false, clear timestamp
      final updatedBracket = bracket.copyWith(
        isFinalized: false,
        finalizedAtTimestamp: null,
      );

      return _bracketRepository.updateBracket(updatedBracket);
    });
  }
}
