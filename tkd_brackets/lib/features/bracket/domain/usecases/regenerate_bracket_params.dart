import 'package:flutter/foundation.dart' show immutable;
import 'package:tkd_brackets/core/algorithms/seeding/bracket_format.dart';
import 'package:tkd_brackets/features/bracket/bracket.dart'
    show RegenerateBracketUseCase;
import 'package:tkd_brackets/features/bracket/domain/usecases/regenerate_bracket_use_case.dart'
    show RegenerateBracketUseCase;

/// Parameters for [RegenerateBracketUseCase].
@immutable
class RegenerateBracketParams {
  /// Creates [RegenerateBracketParams].
  const RegenerateBracketParams({
    required this.divisionId,
    required this.participantIds,
    this.bracketFormat = BracketFormat.singleElimination,
    this.includeThirdPlaceMatch = false,
    this.includeResetMatch = true,
  });

  /// Division ID to regenerate brackets for.
  final String divisionId;

  /// Current participant IDs in seed order.
  final List<String> participantIds;

  /// Bracket format to generate.
  final BracketFormat bracketFormat;

  /// Include 3rd place match (single elimination only).
  final bool includeThirdPlaceMatch;

  /// Include reset match (double elimination grand finals only).
  final bool includeResetMatch;
}
