import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

class MatchCardWidget extends StatelessWidget {
  final MatchEntity match;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final Size? size;

  const MatchCardWidget({
    required this.match,
    required this.isHighlighted,
    super.key,
    this.onTap,
    this.size,
  });

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
          child: isBye
              ? CustomPaint(
                  foregroundPainter: _DashedBorderPainter(
                    color: Colors.grey.shade400,
                    borderRadius: 8,
                  ),
                  child: _buildCardContent(theme, colorScheme, borderColor),
                )
              : _buildCardContent(theme, colorScheme, borderColor),
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
                participantId ?? (isWinner ? '' : 'BYE'),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  fontStyle: participantId == null ? FontStyle.italic : null,
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

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, required this.borderRadius});

  static const _dashWidth = 5.0;
  static const _dashSpace = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dashWidth, metric.length);
        dashPath.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + _dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
