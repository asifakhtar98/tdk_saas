import 'package:flutter/foundation.dart' show immutable;

/// Parameters for [UnlockBracketUseCase].
@immutable
class UnlockBracketParams {
  /// Creates [UnlockBracketParams].
  const UnlockBracketParams({required this.bracketId});

  /// The bracket ID to unlock (un-finalize).
  final String bracketId;
}
