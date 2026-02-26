import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

/// Technology panel (UXD 03k). Shows researched techs and research slots for a player.
class TechnologyPanel extends StatelessWidget {
  const TechnologyPanel({
    super.key,
    required this.game,
    required this.player,
  });

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final techUnlocked = player.techUnlocked ?? {};
    final researchedIds = techUnlocked.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList()
      ..sort();
    final progress = player.researchProgressByTechId ?? {};
    final slots = player.researchSlots ?? 3;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technology — ${player.displayName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Research slots: $slots'),
            const SizedBox(height: 8),
            Text(
              'Researched (${researchedIds.length}):',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            if (researchedIds.isEmpty)
              const Text('None yet')
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: researchedIds
                    .map((id) => Chip(
                          label: Text(id),
                          labelStyle: Theme.of(context).textTheme.bodySmall,
                        ))
                    .toList(),
              ),
            if (progress.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'In progress:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ...progress.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${e.key}: ${e.value} pts',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
