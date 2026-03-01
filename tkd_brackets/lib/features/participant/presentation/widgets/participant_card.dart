import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';

/// Valid status transitions (from UpdateParticipantStatusUseCase).
const _validTransitions = <ParticipantStatus, List<ParticipantStatus>>{
  ParticipantStatus.pending: [
    ParticipantStatus.checkedIn,
    ParticipantStatus.noShow,
    ParticipantStatus.withdrawn,
    ParticipantStatus.disqualified,
  ],
  ParticipantStatus.checkedIn: [
    ParticipantStatus.withdrawn,
    ParticipantStatus.disqualified,
  ],
  ParticipantStatus.noShow: [ParticipantStatus.pending],
  ParticipantStatus.withdrawn: [ParticipantStatus.pending],
  ParticipantStatus.disqualified: [ParticipantStatus.pending],
};

class ParticipantCard extends StatelessWidget {
  const ParticipantCard({
    required this.participant,
    super.key,
    this.onTap,
    this.onStatusChange,
    this.onEdit,
    this.onDelete,
    this.onTransfer,
  });

  final ParticipantEntity participant;
  final VoidCallback? onTap;
  final ValueChanged<ParticipantStatus>? onStatusChange;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisqualified =
        participant.checkInStatus == ParticipantStatus.disqualified;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Text(participant.firstName[0].toUpperCase()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${participant.firstName} '
                          '${participant.lastName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isDisqualified
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          participant.schoolOrDojangName ?? 'No dojang',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: participant.checkInStatus),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                        case 'transfer':
                          onTransfer?.call();
                        case 'delete':
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'transfer',
                        child: ListTile(
                          leading: Icon(Icons.move_up),
                          title: Text('Transfer'),
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          title: Text(
                            'Remove',
                            style: TextStyle(color: colorScheme.error),
                          ),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (participant.beltRank != null)
                    _InfoChip(
                      label: participant.beltRank!.toUpperCase(),
                      icon: Icons.layers,
                    ),
                  if (participant.beltRank != null) const SizedBox(width: 8),
                  if (participant.weightKg != null) ...[
                    _InfoChip(
                      label: '${participant.weightKg} kg',
                      icon: Icons.monitor_weight_outlined,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (participant.age != null)
                    _InfoChip(
                      label: '${participant.age} yrs',
                      icon: Icons.cake_outlined,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showStatusPicker(context),
                    icon: const Icon(Icons.change_circle_outlined, size: 18),
                    label: const Text('Update Status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    final validTargets = _validTransitions[participant.checkInStatus] ?? [];

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Change Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...validTargets.map((status) {
              return ListTile(
                leading: _StatusBadge(status: status),
                title: Text(_statusDisplayName(status)),
                onTap: () {
                  Navigator.pop(context);
                  onStatusChange?.call(status);
                },
              );
            }),
            if (validTargets.isEmpty)
              const ListTile(
                leading: Icon(Icons.block),
                title: Text('No transitions available'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusDisplayName(ParticipantStatus status) {
    return switch (status) {
      ParticipantStatus.pending => 'Mark as Pending',
      ParticipantStatus.checkedIn => 'Check In',
      ParticipantStatus.noShow => 'Mark No-Show',
      ParticipantStatus.withdrawn => 'Withdraw',
      ParticipantStatus.disqualified => 'Disqualify',
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ParticipantStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(ParticipantStatus status) {
    return switch (status) {
      ParticipantStatus.pending => Colors.grey,
      ParticipantStatus.checkedIn => const Color(0xFF388E3C),
      ParticipantStatus.noShow => const Color(0xFFF57C00),
      ParticipantStatus.withdrawn => Colors.blueGrey,
      ParticipantStatus.disqualified => const Color(0xFFD32F2F),
    };
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
