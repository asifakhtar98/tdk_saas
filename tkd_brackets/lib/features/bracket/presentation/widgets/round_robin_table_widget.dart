import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/bracket/domain/entities/match_entity.dart';

class RoundRobinTableWidget extends StatelessWidget {
  final List<MatchEntity> matches;

  const RoundRobinTableWidget({required this.matches, super.key});

  @override
  Widget build(BuildContext context) {
    final participants = <String>{};
    for (final match in matches) {
      if (match.participantRedId != null) {
        participants.add(match.participantRedId!);
      }
      if (match.participantBlueId != null) {
        participants.add(match.participantBlueId!);
      }
    }
    final participantList = participants.toList()..sort();

    if (participantList.isEmpty) {
      return const Center(child: Text('No participants in this pool'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pool Standings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Table(
                defaultColumnWidth: const FixedColumnWidth(120),
                border: TableBorder.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                children: [
                  // Header Row
                  TableRow(
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(''),
                        ),
                      ),
                      ...participantList.map(
                        (p) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data Rows
                  ...participantList.map((rowP) {
                    return TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              rowP,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        ...participantList.map((colP) {
                          if (rowP == colP) {
                            return const TableCell(
                              child: ColoredBox(
                                color: Colors.grey,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    '--',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }
                          final match = matches.cast<MatchEntity?>().firstWhere(
                            (m) =>
                                (m!.participantRedId == rowP &&
                                    m.participantBlueId == colP) ||
                                (m.participantRedId == colP &&
                                    m.participantBlueId == rowP),
                            orElse: () => null,
                          );
                          return TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                match?.status.name ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
