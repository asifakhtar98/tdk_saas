import 'package:flutter/material.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_layout.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';
import 'package:bracket_generator/features/bracket/presentation/widgets/bracket_connection_lines_widget.dart';
import 'package:bracket_generator/features/bracket/presentation/widgets/match_card_widget.dart';
import 'package:bracket_generator/features/bracket/presentation/widgets/round_label_widget.dart';

class BracketViewerWidget extends StatelessWidget {
  final BracketLayout layout;
  final List<MatchEntity> matches;
  final String? selectedMatchId;
  final ValueChanged<String> onMatchTap;

  const BracketViewerWidget({
    required this.layout,
    required this.matches,
    required this.onMatchTap,
    super.key,
    this.selectedMatchId,
  });

  @override
  Widget build(BuildContext context) {
    final matchMap = {for (final m in matches) m.id: m};

    return InteractiveViewer(
      constrained: false,
      minScale: 0.25,
      maxScale: 2,
      boundaryMargin: const EdgeInsets.all(100),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: layout.canvasSize.width,
          height: layout.canvasSize.height + 40, // Extra space for labels
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom layer: lines
              BracketConnectionLinesWidget(layout: layout),

              // Middle layer: match cards
              for (final round in layout.rounds)
                for (final slot in round.matchSlots)
                  if (matchMap.containsKey(slot.matchId))
                    Positioned(
                      left: slot.position.dx,
                      top: slot.position.dy + 30, // Offset for labels
                      child: MatchCardWidget(
                        match: matchMap[slot.matchId]!,
                        isHighlighted: slot.matchId == selectedMatchId,
                        onTap: () => onMatchTap(slot.matchId),
                        size: slot.size,
                      ),
                    ),

              // Top layer: round labels
              for (final round in layout.rounds)
                Positioned(
                  left: round.xPosition,
                  top: 0,
                  width: layout.rounds.first.matchSlots.first.size.width,
                  child: Center(
                    child: RoundLabelWidget(label: round.roundLabel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
