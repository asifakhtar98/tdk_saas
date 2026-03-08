import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_layout.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';
import 'package:bracket_generator/features/bracket/presentation/widgets/bracket_connection_lines_widget.dart';
import 'package:bracket_generator/features/bracket/presentation/widgets/match_card_widget.dart';
import 'package:bracket_generator/features/bracket/presentation/widgets/round_label_widget.dart';
import 'package:bracket_generator/features/participant/domain/entities/participant_entity.dart';

class BracketViewerWidget extends StatelessWidget {
  final BracketLayout layout;
  final List<MatchEntity> matches;
  final List<ParticipantEntity> participants;
  final String? selectedMatchId;
  final ValueChanged<String> onMatchTap;

  const BracketViewerWidget({
    required this.layout,
    required this.matches,
    required this.participants,
    required this.onMatchTap,
    super.key,
    this.selectedMatchId,
  });

  @override
  Widget build(BuildContext context) {
    final matchMap = {for (final m in matches) m.id: m};
    final participantMap = {for (final p in participants) p.id: p};

    if (layout.rounds.isEmpty) {
      return const Center(child: Text('No bracket rounds to display.'));
    }

    // Calculate a safe canvas size based on actual slot positions
    double maxX = 0;
    double maxY = 0;
    for (final round in layout.rounds) {
      for (final slot in round.matchSlots) {
        final rightEdge = slot.position.dx + slot.size.width;
        final bottomEdge = slot.position.dy + slot.size.height;
        if (rightEdge.isFinite) maxX = max(maxX, rightEdge);
        if (bottomEdge.isFinite) maxY = max(maxY, bottomEdge);
      }
    }

    final safeWidth = max(500.0, maxX + 64);
    final safeHeight = max(300.0, maxY + 80);

    return SizedBox(
      width: safeWidth,
      height: safeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom layer: connector lines
          BracketConnectionLinesWidget(
            layout: layout,
          ),

          // Middle layer: match cards
          for (final round in layout.rounds)
            for (final slot in round.matchSlots)
              if (matchMap.containsKey(slot.matchId) &&
                  slot.position.dx.isFinite &&
                  slot.position.dy.isFinite)
                Positioned(
                  left: slot.position.dx,
                  top: slot.position.dy + 30, // Offset for labels
                  child: MatchCardWidget(
                    match: matchMap[slot.matchId]!,
                    participantMap: participantMap,
                    isHighlighted: slot.matchId == selectedMatchId,
                    onTap: () => onMatchTap(slot.matchId),
                    size: slot.size,
                  ),
                ),

          // Top layer: round labels
          for (final round in layout.rounds)
            if (round.matchSlots.isNotEmpty &&
                round.xPosition.isFinite)
              Positioned(
                left: round.xPosition,
                top: 0,
                width: round.matchSlots.first.size.width,
                child: Center(
                  child: RoundLabelWidget(label: round.roundLabel),
                ),
              ),
        ],
      ),
    );
  }
}
