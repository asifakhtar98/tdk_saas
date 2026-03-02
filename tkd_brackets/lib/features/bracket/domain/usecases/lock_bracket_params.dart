import 'package:flutter/foundation.dart' show immutable;

/// Parameters for [LockBracketUseCase].
@immutable
class LockBracketParams {
  /// Creates [LockBracketParams].
  const LockBracketParams({required this.bracketId});

  /// The bracket ID to lock (finalize).
  final String bracketId;
}
