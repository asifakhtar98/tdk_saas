import 'package:bracket_generator/features/bracket/domain/entities/bracket_entity.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_layout.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';

/// Abstract engine for calculating visual bracket layouts.
abstract class BracketLayoutEngine {
  /// Calculates the layout for a given bracket and its matches.
  BracketLayout calculateLayout({
    required BracketEntity bracket,
    required List<MatchEntity> matches,
    required BracketLayoutOptions options,
  });
}
