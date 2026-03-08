
import 'package:flutter/material.dart';
import 'package:bracket_generator/features/bracket/domain/entities/match_entity.dart';
import 'package:bracket_generator/features/participant/domain/entities/participant_entity.dart';

class MatchCardWidget extends StatelessWidget {
  final MatchEntity match;
  final Map<String, ParticipantEntity> participantMap;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final Size? size;

  const MatchCardWidget({
    required this.match,
    required this.participantMap,
    required this.isHighlighted,
    super.key,
    this.onTap,
    this.size,
  });

  String _name(String? id) {
    if (id == null) return 'BYE';
    final p = participantMap[id];
    if (p == null) return 'TBD';
    return p.lastName.isNotEmpty ? p.lastName : p.firstName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderColor = switch (match.status) {
      MatchStatus.ready => colorScheme.primary,
      MatchStatus.inProgress => Colors.amber,
      MatchStatus.completed => Colors.green,
      MatchStatus.cancelled => Colors.red,
      MatchStatus.pending => colorScheme.outline,
    };

    final isBye =
        match.resultType == MatchResultType.bye ||
        (match.participantRedId == null && match.participantBlueId != null) ||
        (match.participantRedId != null && match.participantBlueId == null);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size?.width ?? 200,
        height: size?.height ?? 80,
        child: Card(
          elevation: isHighlighted ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isHighlighted ? colorScheme.primary : borderColor,
              width: isHighlighted ? 2 : 1,
              style: isBye ? BorderStyle.none : BorderStyle.solid,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildCardContent(theme, colorScheme, borderColor),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    ThemeData theme,
    ColorScheme colorScheme,
    Color borderColor,
  ) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'M${match.matchNumberInRound}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        // Participants
        Expanded(
          child: Column(
            children: [
              _buildParticipantRow(
                theme,
                match.participantRedId,
                match.winnerId != null &&
                    match.winnerId == match.participantRedId,
                isRed: true,
              ),
              const Divider(height: 1),
              _buildParticipantRow(
                theme,
                match.participantBlueId,
                match.winnerId != null &&
                    match.winnerId == match.participantBlueId,
                isRed: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantRow(
    ThemeData theme,
    String? participantId,
    bool isWinner, {
    required bool isRed,
  }) {
    final displayName = _name(participantId);
    final isEmptySlot = participantId == null;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isWinner ? Colors.amber.withValues(alpha: 0.1) : null,
        child: Row(
          children: [
            Icon(
              Icons.person,
              size: 14,
              color: isRed ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isEmptySlot ? FontStyle.italic : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWinner)
              const Icon(Icons.check_circle, size: 14, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
