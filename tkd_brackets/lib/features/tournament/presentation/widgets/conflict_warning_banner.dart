import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/division/domain/entities/conflict_warning.dart';

class ConflictWarningBanner extends StatelessWidget {
  const ConflictWarningBanner({
    required this.conflicts,
    super.key,
    this.onDismiss,
  });

  final List<ConflictWarning> conflicts;
  final void Function(String conflictId)? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${conflicts.length} scheduling conflict${conflicts.length > 1 ? 's' : ''} detected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                if (conflicts.length == 1 && onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => onDismiss?.call(conflicts.first.id),
                    tooltip: 'Dismiss',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...conflicts
                .take(3)
                .map((conflict) => _buildConflictItem(context, conflict)),
            if (conflicts.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${conflicts.length - 3} more',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictItem(BuildContext context, ConflictWarning conflict) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: conflict.participantName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' is in both '),
                  TextSpan(
                    text: conflict.divisionName1,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: conflict.divisionName2,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' on ring ${conflict.ringNumber1}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
