import 'package:flutter/foundation.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_generation_result.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';

@immutable
class HybridBracketGenerationResult {
  const HybridBracketGenerationResult({
    required this.poolBrackets,
    required this.eliminationBracket,
    required this.allMatches,
  });

  /// One BracketGenerationResult per pool (Pool A, Pool B, ...).
  final List<BracketGenerationResult> poolBrackets;

  /// The single elimination bracket built from pool qualifiers.
  final BracketGenerationResult eliminationBracket;

  /// All matches across all pools + elimination.
  final List<MatchEntity> allMatches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HybridBracketGenerationResult &&
          runtimeType == other.runtimeType &&
          listEquals(poolBrackets, other.poolBrackets) &&
          eliminationBracket == other.eliminationBracket &&
          listEquals(allMatches, other.allMatches);

  @override
  int get hashCode =>
      poolBrackets.hashCode ^
      eliminationBracket.hashCode ^
      allMatches.hashCode;
}
