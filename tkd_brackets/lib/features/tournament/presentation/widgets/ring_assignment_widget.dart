import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

class RingAssignmentWidget extends StatelessWidget {
  const RingAssignmentWidget({
    super.key,
    required this.ringCount,
    required this.divisions,
    required this.onDivisionMoved,
  });

  final int ringCount;
  final List<DivisionEntity> divisions;
  final void Function(String divisionId, int? ringNumber)? onDivisionMoved;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final divisionsByRing = <int?, List<DivisionEntity>>{};
    for (int i = 1; i <= ringCount; i++) {
      divisionsByRing[i] = [];
    }
    divisionsByRing[null] = [];

    for (final division in divisions) {
      final ring = division.assignedRingNumber;
      divisionsByRing[ring]?.add(division);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int ring = 1; ring <= ringCount; ring++) ...[
            _buildRingColumn(context, ring, divisionsByRing[ring] ?? []),
            const SizedBox(width: 16),
          ],
          _buildUnassignedColumn(context, divisionsByRing[null] ?? []),
        ],
      ),
    );
  }

  Widget _buildRingColumn(
    BuildContext context,
    int ringNumber,
    List<DivisionEntity> divisions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['divisionId'] != null && data['fromRing'] != ringNumber) {
          onDivisionMoved?.call(data['divisionId'] as String, ringNumber);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Container(
          width: 200,
          decoration: BoxDecoration(
            color: isHighlighted
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isHighlighted
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Ring $ringNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: divisions
                      .map(
                        (division) =>
                            _buildDivisionCard(context, division, ringNumber),
                      )
                      .toList(),
                ),
              ),
              if (divisions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Drop divisions here',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnassignedColumn(
    BuildContext context,
    List<DivisionEntity> divisions,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Unassigned',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: divisions
                  .map(
                    (division) => _buildDivisionCard(context, division, null),
                  )
                  .toList(),
            ),
          ),
          if (divisions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No unassigned divisions',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivisionCard(
    BuildContext context,
    DivisionEntity division,
    int? ringNumber,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Draggable<Map<String, dynamic>>(
      data: {'divisionId': division.id, 'fromRing': ringNumber},
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            division.name,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildDivisionCardContent(context, division),
      ),
      child: _buildDivisionCardContent(context, division),
    );
  }

  Widget _buildDivisionCardContent(
    BuildContext context,
    DivisionEntity division,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            division.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${division.category.value} • ${division.gender.value}',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Order: ${division.displayOrder}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
