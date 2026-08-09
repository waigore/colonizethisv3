// Pure helpers for the Production panel Labour controls section.
// SPEC/ui/production-panel.md § Labour Controls, SPEC/game/workers-and-population.md.

export 'production_labour_recruit_economy_mutations.dart';
export 'production_labour_recruit_economy_projection.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'production_labour_recruit_economy_projection.dart';

/// Pure predicate that returns `true` iff every tech id required to recruit
/// or train [tier] (per `SPEC/game/workers-and-population.md` § Tech gates,
/// resolved through [WorkerActionEconomyCatalog.forTier]) is present and
/// `true` in [player]'s `techUnlocked` map. Peasant has no tech gate and
/// therefore always returns `true`.
///
/// Used by the Labour Controls row label parenthetical
/// (`(unlocked)` / `(locked)`) per `SPEC/ui/production-panel.md`
/// § Labour Controls (12-A) — Tech-gate parenthetical. This is a
/// **display-only** signal; the existing `canAppendRecruitWorkerOrder`
/// affordance remains authoritative for the **+** stepper enabled flag and
/// for the resolver's validation chain.
bool isWorkerTierTechUnlocked({
  required Player player,
  required WorkerTier tier,
}) {
  final required = WorkerActionEconomyCatalog.forTier(tier).requiredTechIds;
  if (required.isEmpty) {
    return true;
  }
  final unlocked = player.techUnlocked;
  if (unlocked == null || unlocked.isEmpty) {
    return false;
  }
  for (final id in required) {
    if (unlocked[id] != true) {
      return false;
    }
  }
  return true;
}

/// Render order for the four Labour rows. Peasant first, then trained tiers
/// in tech-tier order — matches the Workers grid above and the worker tier
/// table in SPEC/game/workers-and-population.md § Worker Tiers.
const List<WorkerTier> kProductionLabourTierOrder = <WorkerTier>[
  WorkerTier.peasant,
  WorkerTier.apprentice,
  WorkerTier.journeyman,
  WorkerTier.master,
];

/// Callbacks emitted by Labour controls. The screen wires these to
/// `currentOrdersProvider` (recruit queue) and `currentGameProvider`
/// (immediate disband).
class ProductionLabourCallbacks {
  const ProductionLabourCallbacks({
    required this.onAppendRecruitOrder,
    required this.onPopLastRecruitOrder,
    required this.onDisband,
  });

  /// Append one [RecruitWorkerOrder] at [tier] to the viewed player's queue.
  final void Function(WorkerTier tier) onAppendRecruitOrder;

  /// Remove the last queued [RecruitWorkerOrder] at [tier] (LIFO).
  final void Function(WorkerTier tier) onPopLastRecruitOrder;

  /// Immediately apply disband on one [tier] worker. Peasant is invalid
  /// per SPEC § Disband; callers must filter trained tiers only.
  final void Function(WorkerTier tier) onDisband;
}

/// Inputs needed to render one tier row's stepper + disband controls.
class ProductionLabourTierRowData {
  const ProductionLabourTierRowData({
    required this.tier,
    required this.poolCount,
    required this.queuedCount,
    required this.canAppend,
    required this.canPop,
    required this.canDisband,
    required this.techUnlocked,
  });

  final WorkerTier tier;
  final int poolCount;
  final int queuedCount;
  final bool canAppend;
  final bool canPop;
  final bool canDisband;

  /// Display-only flag mirroring [isWorkerTierTechUnlocked] for [tier] on
  /// the viewed player. Drives the Labour Controls row label parenthetical
  /// (`(unlocked)` / `(locked)`) per `SPEC/ui/production-panel.md`
  /// § Labour Controls (12-A) — Tech-gate parenthetical.
  final bool techUnlocked;
}

/// Pure builder that maps a [Player] + [Orders] snapshot to one row data
/// per tier in canonical render order. Kept side-effect-free so tests can
/// assert affordance and queue counts without mounting the widget.
List<ProductionLabourTierRowData> buildProductionLabourRowData({
  required Player player,
  required Orders currentOrders,
  required bool canEdit,
}) {
  final queued = queuedRecruitWorkerCountsByTier(
    currentOrders: currentOrders,
    playerId: player.id,
  );
  final rows = <ProductionLabourTierRowData>[];
  for (final tier in kProductionLabourTierOrder) {
    final poolCount = workerPoolTierCount(player.workerPool, tier);
    final queuedCount = queued[tier] ?? 0;
    final canAppend = canEdit &&
        canAppendRecruitWorkerOrder(
          player: player,
          currentOrders: currentOrders,
          candidateTier: tier,
        );
    final canPop = canEdit && queuedCount > 0;
    final canDisband =
        canEdit && tier != WorkerTier.peasant && poolCount > 0;
    final techUnlocked = isWorkerTierTechUnlocked(
      player: player,
      tier: tier,
    );
    rows.add(
      ProductionLabourTierRowData(
        tier: tier,
        poolCount: poolCount,
        queuedCount: queuedCount,
        canAppend: canAppend,
        canPop: canPop,
        canDisband: canDisband,
        techUnlocked: techUnlocked,
      ),
    );
  }
  return rows;
}
