library;

/// **Decisive new localization:** `gpCastIronProductionAssignedTurns` is **0
/// for every GP including gp5**, yet the only `castIron` recipe
/// (`castIron_from_iron`) consumes only `timber` × 2 + `iron` × 2
/// (no coal in `inputQuantities`) — so gp5's turn-99 holdings (71 / 64) make it
/// **materially feasible**. This slice adds the missing per-turn signal,
/// `gpCastIronRecipeFeasibleTurns` (built on the read-only pure helper
/// `stockpileAffordsAnyProductionRecipe`, mirroring the existing inline
/// `fabricRecipes` feasibility check), to confirm the feasibility holds across
/// the run, not only at the terminal snapshot. A non-zero
/// `gpCastIronRecipeFeasibleTurns` alongside `gpCastIronProductionAssignedTurns`
/// = 0 splits the residual decisively: the `castIron` chain is no longer
/// blocked on **feedstock supply** (the extraction lever landed) but on
/// **production allocation** — the economy planner never assigns the feasible
/// `castIron` recipe for the lock-recovery seller.
///
/// **Re-pointed next slice (supersedes the "confirm downstream production
/// assigns" pointer above):** target **`castIron` production-recipe
/// assignment** for a below-quota zero-NW lock-recovery seller that already
/// holds (or can co-extract) `timber` + `iron` — i.e. make the economy
/// planner stage the domestic `castIron` run on feasible turns (mirroring the
/// treasury-independent `fabricFrom*` and `lumber_from_timber` staging already
/// landed for the same gate), **not** further feedstock-extraction or
/// supplier-release work (gp5 already co-holds both feedstocks). Verify by
/// re-running this diagnostic and confirming `gpCastIronProductionAssignedTurns`
/// rises above 0 for gp5 / gp6 (and, one stage on,
/// `gpRebuildReadyNoBuildMissingInputTurns` falls) before expecting OW gain to
/// move. The +6 baseline (gp1 / gp2) stays unaffected: they assign / hold
/// `castIron` independently and never enter the lock-recovery seller gate.
///
/// ## S7-D refresh (captured 2026-06-06 — castIron staging path landed,
///     Refs #2847, PR #3289)
///
/// The economy planner now adds
/// `selfLockRecoverySellerStageableImprovementInputs(game, playerId)` to the
/// domestic production boost: the producible **multi-input** level-0
/// improvement input (`castIron`) a below-quota zero-NW lock-recovery seller
/// (zero regiments) is short of **and still owns a `timber` / `iron` feedstock
/// tile for**, so the seller can stage the run even after its fabric-feedstock
/// improvement-cost gate goes inactive. Unit coverage:
/// `self_lock_recovery_seller_stageable_improvement_inputs_test.dart` (logic)
/// and `economy_planner_regiment_build_input_production_test.dart` (AI);
/// SPEC updated in `SPEC/ai/economy-planner.md` § Domestic castIron staging
/// after the fabric gate goes inactive.
///
/// Re-running this diagnostic on the change is **necessary-but-insufficient**
/// on seed 42: the +6 baseline is preserved (gp1 / gp2 **+6** PASS; gp3 +2,
/// gp4 +1, gp5 +1, gp6 +2 FAIL — OW gain identical to the pre-change capture),
/// `gpCastIronRecipeFeasibleTurns` unchanged (gp5 = 53, gp1 = 48), and
/// `gpCastIronProductionAssignedTurns` **stays 0 for every GP**. The staging
/// path is correct groundwork but does not yet fire for gp5 on this seed: the
/// binding constraint sits one stage deeper than "castIron absent from the
/// boosted set" — either gp5's `timber` / `iron` is held without owning a
/// resource tile on the feasible turns (so the tile-ownership gate stays shut),
/// or the materially-feasible turns (`stockpileAffordsAnyProductionRecipe`,
/// material-only) are not **labour**-feasible (`feasibleRuns` is labour-capped)
/// once mandatory food production consumes the seller's small effective labour.
///
/// **Re-pointed next slice:** localize which of the two holds for gp5 — add a
/// read-only counter splitting `castIronRecipeFeasibleTurns` (material) into
/// labour-feasible vs labour-starved, and a counter for whether the seller owns
/// a `timber` / `iron` resource tile on the feasible turns. If tile-ownership
/// is the blocker, broaden the staging gate to fire on held feedstock (and move
/// the gate-inactive co-availability negative controls accordingly); if labour
/// is the blocker, the lever moves to effective-labour / food-reservation, not
/// the production boost. Verify by confirming `gpCastIronProductionAssignedTurns`
/// rises above 0 for gp5 before expecting OW gain to move; the +6 baseline
/// (gp1 / gp2) stays unaffected by construction (regiment-holding gate).
///
/// ## S7-D refresh (captured 2026-06-06 — castIron production-allocation fork
///     resolved, Refs #2847, PR #3289 follow-up)
///
/// This slice lands the two read-only counters the prior refresh re-pointed and
/// re-runs the diagnostic. The fork **resolves decisively to labour**, not tile
/// ownership:
///
///   * `gpCastIronRecipeFeasibleTurns` (material-only): gp1 = 48, gp5 = 53,
///     0 for every other GP — unchanged.
///   * `gpCastIronFeasibleOwnsFeedstockTileTurns`: gp1 = 48, gp5 = 53 — **equal
///     to the material-feasible count**, so on **every** castIron
///     material-feasible turn the seller still owns a `timber` / `iron` resource
///     tile. The staging gate's `_ownsFeedstockResourceTile` precondition is
///     therefore **satisfied**; tile ownership is **not** the blocker, and
///     broadening the staging gate to fire on held feedstock would not help.
///   * `gpCastIronRecipeLabourFeasibleTurns`: **0 for every GP**, including
///     gp5's 53 material-feasible turns. The castIron recipe
///     (`labourPerOutput == 5`) is **never** labour-feasible against the
///     seller's full `effectiveLabourForWorkers` — its effective labour, after
///     mandatory food upkeep, never funds even one run. This is exactly the
///     "labour-capped `feasibleRuns`" branch the prior refresh hypothesised.
///   * `gpCastIronProductionAssignedTurns` stays 0 for every GP, now explained:
///     the recipe is materially feasible and tile-backed but labour-starved, so
///     the planner's own `feasibleRuns` gate never clears.
///   * The +6 baseline is preserved (gp1 / gp2 **+6** PASS); the failing-GP gate
///     is unchanged in kind by this read-only slice.
///
/// **Re-pointed next slice (supersedes the tile-ownership fork):** the binding
/// constraint for the lock-recovery seller's first domestic `castIron` run is
/// **effective labour**, not feedstock supply, tile ownership, or the staging
/// boost. The next *behaviour* slice must give a below-quota zero-NW
/// zero-regiment lock-recovery seller enough spare labour to fund one
/// `castIron` run on a materially-feasible turn — e.g. reserving / freeing
/// effective labour from lower-priority recipes (or a food-reservation that
/// leaves a `labourPerOutput`-sized slice) under the same self-clearing
/// lock-recovery-seller gate that keeps the +6 baseline GPs (gp1 / gp2,
/// regiment-holding) out by construction. Verify by confirming
/// `gpCastIronRecipeLabourFeasibleTurns` then `gpCastIronProductionAssignedTurns`
/// rise above 0 for gp5 before expecting OW gain to move. Broadening the staging
/// gate or adding feedstock supply is explicitly **not** the lever (both are
/// already satisfied on the feasible turns). This slice is read-only diagnostic
/// instrumentation (no behaviour change, no config constants, no gate-threshold
/// changes; positive + negative unit tests for the two helpers in
/// `support_test/seed42_s7d_feedstock_helpers_test.dart`).
///
/// ## S7-D refresh (captured 2026-06-06 — castIron labour-starvation sub-cause
///     fork resolved: population-bound, not food-starved; Refs #2847)
///
/// The prior refresh re-pointed the behaviour lever to "effective labour" but
/// left the *sub-cause* open: is the labour shortfall a **food** problem
/// (workers exist but too few are fed) or a **population** problem (too few
/// workers even if all fed)? Its hypothesised lever — "reserve / free effective
/// labour from lower-priority recipes, or a food-reservation" — assumed the
/// former. This slice adds two read-only counters
/// (`gpCastIronLabourFoodStarvedTurns` vs `gpCastIronLabourPopulationBoundTurns`,
/// a partition of the material-feasible-but-labour-infeasible turns, forked on
/// whether the food-ungated ceiling `playerRawLabourSupply` would itself fund one
/// `castIron` run of `castIronMinLabourPerOutput == 5`) plus a turn-99
/// effective-labour / raw-supply / food-on-hand snapshot. The fork resolves
/// **decisively to population**, and **falsifies the food hypothesis**:
///
///   * `gpCastIronLabourFoodStarvedTurns` = **0 for every GP** — on no
///     material-feasible turn would feeding more workers reach one run.
///   * `gpCastIronLabourPopulationBoundTurns` = gp1 = 48, gp5 = 53 (**equal to
///     the full material-feasible count**) — on *every* such turn the seller's
///     fully-fed labour ceiling is itself below `labourPerOutput == 5`.
///   * Turn-99 snapshot: every GP has `effectiveLabour == rawLabourSupply`
///     (so **all** workers are already fed — food is not gating labour) while
///     that ceiling is tiny: gp5 = **1**, gp1 / gp2 / gp3 / gp4 = **2**, far
///     below 5. Food on hand is simultaneously **abundant** (gp5 = 289,
///     gp3 = 203, gp6 = 193), confirming the seller is drowning in food yet
///     starved of *workers*, not food.
///
/// **Re-pointed next slice (supersedes the food-reservation hypothesis):** the
/// binding constraint is the lock-recovery seller's **worker population**, not
/// food supply, feedstock, tile ownership, or recipe competition. A below-quota
/// zero-NW zero-regiment seller holds only ~1-2 total labour against the
/// `castIron` recipe's 5, with surplus food and idle feedstock — so neither
/// freeing labour from other recipes (there is almost none to free) nor a
/// food-reservation (food is not the gate) can ever clear `feasibleRuns > 0`.
/// The next *behaviour* slice must grow the seller's labour pool — e.g. convert
/// the abundant food into worker growth / peasant recruitment for the same
/// self-clearing lock-recovery-seller cohort — until the fully-fed ceiling
/// reaches `castIronMinLabourPerOutput`, gated to exclude the regiment-holding
/// +6 baseline GPs (gp1 / gp2) by construction. Verify by confirming
/// `gpCastIronLabourPopulationBoundTurns` falls as `rawLabourSupply` rises past
/// 5, then `gpCastIronRecipeLabourFeasibleTurns` and
/// `gpCastIronProductionAssignedTurns` rise above 0 for gp5. This slice is
/// read-only diagnostic instrumentation (no behaviour change, no config
/// constants, no gate-threshold changes; positive + negative unit tests for the
/// three helpers `playerEffectiveLabour` / `playerRawLabourSupply` /
/// `playerFoodOnHand` in `support_test/seed42_s7d_feedstock_helpers_test.dart`).
///
export 's7d_findings_feedstock_castiron_late_refresh_peasant_recruit.dart';
