/// CastIron / fabric / labour S7-D findings — late sections (Refs #2847 / #4239 Slice C).
///
library;

// ignore_for_file: dangling_library_doc_comments

/// ## S7-D refresh (captured 2026-06-06 on current `dev` HEAD — castIron
///     production-assignment localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (post the seller
/// feedstock-tile acquisition thread #3271–#3276 and the lumber bootstrap
/// waiver) confirms the prior re-pointed step is now reached: the owned-tile
/// extraction path **works** for gp5 / gp6 — `gpFeedstockInStockpileTurns` =
/// gp5 49 / gp6 44 (was 1) and `gpCastIronFeedstockHeldAtTurn99` shows **gp5
/// co-holds `timber` = 71 and `iron` = 64** at turn 99 (gp6 `timber` = 214 /
/// `iron` = 0; gp3 / gp4 still 0 / 0). OW gain is unchanged (gp1 / gp2 = +6
/// PASS; gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL).
///
/// ## S7-D refresh (captured 2026-06-06 on current `dev` HEAD — castIron
///     production-assignment localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (post the seller
/// feedstock-tile acquisition thread #3271–#3276 and the lumber bootstrap
/// waiver) confirms the prior re-pointed step is now reached: the owned-tile
/// extraction path **works** for gp5 / gp6 — `gpFeedstockInStockpileTurns` =
/// gp5 49 / gp6 44 (was 1) and `gpCastIronFeedstockHeldAtTurn99` shows **gp5
/// co-holds `timber` = 71 and `iron` = 64** at turn 99 (gp6 `timber` = 214 /
/// `iron` = 0; gp3 / gp4 still 0 / 0). OW gain is unchanged (gp1 / gp2 = +6
/// PASS; gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL).
///
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
/// ## Refs #2847 — #3303 peasant-recruit effectiveness (circular fabric lock)
///
/// #3303 acted on the population-bound finding above: it wired an EXPAND
/// orchestrator pass that emits one peasant `RecruitWorkerOrder` whenever
/// `isCastIronLabourPopulationBoundForLockRecoverySeller` holds, so the seller
/// can grow raw labour toward one `castIron` run. The S7-D refresh **after
/// #3303 landed** shows it did not move the conquest gate (OW gain unchanged:
/// gp1/gp2 +6, gp3 +2, gp4 +1, gp5 +1, gp6 +2) and that
/// `gpCastIronRecipeLabourFeasibleTurns` / `gpCastIronProductionAssignedTurns`
/// are **still 0 for every GP**. Three read-only counters localize why by
/// splitting the boost's gate-active turns on peasant-recruit affordability
/// (`canAffordRecruitWorker` against `WorkerActionEconomyCatalog.peasant`,
/// whose cost row is **2 `fabric`**):
///
///   * `gpCastIronLabourPeasantRecruitGateTurns` = **gp5 = 37**, every other
///     GP = 0. Only gp5 ever satisfies the #3303 gate: gp3/gp4/gp6 are never
///     even castIron material-feasible (`gpCastIronRecipeFeasibleTurns == 0`),
///     and gp1 holds regiments (the gate is scoped to `regimentCount == 0`).
///   * `gpCastIronLabourPeasantRecruitAffordableTurns` = **0 for every GP**.
///   * `gpCastIronLabourPeasantRecruitFabricStarvedTurns` = **gp5 = 37**
///     (== its gate-active total).
///
/// **#3303 is a structural no-op.** On every turn its gate fires (gp5, 37
/// turns) the seller cannot pay the peasant recruit's 2-`fabric` cost, so the
/// orchestrator probes a recruit the validator must reject — raw labour never
/// grows, the castIron run never becomes labour-feasible. This is a **circular
/// dependency**: the peasant that would grow castIron labour is itself bought
/// with `fabric`, the very downstream commodity the castIron → improvement →
/// feedstock-extraction chain exists to unblock. A fabric-starved
/// lock-recovery seller can never bootstrap out of the lock through peasant
/// recruitment.
///
/// **Re-pointed next slice (supersedes the peasant-recruit hypothesis):** the
/// labour-growth lever must not consume the scarce end-of-chain commodity.
/// gp5 already shows `gpFabricRecipeFeasibleTurns == 48` (it can run the fabric
/// recipe from owned cotton/wool feedstock), so a viable direction is to route
/// a domestic `fabric` production assignment for the lock-recovery seller
/// *before* the peasant recruit so the 2-`fabric` cost is payable from own
/// output rather than from the (absent) market — or to grow labour through a
/// fabric-free path. Verify by confirming
/// `gpCastIronLabourPeasantRecruitAffordableTurns` rises above 0, then
/// `gpCastIronRecipeLabourFeasibleTurns` and `gpCastIronProductionAssigned
/// Turns` rise above 0 for gp5, while the gp1/gp2 +6 baseline holds. This
/// slice is read-only diagnostic instrumentation (no behaviour change, no
/// config constants, no gate-threshold changes; the three counters partition
/// the gate-active turns under a structural-invariant assertion).
///
/// **Market-fabric localization (post-#3317 re-point):** the #3317 refresh
/// re-pointed the next slice toward a *non-`fabric`* labour-growth path, but
/// the `WorkerActionEconomyCatalog` shows no such row exists — the peasant
/// recruit is the only raw-population-growth action and it is `fabric`-gated
/// (apprentice/journeyman/master merely *convert* an existing peasant). The
/// only remaining lever to pay the 2-`fabric` recruit cost without producing
/// it is to *buy* it, so `gpCastIronLabourPeasantRecruitMarketFabricStarvedTurns`
/// refines the fabric-starved turns to those where **no other great power
/// holds any `fabric` either** (`otherGreatPowerFabricHeld <= 0`). The seed-42
/// run shows gp5 = **0 of 8** fabric-starved turns are market-starved: other
/// great powers DO hold `fabric` on every one of gp5's fabric-starved turns,
/// so the market door is **not** closed at the holdings level — the held
/// `fabric` simply is not reaching the seller (labour-bound holders keep it
/// for their own use rather than offering it). This rules out the "create
/// `fabric` supply / rules-level bootstrap" framing and re-points the next
/// slice onto the **offer / acquisition** path: held-but-unoffered `fabric`
/// vs offered-but-unbid/unmatched. Read-only instrumentation (no behaviour
/// change, no config constants, no gate-threshold changes; the new counter is
/// a strict refinement of the fabric-starved turns under a structural-invariant
/// assertion).
///
/// ## S7-D refresh (captured 2026-06-07 on current `dev` HEAD — castIron-feedstock
///     order-matching gap surfaced but localized OFF the critical path; this
///     slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD surfaces a **new** market
/// state the prior refreshes did not have, and resolves where it sits on the
/// chain. OW gain: gp1 = +6, gp2 = +6 (PASS); gp3 = +1, gp4 = +2, gp5 = −7,
/// gp6 = +10 (FAIL) — gp5/gp6 are the peer-war-variance pair (gp5 cornered this
/// run); gp3/gp4 are the stable below-quota failures. The +6 baseline holds.
///
///   * **Suppliers now OFFER the castIron feedstock.**
///     `gpCastIronFeedstockOffersEmitted` = **gp1 89 / gp2 24 / gp5 46 / gp6 33**
///     (`timber` / `iron`) — the supplier feedstock-extraction routing landed,
///     so the historical "no holder has a `timber` / `iron` surplus to release"
///     finding is now **stale**. gp1 ends the run holding `timber` 133 / `iron`
///     118; gp5 `timber` 27 / `iron` 35.
///   * **Yet the locked seller's feedstock bids fill nothing.**
///     `gpCastIronFeedstockBidsEmitted` = gp3 14 / gp6 2, but
///     `gpCastIronFeedstockDealsAsBuyer` = **0 for every GP**. With offers now
///     present, the residual is a `timber` / `iron` offer/bid **priority-tier
///     mismatch** (the same class `_alignBuildInputSupplyOfferTiers` already
///     fixes for the `lumber` / `castIron` improvement inputs, which DO cross —
///     gp3's improvement-input bids fill 15/15).
///   * **But that order-matching gap is OFF the critical path.** New counter
///     `gpCastIronFeedstockExtractionLabourFutileTurns` records the
///     feedstock-extraction-gate-active turns whose fully-fed raw labour ceiling
///     is below the castIron `labourPerOutput` (5). For gp3 this equals the full
///     gate-active total (raw labour ceiling 2): on **every** such turn, even a
///     fully-filled `timber` / `iron` bid could not yield a labour-feasible
///     castIron run. So aligning the feedstock offer tier (or any further
///     supplier-release work) would only let gp3 **hoard unusable feedstock** —
///     it cannot move the OW gate while the seller stays population-bound.
///
/// **Re-pointed next slice (supersedes the castIron market-supply / offer-tier
/// candidates):** the feedstock supply and order-matching levers are now
/// confirmed dead ends for the stable failures — `timber` / `iron` are offered,
/// and even filling the bids leaves the castIron recipe labour-infeasible. The
/// binding constraint remains the lock-recovery seller's **worker population**
/// (raw labour ceiling 1-2 vs castIron's 5 / fabric's 2), consistent with the
/// population-bound conclusion above; the only raw-population-growth action
/// (peasant recruit) is `fabric`-gated and the seller's `fabric` is itself
/// labour-walled (the circular deadlock). The next *behaviour* lever must grow
/// the seller's labour pool without consuming the scarce end-of-chain `fabric`,
/// under the same self-clearing lock-recovery-seller gate that keeps the +6
/// baseline GPs out. This slice is read-only diagnostic instrumentation (no
/// behaviour change, no config constants, no gate-threshold changes; a positive
/// + negative + boundary unit test for the helper
/// `castIronFeedstockExtractionLabourFutile` and a structural-invariant
/// assertion bounding the counter by the gate-active total).
///
