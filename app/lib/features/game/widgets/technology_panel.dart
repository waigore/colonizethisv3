import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';

/// Technology panel (UXD 03k). Shows researched techs and research slots for a player.
class TechnologyPanel extends StatelessWidget {
  const TechnologyPanel({
    super.key,
    required this.game,
    required this.player,
    this.currentOrders = const Orders(),
    this.onOrdersChanged,
  });

  final Game game;
  final Player player;
  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  @override
  Widget build(BuildContext context) {
    final techUnlocked = player.techUnlocked ?? {};
    final researchedIds = techUnlocked.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) {
        final ta = techById(a);
        final tb = techById(b);
        final eraA = ta?.era ?? 999;
        final eraB = tb?.era ?? 999;
        final eraCmp = eraA.compareTo(eraB);
        if (eraCmp != 0) return eraCmp;
        return techDisplayName(a).compareTo(techDisplayName(b));
      });
    final progress = player.researchProgressByTechId ?? {};
    final slots = player.researchSlots ?? 3;
    final humanPlayerId = player.id;
    final researchOrdersForPlayer =
        currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
            const <ResearchOrder>[];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CtPanel(
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
              'Research slots',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Column(
              children: List.generate(slots, (index) {
                ResearchOrder? order;
                for (final o in researchOrdersForPlayer) {
                  if (o.slotIndex == index) {
                    order = o;
                  }
                }
                final techId = order?.techId.isNotEmpty == true
                    ? order!.techId
                    : null;
                final tech = techId != null ? techById(techId) : null;
                final displayName = techId != null
                    ? techDisplayName(techId)
                    : 'Empty';
                final techProgress =
                    techId != null ? (progress[techId] ?? 0) : 0;
                final cost = tech?.cost ?? 0;
                final hasTech = techId != null;
                final canEdit = onOrdersChanged != null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Slot ${index + 1}'),
                  subtitle: hasTech
                      ? Text(
                          '$displayName · ${techProgress}/${cost > 0 ? cost : '—'} RP',
                        )
                      : const Text('No tech assigned'),
                  trailing: canEdit
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasTech)
                              CtNinePatchButton(
                                onPressed: () {
                                  _cancelSlot(
                                    context: context,
                                    slotIndex: index,
                                    humanPlayerId: humanPlayerId,
                                    currentOrders: currentOrders,
                                    onOrdersChanged: onOrdersChanged!,
                                  );
                                },
                                child: const Text('Cancel'),
                              ),
                            const SizedBox(width: 4),
                            CtNinePatchButton(
                              onPressed: () {
                                _showAssignDialog(
                                  context: context,
                                  game: game,
                                  slotIndex: index,
                                  humanPlayerId: humanPlayerId,
                                  currentOrders: currentOrders,
                                  player: player,
                                  onOrdersChanged: onOrdersChanged!,
                                );
                              },
                              child: const Text('Choose tech'),
                            ),
                          ],
                        )
                      : null,
                );
              }),
            ),
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).dividerColor),
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
                    .map(
                      (id) => Chip(
                        label: Text(techDisplayName(id)),
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
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
                    '${techDisplayName(e.key)}: ${e.value} RP',
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

void _showAssignDialog({
  required BuildContext context,
  required Game game,
  required int slotIndex,
  required String humanPlayerId,
  required Orders currentOrders,
  required Player player,
  required void Function(Orders orders) onOrdersChanged,
}) {
  final techUnlocked = player.techUnlocked ?? {};
  final existingOrders =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
          const <ResearchOrder>[];
  final currentlyAssignedIds = existingOrders
      .where((o) => o.techId.isNotEmpty)
      .map((o) => o.techId)
      .toSet();

  final researchableIds = researchableTechIds(
    techUnlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, player.id, r),
  );
  final choosableIds = researchableIds
      .where((id) => !currentlyAssignedIds.contains(id))
      .toList();
  final availableTechs = choosableIds
      .map((id) => techById(id))
      .whereType<TechDefinition>()
      .toList()
    ..sort((a, b) {
      final eraCmp = a.era.compareTo(b.era);
      if (eraCmp != 0) return eraCmp;
      return techDisplayName(a.id).compareTo(techDisplayName(b.id));
    });

  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) {
      if (availableTechs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No techs available to research'),
        );
      }
      return ListView.builder(
        itemCount: availableTechs.length,
        itemBuilder: (context, index) {
          final tech = availableTechs[index];
          return ListTile(
            title: Text(techDisplayName(tech.id)),
            subtitle: Text(
              'Era ${_eraRoman(tech.era)} · ${_categoryLabel(tech.category)} · ${tech.cost} RP',
            ),
            onTap: () {
              final updatedOrders = _assignTechToSlot(
                currentOrders: currentOrders,
                humanPlayerId: humanPlayerId,
                slotIndex: slotIndex,
                techId: tech.id,
                existingOrders: existingOrders,
              );
              onOrdersChanged(updatedOrders);
              Navigator.of(ctx).pop();
            },
          );
        },
      );
    },
  );
}

Orders _assignTechToSlot({
  required Orders currentOrders,
  required String humanPlayerId,
  required int slotIndex,
  required String techId,
  required List<ResearchOrder> existingOrders,
}) {
  final ordersForPlayer = List<ResearchOrder>.from(existingOrders);
  final existingIndex =
      ordersForPlayer.indexWhere((o) => o.slotIndex == slotIndex);
  final funding = existingIndex >= 0
      ? ordersForPlayer[existingIndex].funding
      : ResearchFundingLevel.medium;
  final newOrder = ResearchOrder(
    slotIndex: slotIndex,
    techId: techId,
    funding: funding,
  );
  if (existingIndex >= 0) {
    ordersForPlayer[existingIndex] = newOrder;
  } else {
    ordersForPlayer.add(newOrder);
  }

  final updatedMap = {
    ...currentOrders.researchOrdersByPlayerId,
    humanPlayerId: ordersForPlayer,
  };
  return currentOrders.copyWith(researchOrdersByPlayerId: updatedMap);
}

void _cancelSlot({
  required BuildContext context,
  required int slotIndex,
  required String humanPlayerId,
  required Orders currentOrders,
  required void Function(Orders orders) onOrdersChanged,
}) {
  final existingOrders =
      currentOrders.researchOrdersByPlayerId[humanPlayerId] ??
          const <ResearchOrder>[];
  final remaining = existingOrders
      .where((o) => o.slotIndex != slotIndex)
      .toList(growable: false);
  final updatedMap = {
    ...currentOrders.researchOrdersByPlayerId,
    humanPlayerId: remaining,
  };
  final updated = currentOrders.copyWith(
    researchOrdersByPlayerId: updatedMap,
  );
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    const SnackBar(content: Text('Research slot cancelled')),
  );
  onOrdersChanged(updated);
}

String _categoryLabel(String category) {
  const labels = {
    'gathering': 'Gathering',
    'transport': 'Transport',
    'labour': 'Labour',
    'civilian': 'Civilian',
    'diplomacy': 'Diplomacy',
    'naval': 'Naval',
    'military': 'Military',
    'new-world': 'New World',
  };
  return labels[category] ?? category;
}

String _eraRoman(int era) {
  const romans = ['I', 'II', 'III', 'IV'];
  return era >= 1 && era <= romans.length ? romans[era - 1] : '$era';
}
