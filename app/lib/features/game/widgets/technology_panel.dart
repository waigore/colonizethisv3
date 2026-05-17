import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../utils/tech_ui_helpers.dart';
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
    final l10n = appL10n(context);
    final researchedIds = _sortedResearchedTechIds();
    final progress = player.researchProgressByTechId ?? const <String, int>{};
    final slots = player.researchSlots ?? 3;
    final humanPlayerId = player.id;
    final researchOrdersForPlayer = _researchOrdersForPlayer(humanPlayerId);
    final canEdit = onOrdersChanged != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CtPanel(
        padding: const EdgeInsets.all(16),
        child: _buildPanelContent(
          context: context,
          l10n: l10n,
          researchedIds: researchedIds,
          progress: progress,
          slots: slots,
          humanPlayerId: humanPlayerId,
          researchOrdersForPlayer: researchOrdersForPlayer,
          canEdit: canEdit,
        ),
      ),
    );
  }

  Widget _buildPanelContent({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<String> researchedIds,
    required Map<String, int> progress,
    required int slots,
    required String humanPlayerId,
    required List<ResearchOrder> researchOrdersForPlayer,
    required bool canEdit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.technologyPanel_title(player.displayName),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.technologyPanel_researchSlotsCount(slots)),
        const SizedBox(height: 8),
        Text(
          l10n.technologyPanel_researchSlots,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Column(
          children: List.generate(
            slots,
            (index) => _buildResearchSlotTile(
              context: context,
              l10n: l10n,
              index: index,
              progress: progress,
              humanPlayerId: humanPlayerId,
              researchOrdersForPlayer: researchOrdersForPlayer,
              canEdit: canEdit,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 8),
        Text(
          l10n.technologyPanel_researched(researchedIds.length),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        if (researchedIds.isEmpty)
          Text(l10n.technologyPanel_noneYet)
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
            l10n.technologyPanel_inProgress,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          ...progress.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.technologyPanel_progressLine(
                  techDisplayName(entry.key),
                  entry.value,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _sortedResearchedTechIds() {
    final techUnlocked = player.techUnlocked ?? const <String, bool>{};
    final researchedIds = techUnlocked.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    researchedIds.sort(_sortTechIdsByEraThenName);
    return researchedIds;
  }

  int _sortTechIdsByEraThenName(String a, String b) {
    final eraA = techById(a)?.era ?? 999;
    final eraB = techById(b)?.era ?? 999;
    final eraCmp = eraA.compareTo(eraB);
    if (eraCmp != 0) {
      return eraCmp;
    }
    return techDisplayName(a).compareTo(techDisplayName(b));
  }

  List<ResearchOrder> _researchOrdersForPlayer(String playerId) {
    return currentOrders.researchOrdersByPlayerId[playerId] ??
        const <ResearchOrder>[];
  }

  Widget _buildResearchSlotTile({
    required BuildContext context,
    required AppLocalizations l10n,
    required int index,
    required Map<String, int> progress,
    required String humanPlayerId,
    required List<ResearchOrder> researchOrdersForPlayer,
    required bool canEdit,
  }) {
    final order = _researchOrderForSlot(researchOrdersForPlayer, index);
    final techId = _slotTechId(order);
    final tech = techId == null ? null : techById(techId);
    final displayName = techId == null
        ? l10n.technologyPanel_empty
        : techDisplayName(techId);
    final techProgress = techId == null ? 0 : (progress[techId] ?? 0);
    final cost = tech?.cost ?? 0;
    final hasTech = techId != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.technologyPanel_slot(index + 1)),
      subtitle: hasTech
          ? Text(
              l10n.technologyPanel_slotSubtitle(
                displayName,
                techProgress,
                cost > 0 ? '$cost' : '—',
              ),
            )
          : Text(l10n.technologyPanel_noTechAssigned),
      trailing: canEdit
          ? _buildSlotActions(context, l10n, index, humanPlayerId, hasTech)
          : null,
    );
  }

  ResearchOrder? _researchOrderForSlot(List<ResearchOrder> orders, int index) {
    for (final order in orders) {
      if (order.slotIndex == index) {
        return order;
      }
    }
    return null;
  }

  String? _slotTechId(ResearchOrder? order) {
    if (order == null || order.techId.isEmpty) {
      return null;
    }
    return order.techId;
  }

  Widget _buildSlotActions(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    String humanPlayerId,
    bool hasTech,
  ) {
    return Row(
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
            child: Text(l10n.common_cancel),
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
          child: Text(l10n.technologyPanel_chooseTech),
        ),
      ],
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
  final l10n = appL10n(context);
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
  final availableTechs =
      choosableIds
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
        return Padding(
          padding: EdgeInsets.all(16),
          child: Text(l10n.technologyPanel_noTechsAvailable),
        );
      }
      return ListView.builder(
        itemCount: availableTechs.length,
        itemBuilder: (context, index) {
          final tech = availableTechs[index];
          return ListTile(
            title: Text(techDisplayName(tech.id)),
            subtitle: Text(
              l10n.technologyPanel_pickSubtitle(
                eraRoman(tech.era),
                techCategoryLabelL10n(l10n, tech.category),
                tech.cost,
              ),
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
  final existingIndex = ordersForPlayer.indexWhere(
    (o) => o.slotIndex == slotIndex,
  );
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
  final l10n = appL10n(context);
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
  final updated = currentOrders.copyWith(researchOrdersByPlayerId: updatedMap);
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(content: Text(l10n.technologyPanel_slotCancelled)),
  );
  onOrdersChanged(updated);
}
