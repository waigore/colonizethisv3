// Explorer / mineral-prospect localization counters for S7-D rollup
// (Refs #2847 / #4079 Slice D). Mixed into [Seed42S7dCampaignRollup].
library;

/// Explorer co-location and prospect-candidate diagnostic counters.
mixin Seed42S7dCampaignRollupExplorerCounters {
  List<String> get gpIds;


  // Refs #2847 H8-extraction Old World mineral feedstock prospect
  // localization (post-#3257 reservation). The reservation holds back an
  // idle Builder/Explorer for Old World feedstock work, yet
  // `gpCastIronFeedstockHeldAtTurn99` still shows `iron == 0` for every
  // supplier (`iron` is never extracted) while surface `timber` is. A
  // mineral `build_improvement` is rejected until the tile is prospected
  // (`work_order_target_prechecks.dart`), and only an **idle** Explorer is
  // reservable, so these two counters split the residual `iron` break,
  // captured while the supplier castIron gate is active:
  //
  //   * `supplierIdleExplorerPresentTurns` — the supplier owns an idle
  //     Explorer this turn (a unit the reservation could route onto the
  //     `iron` prospect). A near-zero count localizes the break to
  //     **Explorer availability** (all Explorers busy / dispatched to
  //     multi-turn New World exploration, so the reservation never has an
  //     idle Explorer to hold).
  //   * `supplierProspectedMineralFeedstockTileTurns` — the supplier owns a
  //     **prospected** Old World `iron` mineral feedstock tile. A non-zero
  //     count alongside `iron` held == 0 instead localizes the break
  //     **downstream** of prospecting (the Builder never improves the
  //     prospected tile / cannot afford the improvement); a flat zero
  //     confirms the prospect itself never happens.
  //   * `supplierIdleExplorerColocatedFeedstockTileTurns` — the supplier
  //     owns an idle Explorer standing **in the same province** as an
  //     unprospected Old World `iron` mineral feedstock tile. `prospect`
  //     candidate generation only reaches an Explorer positioned on (or
  //     single-hop from) the feedstock province, and the reservation holds
  //     the lexicographically-smallest idle Explorer **without
  //     repositioning it**. A flat zero alongside
  //     `supplierIdleExplorerPresentTurns > 0` localizes the residual to
  //     reservation **positioning** (no idle Explorer ever reaches the
  //     feedstock province, so no `prospect` candidate generates); a
  //     non-zero count instead points at candidate-generation eligibility
  //     (mineral-tile gate / validator) or selection ranking for an
  //     already-positioned Explorer.
  //   * `supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns` —
  //     the supplier owns an idle Explorer co-located with an unprospected
  //     Old World `iron` mineral feedstock tile that **also** passes the
  //     live mineral-eligibility terrain check (`isMineralEligibleTile`
  //     under the seed-42 `tileMapByRegion`). This is the next gate the
  //     `prospect` candidate must clear in
  //     `_allAcceptedProspectTilesInProvince`. Comparing it against
  //     `supplierIdleExplorerColocatedFeedstockTileTurns` splits the
  //     residual finer: a flat zero here while the resource-only co-located
  //     count is non-zero localizes the break to **terrain
  //     mineral-eligibility** at candidate generation (the owned `iron`
  //     tile sits on non-prospectable terrain); equal non-zero counts
  //     instead point **downstream** of eligibility (validator material
  //     cost / visibility precheck or selection ranking).
  //   * `supplierIdleExplorerColocatedSuggestedProspectTileTurns` — the
  //     **real** `suggestWorkOrders` pass actually emits a `prospect`
  //     candidate for the co-located mineral-eligible feedstock tile. This
  //     is the next gate past terrain eligibility: it runs the live
  //     generation pass (province visibility, move-leg validation, and the
  //     incremental-validator material-cost / visibility precheck all live
  //     inside it) rather than re-deriving one gate. Comparing it against
  //     `supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns`
  //     resolves the final fork: a non-zero count proves the prospect is
  //     generated + validator-accepted, so the residual is **selection
  //     ranking** (the accepted `prospect` loses to a competing `explore`
  //     in `selectFullAiCivilianWorkOrders`); a flat zero while the
  //     mineral-eligible count is non-zero localizes the residual **inside
  //     generation** (the visibility / move-leg / validator gates), not
  //     ranking.
  //
  // Read-only; the (freely tunable) counts can move as later slices land.
  late final supplierIdleExplorerPresentTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final supplierProspectedMineralFeedstockTileTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final supplierIdleExplorerColocatedFeedstockTileTurns = <String, int>{
    for (final gpId in gpIds) gpId: 0,
  };
  late final supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};
  late final supplierIdleExplorerColocatedSuggestedProspectTileTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};
  late final supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};
  late final supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};
  late final supplierIdleExplorerColocatedFeedstockProspectValidatorTurns =
      <String, int>{for (final gpId in gpIds) gpId: 0};

}
