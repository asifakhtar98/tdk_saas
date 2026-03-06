import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/division/domain/entities/division_entity.dart';

class BracketFormatSelectionDialog extends StatelessWidget {
  const BracketFormatSelectionDialog({super.key});

  static Future<BracketFormat?> show(BuildContext context) {
    return showModalBottomSheet<BracketFormat>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const BracketFormatSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Bracket Format',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_tree),
            title: const Text('Single Elimination'),
            subtitle: const Text('Standard knockout format'),
            onTap: () => Navigator.of(context).pop(BracketFormat.singleElimination),
          ),
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text('Double Elimination'),
            subtitle: const Text('Winners + losers bracket'),
            onTap: () => Navigator.of(context).pop(BracketFormat.doubleElimination),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Round Robin'),
            subtitle: const Text('Everyone plays everyone'),
            onTap: () => Navigator.of(context).pop(BracketFormat.roundRobin),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
