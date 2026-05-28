// Order helpers + Choose-tech bottom sheet for `TechnologyPanel`.
// Split out of `technology_panel.dart` to keep that file under the
// 700-line `repo.game_widgets_file_size` cap (Refs #2864 S2/S3 + repo
// lint cap).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../utils/tech_ui_helpers.dart';

/// Opens the bottom sheet that lists choosable techs for [slotIndex] and
/// dispatches `onOrdersChanged` with the updated `Orders` when the user
/// picks a row. Empty-state message is `"No techs available to research"`.
void showChooseTechBottomSheet({
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
          padding: const EdgeInsets.all(16),
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
              final updatedOrders = applyAssignTechToSlot(
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

/// Returns an `Orders` value with `slotIndex` set to [techId] for
/// [humanPlayerId]. Funding for the slot is preserved when an order
/// already exists there, otherwise defaults to `ResearchFundingLevel.medium`.
Orders applyAssignTechToSlot({
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

/// Removes the `ResearchOrder` at [slotIndex] for [humanPlayerId], shows
/// a transient snackbar confirmation when a `ScaffoldMessenger` is in
/// scope, and dispatches the updated `Orders` via `onOrdersChanged`.
void applyCancelSlotOrder({
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
