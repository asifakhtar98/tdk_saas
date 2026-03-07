import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/features/bracket/domain/usecases/unlock_bracket_use_case.dart'
    show UnlockBracketUseCase;

/// Parameters for [UnlockBracketUseCase].
@immutable
class UnlockBracketParams {
  /// Creates [UnlockBracketParams].
  const UnlockBracketParams({required this.bracketId});

  /// The bracket ID to unlock (un-finalize).
  final String bracketId;
}
