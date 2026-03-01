import 'package:flutter/foundation.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/bracket_entity.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

/// Value object containing the results of a bracket generation
/// operation. This includes the generated [BracketEntity] and
/// its associated [MatchEntity] records.
@immutable
class BracketGenerationResult {
  const BracketGenerationResult({required this.bracket, required this.matches});

  final BracketEntity bracket;
  final List<MatchEntity> matches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BracketGenerationResult &&
          runtimeType == other.runtimeType &&
          bracket == other.bracket &&
          listEquals(matches, other.matches);

  @override
  int get hashCode => bracket.hashCode ^ matches.hashCode;
}
