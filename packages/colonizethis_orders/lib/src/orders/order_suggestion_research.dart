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
  final bucketWeights = <_AiBucket, int>{
    _AiBucket.naval: researchNavalWeight,
    _AiBucket.military: researchMilitaryWeight,
    _AiBucket.economic: researchEconomicWeight,
    _AiBucket.exploration: researchExplorationWeight,
  };

  // Buckets already represented by lower slots (pending orders + assignments
  // made earlier in this pass) so slots >= 1 can prefer an unrepresented one.
  final represented = <_AiBucket>{};
  for (final o in existingForPlayer) {
    final tech = techCatalog[o.techId];
    if (tech != null) represented.add(_bucketForCategory(tech.category));
  }

  var inProgressCursor = 0;
  for (final slot in freeSlots) {
    String? techId;
    if (inProgressCursor < inProgressTechIds.length) {
      techId = inProgressTechIds[inProgressCursor++];
    } else if (pool.isNotEmpty) {
      techId = _pickNewTech(
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
    if (tech != null) represented.add(_bucketForCategory(tech.category));
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

/// AI category buckets that group the seven game tech categories for Full-AI
/// research diversification. SPEC/program/order-suggestions.md § Research orders.
enum _AiBucket { naval, military, economic, exploration }

/// Fixed tiebreak order for equal-weight buckets: naval > military > economic >
/// exploration. Also the deterministic iteration order for bucket selection.
const List<_AiBucket> _bucketOrder = <_AiBucket>[
  _AiBucket.naval,
  _AiBucket.military,
  _AiBucket.economic,
  _AiBucket.exploration,
];

/// Maps a game tech category to its AI bucket. Unmapped categories (and
/// `new-world` / `diplomatic` / `civilian`) fall back to exploration.
_AiBucket _bucketForCategory(String category) {
  switch (category) {
    case 'naval':
    case 'transport':
      return _AiBucket.naval;
    case 'military':
      return _AiBucket.military;
    case 'gathering':
    case 'labour':
      return _AiBucket.economic;
    default:
      return _AiBucket.exploration;
  }
}

/// Deterministic 0..99 roll from [seed] (stable pure-int hash; no RNG state).
int _diversifyRoll(int seed) {
  var x = seed & 0x7fffffff;
  x = (x * 1103515245 + 12345) & 0x7fffffff;
  return x % 100;
}

/// Greedy-cheapest tech id for [pool]'s head, or — for slots `>= 1` when
/// [diversify] and the per-slot blend rolls in — the greedy-first tech in the
/// highest-weight AI bucket not yet [represented]. Falls back to greedy when
/// the chosen bucket has no available tech. [pool] is greedy-sorted by caller.
String _pickNewTech({
  required int slotIndex,
  required List<TechDefinition> pool,
  required bool diversify,
  required Map<_AiBucket, int> bucketWeights,
  required Set<_AiBucket> represented,
  required int researchSeed,
  required int diversifyWeight,
}) {
  if (!diversify || slotIndex == 0) return pool.first.id;
  if (_diversifyRoll(researchSeed + slotIndex) >= diversifyWeight) {
    return pool.first.id;
  }
  final bucket = _chooseDiversifiedBucket(
    pool: pool,
    bucketWeights: bucketWeights,
    represented: represented,
  );
  if (bucket == null) return pool.first.id;
  for (final tech in pool) {
    if (_bucketForCategory(tech.category) == bucket) return tech.id;
  }
  return pool.first.id;
}

/// Highest-weight AI bucket that is both unrepresented and has at least one
/// tech in [pool], ties broken by [_bucketOrder]. Null when none qualifies.
_AiBucket? _chooseDiversifiedBucket({
  required List<TechDefinition> pool,
  required Map<_AiBucket, int> bucketWeights,
  required Set<_AiBucket> represented,
}) {
  final available = <_AiBucket>{
    for (final tech in pool) _bucketForCategory(tech.category),
  };
  final candidates = _bucketOrder
      .where((b) => !represented.contains(b) && available.contains(b))
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final byWeight = (bucketWeights[b] ?? 0).compareTo(bucketWeights[a] ?? 0);
    if (byWeight != 0) return byWeight;
    return _bucketOrder.indexOf(a).compareTo(_bucketOrder.indexOf(b));
  });
  return candidates.first;
}
