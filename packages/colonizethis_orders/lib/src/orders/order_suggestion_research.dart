import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_suggestion_context.dart';
import 'order_suggestion_research_diversify.dart';

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
/// real treasury-aware funding.
///
/// When [categoryDiversifyWeight] is `> 0` (Full-AI only; defaults to `0` for
/// human / simple-AI / tooling callers, preserving pure greedy selection), free
/// slot 0 keeps the greedy pick while free slots `>= 1` prefer the highest-weight
/// AI category bucket not yet represented by lower slots, via a deterministic
/// per-slot blend keyed by [researchSeed] `+ slotIndex`. The four
/// `research*Weight` parameters supply the bucket weights (`researchNaval` ←
/// `naval`/`transport`; `researchMilitary` ← `military`; `researchEconomic` ←
/// `gathering`/`labour`; `researchExploration` ← `new-world`/`diplomatic` +
/// fallback). SPEC/program/order-suggestions.md § Research orders. Refs #3472.
List<ResearchOrder> suggestResearchOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  int researchNavalWeight = 0,
  int researchMilitaryWeight = 0,
  int researchEconomicWeight = 0,
  int researchExplorationWeight = 0,
  int researchSeed = 0,
  int categoryDiversifyWeight = 0,
}) {
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
      currentOrders.researchOrdersByPlayerId[playerId] ??
      const <ResearchOrder>[];
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

  // New (non-in-progress) researchable techs, greedy `era → cost → id` order,
  // excluding ids already assigned to pending orders / in-progress slots.
  final pool = <TechDefinition>[
    for (final tech in candidates)
      if (!assignedTechIds.contains(tech.id)) tech,
  ];
  if (inProgressTechIds.isEmpty && pool.isEmpty) return suggestions;

  // Free slot indices (lowest first) not already taken by pending orders.
  final freeSlots = <int>[];
  for (var i = 0; i < slots; i++) {
    if (!pendingSlots.contains(i)) freeSlots.add(i);
  }

  // Full-AI category diversification (Refs #3472): off when weight <= 0, which
  // is the default for human / simple-AI / tooling callers (pure greedy).
  final diversify = categoryDiversifyWeight > 0;
  final bucketWeights = <ResearchAiBucket, int>{
    ResearchAiBucket.naval: researchNavalWeight,
    ResearchAiBucket.military: researchMilitaryWeight,
    ResearchAiBucket.economic: researchEconomicWeight,
    ResearchAiBucket.exploration: researchExplorationWeight,
  };

  // Buckets already represented by lower slots (pending orders + assignments
  // made earlier in this pass) so slots >= 1 can prefer an unrepresented one.
  final represented = <ResearchAiBucket>{};
  for (final o in existingForPlayer) {
    final tech = techCatalog[o.techId];
    if (tech != null) {
      represented.add(researchBucketForCategory(tech.category));
    }
  }

  var inProgressCursor = 0;
  for (final slot in freeSlots) {
    String? techId;
    if (inProgressCursor < inProgressTechIds.length) {
      techId = inProgressTechIds[inProgressCursor++];
    } else if (pool.isNotEmpty) {
      techId = pickDiversifiedResearchTech(
        slotIndex: slot,
        pool: pool,
        diversify: diversify,
        bucketWeights: bucketWeights,
        represented: represented,
        researchSeed: researchSeed,
        diversifyWeight: categoryDiversifyWeight,
      );
      pool.removeWhere((t) => t.id == techId);
    } else {
      break;
    }
    final tech = techCatalog[techId];
    if (tech != null) {
      represented.add(researchBucketForCategory(tech.category));
    }
    suggestions.add(
      ResearchOrder(
        slotIndex: slot,
        techId: techId,
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
