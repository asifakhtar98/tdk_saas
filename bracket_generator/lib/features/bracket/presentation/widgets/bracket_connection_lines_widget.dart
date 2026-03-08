import 'package:flutter/material.dart';
import 'package:bracket_generator/features/bracket/domain/entities/bracket_layout.dart';

class BracketConnectionLinesPainter extends CustomPainter {
  final BracketLayout layout;
  final Color lineColor;
  final double lineWidth;

  BracketConnectionLinesPainter({
    required this.layout,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    for (final round in layout.rounds) {
      for (final slot in round.matchSlots) {
        if (slot.advancesToSlot != null) {
          final startX = slot.position.dx + slot.size.width;
          final startY = slot.position.dy + slot.size.height / 2;

          final endX = slot.advancesToSlot!.position.dx;
          final endY =
              slot.advancesToSlot!.position.dy +
              slot.advancesToSlot!.size.height / 2;

          final midX = startX + (endX - startX) / 2;

          final path = Path()
            ..moveTo(startX, startY)
            ..lineTo(midX, startY)
            ..lineTo(midX, endY)
            ..lineTo(endX, endY);

          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectionLinesPainter oldDelegate) {
    return layout != oldDelegate.layout ||
        lineColor != oldDelegate.lineColor ||
        lineWidth != oldDelegate.lineWidth;
  }
}

class BracketConnectionLinesWidget extends StatelessWidget {
  final BracketLayout layout;
  final Color? lineColor;
  final double lineWidth;

  const BracketConnectionLinesWidget({
    required this.layout,
    super.key,
    this.lineColor,
    this.lineWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: layout.canvasSize,
      painter: BracketConnectionLinesPainter(
        layout: layout,
        lineColor: lineColor ?? Theme.of(context).colorScheme.outlineVariant,
        lineWidth: lineWidth,
      ),
    );
  }
}
