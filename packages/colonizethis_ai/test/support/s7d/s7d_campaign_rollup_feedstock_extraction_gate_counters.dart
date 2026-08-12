// Feedstock-extraction gate execution-gap counters (Refs #4310 Slice A).
library;

import 'package:colonizethis_data/colonizethis_data.dart';

/// Builder routing, improvement affordability, and acquisition-thread counters.
mixin Seed42S7dCampaignRollupFeedstockExtractionGateCounters {
  List<String> get gpIds;

  // Refs #2847 H8-extraction execution-gap disambiguation (read-only).
  // Both are gated on a feedstock-extraction-gate-active turn so they split
  // the 29-52 gate-active turns into the proximate failure stage:
  //   * `feedstockGateIdleBuilderPresentTurns` — a free Builder exists to
  //     route (rules out "no Builder available");
  //   * `feedstockGateImprovedTileOwnedTurns` — the routed Builder has
  //     actually finished improving a feedstock tile. Near-zero here with
  //     an idle Builder present and `gpUnimprovedFeedstockTileOwnedTurns`
  //     high => the improvement never completes (routing / preemption);
  //     high here with `gpFeedstockInStockpileTurns` near-zero => the
  //     improved tile is not extraction-connected (transport-cap stage).
  late final feedstockGateIdleBuilderPresentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockGateImprovedTileOwnedTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction missing-candidate disambiguation (read-only).
  // Both are gated on a feedstock-extraction-gate-active turn and split the
  // "idle Builder present + unimproved feedstock tile owned, yet improvement
  // never completes" gap into its proximate cause:
  //   * `feedstockGateValidBuildImprovementCandidateTurns` — the work-order
  //     engine (`getValidWorkOrderTileKeys`, the same validator chain
  //     `suggestWorkOrders` runs) actually accepts a `build_improvement`
  //     candidate for an idle Builder on an owned unimproved feedstock tile.
  //     Near-zero here confirms the candidate is suppressed by the validator
  //     before any selection boost (#3234) applies; high here re-points the
  //     break downstream to selection / orchestrator / phase filtering.
  //   * `feedstockGateImprovementCostAffordableTurns` — the GP's stockpile
  //     can afford the level-0 `build_improvement` cost (1 lumber + 1 cast
  //     iron). Near-zero alongside a near-zero candidate count localizes the
  //     suppression to the validator material-cost gate (the lumber /
  //     cast-iron deadlock); high alongside a near-zero candidate count
  //     points instead at tile control / visibility / occupancy gates.
  late final feedstockGateValidBuildImprovementCandidateTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockGateImprovementCostAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction affordability localization: the level-0
  // `build_improvement` cost is purely material (1 lumber + 1 cast iron,
  // `work_order_costs.dart`) — no treasury or recipe gate. When the
  // combined `gpFeedstockGateImprovementCostAffordableTurns` stays flat at
  // zero, these per-component counters split it into its proximate
  // shortfall: how many gate-active turns the GP holds the `lumber` share
  // vs the `castIron` share. Pins the binding missing material during the
  // gate window (not just at the turn-99 snapshot) so the next slice can
  // target lumber supply, castIron supply, or both. Read-only.
  late final improvementLumberId = CommodityCatalog.lumber.id;
  late final improvementCastIronId = CommodityCatalog.castIron.id;
  late final feedstockGateImprovementLumberAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockGateImprovementCastIronAffordableTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  // Refs #2847 H8-extraction acquisition-thread localization (read-only).
  // Post-#3274 the seller feedstock-tile acquisition thread (declare-war
  // target bias #3273 + conquest army-move target bias #3274) drives a
  // flagged below-quota zero-NW lock-recovery seller toward the Old World
  // feedstock province it must conquer when it owns no extractable feedstock
  // tile of its own. These split *why* a flagged seller that still owns 0
  // improved feedstock tiles (e.g. gp3) never completes the acquisition into
  // its proximate stage:
  //   * `feedstockAcquisitionTargetActiveTurns` —
  //     `expandSellerFeedstockTileAcquisitionTarget(game, snap)` returns a
  //     non-null conquest-reachable Old World feedstock province this turn,
  //     so the acquisition thread engages. Zero here localizes the residual
  //     upstream of the declare-war / army-move bias to "no conquest-
  //     reachable feedstock target" (the needed feedstock province is never
  //     invadable) — the bias has nothing to redirect.
  //   * `feedstockAcquisitionTargetWithFieldArmyTurns` — subset of the above
  //     where the GP also owns at least one non-home field army able to
  //     execute the march. Near-zero here with a positive active count
  //     localizes the residual to "target reachable but no field army to
  //     march it" (peer-war regiment attrition); a high count alongside a
  //     flat `gpFeedstockGateImprovedTileOwnedTurns` re-points the break to
  //     march/capture completion downstream of the army-move bias. Both stay
  //     0 by construction for the +6 baseline GPs gp1/gp2 (never flagged, so
  //     the acquisition target is always null).
  late final feedstockAcquisitionTargetActiveTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final feedstockAcquisitionTargetWithFieldArmyTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
}
