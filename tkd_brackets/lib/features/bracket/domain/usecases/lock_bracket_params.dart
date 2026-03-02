import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/features/bracket/bracket.dart' show LockBracketUseCase;
import 'package:tkd_brackets/features/bracket/domain/usecases/lock_bracket_use_case.dart' show LockBracketUseCase;

/// Parameters for [LockBracketUseCase].
@immutable
class LockBracketParams {
  /// Creates [LockBracketParams].
  const LockBracketParams({required this.bracketId});

  /// The bracket ID to lock (finalize).
  final String bracketId;
}
