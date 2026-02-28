import 'package:flutter/foundation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

/// Value object containing the results of a double elimination
/// bracket generation operation.
@immutable
class DoubleEliminationBracketGenerationResult {
  const DoubleEliminationBracketGenerationResult({
    required this.winnersBracket,
    required this.losersBracket,
    required this.grandFinalsMatch,
    required this.allMatches,
    this.resetMatch,
  });

  final BracketEntity winnersBracket;
  final BracketEntity losersBracket;
  final MatchEntity grandFinalsMatch;
  final MatchEntity? resetMatch;
  final List<MatchEntity> allMatches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleEliminationBracketGenerationResult &&
          runtimeType == other.runtimeType &&
          winnersBracket == other.winnersBracket &&
          losersBracket == other.losersBracket &&
          grandFinalsMatch == other.grandFinalsMatch &&
          resetMatch == other.resetMatch &&
          listEquals(allMatches, other.allMatches);

  @override
  int get hashCode =>
      winnersBracket.hashCode ^
      losersBracket.hashCode ^
      grandFinalsMatch.hashCode ^
      resetMatch.hashCode ^
      allMatches.hashCode;
}
