import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_suggestion_context.dart';

/// Default research slot count when [Player.researchSlots] is null.
/// SPEC/game/research-state.md (default 3, 4 with University).
const int _defaultResearchSlots = 3;

/// Suggests research orders for [view.playerId], one per assignable slot.
///
/// Enumerates the player's active research slots (`0 .. researchSlots-1`) and
/// returns at most one funding-agnostic [ResearchOrder] per slot. In-progress
/// research (techs with accumulated progress that are not yet unlocked) is
/// re-emitted first so the turn resolver preserves that progress; remaining
/// empty slots are filled with distinct researchable techs in greedy
/// `era → cost → id` order. Funding is a placeholder
/// ([ResearchFundingLevel.medium]); the Full-AI research planner applies the
/// real treasury-aware funding. SPEC/program/order-suggestions.md § Research
/// orders. Refs #3472.
List<ResearchOrder> suggestResearchOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  orderSuggestionLog.d('suggestResearchOrders player=${view.playerId}');
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <ResearchOrder>[];

  final slots = player.researchSlots ?? _defaultResearchSlots;
  if (slots <= 0) return suggestions;

  final unlocked = player.techUnlocked ?? const <String, bool>{};

  // Slots already taken by pending research orders this turn keep their
  // assignment; their tech ids are excluded from new suggestions.
  final pendingSlots = <int>{};
  final assignedTechIds = <String>{};
  final existingForPlayer =
      currentOrders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
  for (final o in existingForPlayer) {
    pendingSlots.add(o.slotIndex);
    if (o.techId.isNotEmpty) assignedTechIds.add(o.techId);
  }

  // In-progress techs (progress > 0, not yet unlocked, still valid) must be
  // re-emitted so the resolver does not drop their accumulated progress.
  final progress = player.researchProgressByTechId ?? const <String, int>{};
  final inProgressTechIds = <String>[];
  for (final entry in progress.entries) {
    if (entry.value <= 0) continue;
    if (unlocked[entry.key] == true) continue;
    final tech = techCatalog[entry.key];
    if (tech == null) continue;
    if (tech.cost > 0 && entry.value >= tech.cost) continue;
    if (assignedTechIds.contains(entry.key)) continue;
    inProgressTechIds.add(entry.key);
  }
  inProgressTechIds.sort();
  assignedTechIds.addAll(inProgressTechIds);

  // Researchable techs (discovery-gated) sorted greedily by era, cost, id.
  final researchableIds = researchableTechIds(
    unlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, playerId, r),
  );
  final candidates = <TechDefinition>[];
  for (final id in researchableIds) {
    final tech = techCatalog[id];
    if (tech != null) candidates.add(tech);
  }
  candidates.sort((a, b) {
    final eraCmp = a.era.compareTo(b.era);
    if (eraCmp != 0) return eraCmp;
    final costCmp = a.cost.compareTo(b.cost);
    if (costCmp != 0) return costCmp;
    return a.id.compareTo(b.id);
  });

  // Techs to assign: in-progress first (preserve), then distinct greedy techs.
  final toAssign = <String>[...inProgressTechIds];
  for (final tech in candidates) {
    if (assignedTechIds.contains(tech.id)) continue;
    toAssign.add(tech.id);
    assignedTechIds.add(tech.id);
  }
  if (toAssign.isEmpty) return suggestions;

  // Free slot indices (lowest first) not already taken by pending orders.
  final freeSlots = <int>[];
  for (var i = 0; i < slots; i++) {
    if (!pendingSlots.contains(i)) freeSlots.add(i);
  }

  final count = freeSlots.length < toAssign.length
      ? freeSlots.length
      : toAssign.length;
  for (var k = 0; k < count; k++) {
    suggestions.add(
      ResearchOrder(
        slotIndex: freeSlots[k],
        techId: toAssign[k],
        funding: ResearchFundingLevel.medium,
      ),
    );
  }

  orderSuggestionLog.d(
    'suggestResearchOrders player=$playerId slots=$slots '
    'inProgress=${inProgressTechIds.length} suggested=${suggestions.length}',
  );
  return suggestions;
}
