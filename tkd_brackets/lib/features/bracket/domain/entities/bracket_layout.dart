import 'dart:ui' show Offset, Size;
import 'package:flutter/foundation.dart' show immutable, listEquals;

/// Format of the bracket layout, determining how matches are positioned.
enum BracketFormat { singleElimination, doubleElimination, roundRobin }

/// Represents the full visual layout of a bracket.
@immutable
class BracketLayout {
  final BracketFormat format;
  final List<BracketRound> rounds;
  final Size canvasSize;

  const BracketLayout({
    required this.format,
    required this.rounds,
    required this.canvasSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BracketLayout &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          listEquals(rounds, other.rounds) &&
          canvasSize == other.canvasSize;

  @override
  int get hashCode =>
      format.hashCode ^ Object.hashAll(rounds) ^ canvasSize.hashCode;

  @override
  String toString() =>
      'BracketLayout(format: $format, rounds: ${rounds.length}, canvasSize: $canvasSize)';
}

/// Represents a single round column in the bracket layout.
@immutable
class BracketRound {
  final int roundNumber;
  final String roundLabel;
  final List<MatchSlot> matchSlots;
  final double xPosition;

  const BracketRound({
    required this.roundNumber,
    required this.roundLabel,
    required this.matchSlots,
    required this.xPosition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BracketRound &&
          runtimeType == other.runtimeType &&
          roundNumber == other.roundNumber &&
          roundLabel == other.roundLabel &&
          listEquals(matchSlots, other.matchSlots) &&
          xPosition == other.xPosition;

  @override
  int get hashCode =>
      roundNumber.hashCode ^
      roundLabel.hashCode ^
      Object.hashAll(matchSlots) ^
      xPosition.hashCode;

  @override
  String toString() =>
      'BracketRound(roundNumber: $roundNumber, label: $roundLabel, slots: ${matchSlots.length}, x: $xPosition)';
}

/// Represents a specific slot where a match card is rendered.
@immutable
class MatchSlot {
  final String matchId;
  final Offset position;
  final Size size;
  final MatchSlot? advancesToSlot;

  const MatchSlot({
    required this.matchId,
    required this.position,
    required this.size,
    this.advancesToSlot,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchSlot &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId &&
          position == other.position &&
          size == other.size &&
          advancesToSlot == other.advancesToSlot;

  @override
  int get hashCode =>
      matchId.hashCode ^
      position.hashCode ^
      size.hashCode ^
      advancesToSlot.hashCode;

  @override
  String toString() =>
      'MatchSlot(matchId: $matchId, pos: $position, size: $size)';
}

/// Configuration options for the bracket layout engine.
@immutable
class BracketLayoutOptions {
  final double matchCardWidth;
  final double matchCardHeight;
  final double horizontalSpacing;
  final double verticalSpacing;
  final double connectorLineWidth;
  final bool showByes;

  const BracketLayoutOptions({
    this.matchCardWidth = 200.0,
    this.matchCardHeight = 80.0,
    this.horizontalSpacing = 60.0,
    this.verticalSpacing = 20.0,
    this.connectorLineWidth = 2.0,
    this.showByes = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BracketLayoutOptions &&
          runtimeType == other.runtimeType &&
          matchCardWidth == other.matchCardWidth &&
          matchCardHeight == other.matchCardHeight &&
          horizontalSpacing == other.horizontalSpacing &&
          verticalSpacing == other.verticalSpacing &&
          connectorLineWidth == other.connectorLineWidth &&
          showByes == other.showByes;

  @override
  int get hashCode =>
      matchCardWidth.hashCode ^
      matchCardHeight.hashCode ^
      horizontalSpacing.hashCode ^
      verticalSpacing.hashCode ^
      connectorLineWidth.hashCode ^
      showByes.hashCode;

  @override
  String toString() =>
      'BracketLayoutOptions(cardWidth: $matchCardWidth, cardHeight: $matchCardHeight)';
}
