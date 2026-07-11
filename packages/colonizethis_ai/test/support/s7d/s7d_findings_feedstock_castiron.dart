/// CastIron / fabric / labour S7-D findings (Refs #2847 / #3972).
///
/// Per-component affordability, castIron staging / labour starvation,
/// peasant-recruit fabric lock, and castIron-feedstock labour futility.
///
library;

// ignore_for_file: dangling_library_doc_comments

/// ## S7-D refresh (captured 2026-06-05 on merged `dev`, per-component
///     affordability split — this slice, Refs #2847)
///
/// The level-0 `build_improvement` cost is purely material
/// (`work_order_costs.dart` § `workOrderCostBuildImprovement(0)` = 1 `lumber` +
/// 1 `castIron`) — there is **no** treasury or recipe-cost gate, so the
/// combined `gpFeedstockGateImprovementCostAffordableTurns` (which requires
/// **both** materials at once) is split into two read-only per-component
/// counters measured on feedstock-extraction-gate-active turns:
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateImprovementCastIronAffordableTurns`. This localizes *which*
/// material binds during the gate window, not only at the turn-99 snapshot.
///
/// **Result (seed 42, turn 100; OW gate unchanged — gp1/gp2 = +6 PASS, gp3 =
/// +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL):**
///
/// | GP | gate-active | valid candidate | combined affordable | lumber affordable | castIron affordable |
/// |----|------------:|----------------:|--------------------:|------------------:|--------------------:|
/// | gp3 | 32 | 0 | 0 | **0** | **0** |
/// | gp5 | 13 | 2 | 0 | **2** | **0** |
/// | gp6 | 59 | 1 | 0 | **1** | **0** |
///
/// (gp1/gp2/gp4 hold the gate inactive — 0 gate-active turns — so all their
/// counters are 0 by construction; gp1/gp2 win OW without the feedstock chain.)
///
/// **Decisive localization:** `castIron` is the **universal binding material** —
/// `gpFeedstockGateImprovementCastIronAffordableTurns` is **0** for every
/// failing GP, so no GP ever holds the `castIron` share on any gate-active turn.
/// The combined counter tracks the `castIron` component exactly (0 / 0 / 0),
/// while the `lumber` component is occasionally satisfied (gp5 = 2, gp6 = 1,
/// matching their valid-candidate turns). gp3 is a distinct, more severe class:
/// it holds **neither** `lumber` nor `castIron` on **any** of its 32
/// gate-active turns (both = 0), consistent with its flat
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` = 0.
///
/// **Re-pointed next slice:** the binding shortfall is **`castIron` supply**,
/// not `lumber` and not a treasury/affordability *threshold* (treasury at
/// turn 99 now sits at gp3 = 2029, gp4 = 2170, gp5 = 2036, gp6 = 2036 — all
/// above `cheapestRegimentBuildTreasuryCost` = 2000, so treasury is no longer
/// the binding constraint). The next behavioural slice must make a locked
/// seller actually **produce or acquire its first `castIron`** (domestic
/// `castIron` from co-available `timber` + `iron`, per the prior co-availability
/// finding), and for gp3 additionally secure `lumber`. This split de-risks that
/// slice by confirming `lumber` is *not* the universal blocker. Per the scope
/// boundary, this remains the #2847 OW-conquest material-chain bootstrap (not
/// the colonial economy / Merchant gates scoped to #2852). Verify the next
/// slice by re-running this diagnostic and confirming
/// `gpFeedstockGateImprovementCastIronAffordableTurns` rises above 0 for
/// gp3 / gp5 / gp6 before expecting OW gain to move.
///
/// ## S7-D refresh (captured 2026-06-05 on current `dev` HEAD post-#3264 —
///     lumber re-localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (after the gp1 Old World
/// feedstock-prospect localization #3262 / #3263 / #3264) reproduces the prior
/// surface at the OW gate (gp1 / gp2 = +6 PASS; gp3 = +2, gp4 = +1, gp5 = +1,
/// gp6 = +2 FAIL) and at the feedstock affordability split
/// (`gpFeedstockGateImprovementCastIronAffordableTurns` = 0 for every GP;
/// `gpFeedstockGateImprovementLumberAffordableTurns` = gp5 2 / gp6 1 / gp3 0).
/// #3262 / #3263 / #3264 therefore did **not** move this surface.
///
/// **Correction to the prior "`castIron` is the universal binding material"
/// pointer (above):** the gate the next slice must actually move is the
/// production work-order **validator** candidate
/// (`gpFeedstockGateValidBuildImprovementCandidateTurns` = gp5 2 / gp6 1 /
/// gp3 0), measured through `getValidWorkOrderTileKeys` — which applies the
/// level-0 `castIron` **waiver**
/// (`feedstockBootstrapBuildImprovementCastIronWaived`: when the feedstock-
/// extraction gate is active and the GP holds the `lumber` share but not the
/// `castIron` share, the level-0 `build_improvement` may omit `castIron`).
/// The valid-candidate count tracks the **`lumber`** component exactly
/// (gp5 2 = 2, gp6 1 = 1, gp3 0 = 0) and is independent of the `castIron`
/// component (0 / 0 / 0): under the waiver `castIron` is **not** required to
/// extract the feedstock tile, so `castIron`-affordability = 0 does not gate
/// the `build_improvement` — **`lumber`** does.
///
/// **What `castIron` actually starves is one stage downstream.** Even where the
/// tile is extracted, the multi-input `castIron` recipe is never assigned by any
/// GP (`gpCastIronProductionAssignedTurns` = 0 for all six) because `iron` never
/// reaches any stockpile (`gpCastIronFeedstockHeldAtTurn99` iron = 0 for all
/// six; gp2 holds `timber` = 46 but `iron` = 0), even though the affluent
/// suppliers own a prospected, unimproved `iron` feedstock tile all 59
/// supplier-gate turns (`gpSupplierActiveUnimprovedCastIronFeedstockTileTurns`
/// gp1 / gp2 iron = 59; `gpSupplierProspectedMineralFeedstockTileTurns`
/// gp1 / gp2 = 59). The supplier's prospected `iron` tile is never *improved*
/// for the same reason: improving it also costs one `lumber` (+ waived
/// `castIron`), and only gp2 ever offers `lumber`
/// (`gpImprovementInputOffersEmitted` gp2 = 11; gp1 = 0), of which gp5 / gp6 win
/// a couple (`gpImprovementInputDealsAsBuyer` gp5 2 / gp6 1) and gp3 wins none
/// (0).
///
/// **Re-pointed next slice (supersedes the `castIron`-supply pointer above):**
/// the universal binding shortfall is **`lumber` supply for the level-0
/// `build_improvement`**, not `castIron`. Both the seller's own fabric-feedstock
/// extraction and the supplier's `iron` extraction are gated on holding one
/// `lumber` (with `castIron` waived), and the world market under-supplies it
/// (one offerer, gp1 silent). The next behavioural slice should make affluent
/// suppliers **over-produce and release `lumber`** for peer locked sellers
/// (mirroring the existing `castIron` supplier-release path, which today targets
/// only `kDomesticProductionImprovementInputIds = {castIron}`) and / or let a
/// locked seller domestically produce `lumber` from owned `timber`, so the
/// waived `build_improvement` becomes affordable on more than 0-2 turns. Verify
/// by re-running this diagnostic and confirming
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` rise for gp3 / gp5 / gp6
/// (and, one stage on, `gpCastIronProductionAssignedTurns` > 0 once `iron`
/// extracts) before expecting OW gain to move. The +6 baseline GPs (gp1 / gp2)
/// stay unaffected: a `lumber` supplier-release boost reuses the existing
/// leftover-labour-only sizing argument that keeps the conquest economy intact.
///
/// **Post-implementation refresh (supplier `lumber`-release slice landed).**
/// The supplier-release set was generalized from the hardcoded
/// `kDomesticProductionImprovementInputIds = {castIron}` to
/// `peerLockRecoverySellerNeededProducibleImprovementInputs(...)` (now exported
/// from `ai_api.dart`), so an affluent supplier over-produces whichever
/// producible improvement input a peer lock-recovery seller actually binds on —
/// `lumber` here, not the waived `castIron`. The economy- and treasury-planner
/// triggers were generalized to match, with positive + negative-control unit
/// coverage in `economy_planner_regiment_build_input_production_test.dart`.
/// Re-running this diagnostic on the change produces a **byte-identical** seed-42
/// surface: `gpImprovementInputOffersEmitted` unchanged (gp1 = 0, gp2 = 11),
/// `gpFeedstockGateImprovementLumberAffordableTurns` /
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` unchanged
/// (gp5 = 2, gp6 = 1, gp3 = 0), `gpImprovementInputDealsAsBuyer` unchanged
/// (gp5 = 2, gp6 = 1, gp3 = 0), and OW gain unchanged. The release boost is
/// therefore **correct groundwork but verified necessary-but-insufficient** on
/// this seed: it re-prioritizes leftover supplier labour toward the binding
/// material, but it cannot release `lumber` the suppliers do not produce/hold —
/// gp1 stays silent (0 offers) and gp2's 11 offers are its pre-existing output,
/// neither of which the prioritization-only boost increases.
///
/// **Re-pointed lever (supersedes the supplier-release pointer above).** The
/// binding shortfall is `lumber` **production/supply capacity**, not its release
/// prioritization. The next slice should make the locked seller domestically
/// produce `lumber` from its own `timber` (option b above) — gp3 holds
/// `timber` = 7 (`gpCastIronFeedstockHeldAtTurn99`), so a seller-side
/// `lumber_from_timber` assignment removes the dependence on a thin one-offerer
/// market — and/or raise the supplier's `timber`->`lumber` throughput so the
/// release set has surplus to ship. Verify the same way: confirm
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` rise for gp3 / gp5 / gp6
/// before expecting OW gain to move.
///
/// **Post-implementation refresh (seller domestic `lumber`-production slice
/// landed; captured 2026-06-05 on current `dev` HEAD post-#3267, Refs #2847).**
/// Option (b) above is now implemented: the locked seller's domestic-production
/// set was generalized from the market-absent `castIron`-only filter to
/// `selfLockRecoverySellerNeededProducibleImprovementInputs(...)`, so a seller
/// short the **binding** level-0 `lumber` input now boosts `lumber_from_timber`
/// from its own `timber` instead of depending on the thin one-offerer market,
/// and the single-input `lumber` output is excluded from the seller's feedstock
/// reserve so it draws only *surplus* `timber` (preserving the multi-input
/// `castIron` co-availability guarantee). Positive + negative-control unit
/// coverage in `economy_planner_regiment_build_input_production_test.dart` and a
/// logic contract test in
/// `full_ai_civilian_work_regiment_build_input_feedstock_extraction_test.dart`;
/// SPEC updated in `SPEC/ai/economy-planner.md` § Domestic improvement-input
/// production.
///
/// This slice is **correct groundwork but verified byte-identical
/// (necessary-but-insufficient)** on seed 42: OW gain unchanged (gp1/gp2 **+6**
/// PASS; gp3 +2, gp4 +1, gp5 +1, gp6 +2 FAIL),
/// `gpFeedstockGateImprovementLumberAffordableTurns` unchanged (gp5 2 / gp6 1 /
/// gp3 0), `gpLumberHeldAtTurn99` still 0 for every failing GP. The decisive
/// reason: **the failing sellers hold no `timber`** to convert —
/// `gpCastIronFeedstockHeldAtTurn99` shows `timber = 0` (and `iron = 0`) for
/// gp3 / gp4 / gp5 / gp6 at turn 99 (only the suppliers gp2 holds `timber 44`).
/// `lumber_from_timber` therefore stays infeasible for the very GPs that bind on
/// `lumber`, so the now-enabled domestic path has no feedstock to run — the
/// mirror of #3267's supplier-release slice, which could not release `lumber`
/// the suppliers do not hold.
///
/// **Re-pointed lever — now landed.** The binding precondition was **seller
/// `timber` holdings**: the locked seller owns unimproved `timber` tiles but
/// holds zero `timber`, so neither `lumber_from_timber` nor
/// `castIron_from_iron` had feedstock. That lever is now
/// implemented: `sellerImprovementInputFeedstockExtractionResourceIds`
/// (`full_ai_civilian_work_selection.dart`) extends the H8 feedstock-extraction
/// gate (via `feedstockExtractionResourceIdsForPlayer`) to the seller's own
/// `lumber` / `castIron` improvement-input feedstock (`timber` / `iron`), not
/// only the `fabric`-recipe feedstock `wool` / `cotton`, so the locked seller's
/// idle Builder is routed onto its own unimproved `timber` tile (improving a
/// `timber` surface tile is itself level-0 `build_improvement`, covered by the
/// same `castIron`-waiver once one `lumber` is on hand), and the Old World
/// feedstock unit reservation holds that Builder in the Old World.
/// `gpFeedstockGateIdleBuilderPresentTurns` (gp3 32 / gp5 13 / gp6 59) confirms
/// an idle Builder is available to route. Verify by confirming
/// `gpCastIronFeedstockHeldAtTurn99` `timber` rises above 0 for gp3 / gp5 / gp6,
/// then `gpFeedstockGateImprovementLumberAffordableTurns` rises, before
/// expecting OW gain to move. The residual lever for a seller that owns **no**
/// `timber` tile at all is feedstock-tile acquisition (further #2847 work).
///
/// ## S7-D refresh (captured 2026-06-05 on merged `dev` post-#3274 —
///     acquisition-thread localization, this slice, Refs #2847)
///
/// Post-#3274 (conquest army-move target bias for flagged seller feedstock
/// province), the OW gate is unchanged (gp1/gp2 **+6** PASS; gp3 +2, gp4 +1,
/// gp5 +1, gp6 +2 FAIL). Two new read-only counters localize whether the
/// seller feedstock-tile **acquisition** thread (declare-war bias #3273 +
/// army-move bias #3274) engages on seed 42:
///
///   * `gpFeedstockAcquisitionTargetActiveTurns` — turns where
///     `expandSellerFeedstockTileAcquisitionTarget(game, snap)` returns a
///     non-null conquest-reachable Old World feedstock province.
///   * `gpFeedstockAcquisitionTargetWithFieldArmyTurns` — subset where the GP
///     also owns a non-home field army to execute the march.
///
/// **Result: both counters are 0 for every GP (gp1–gp6) on all 100 turns.**
///
/// **Decisive localization:** the acquisition residual
/// (`sellerNeedsImprovementInputFeedstockTileAcquisition`) is **inactive** for
/// every failing GP on seed 42 because each already **owns** an unimproved
/// feedstock tile (`gpUnimprovedFeedstockTileOwnedTurns` = 100 for all six GPs).
/// The acquisition path fires only when the seller owns **no** feedstock tile at
/// all; the failing GPs instead need to **improve** tiles they already hold
/// (blocked on `lumber` supply per the prior refresh). The #3271–#3274 conquest-
/// acquisition thread (detection → target pick → declare-war bias → army-move
/// bias) is therefore **structurally present and unit-tested** but **inert on
/// this seed** — it does not apply to the current failing-GP profile. gp3's
/// `gpFeedstockGateImprovedTileOwnedTurns` = 0 despite 32 gate-active turns
/// with an idle Builder confirms the break remains on the **extraction /
/// lumber-supply** path (improve the owned tile), not on conquest acquisition.
///
/// **Re-pointed next slice (supersedes the acquisition-thread pointer above):**
/// continue the **lumber-supply / owned-tile extraction** lever for gp3 / gp5 /
/// gp6 (`gpFeedstockGateImprovementLumberAffordableTurns` gp5 = 2 / gp6 = 12 /
/// gp3 = 0; `gpFeedstockGateImprovedTileOwnedTurns` gp5 = 49 / gp6 = 20 / gp3 =
/// 0), **not** further conquest-acquisition bias slices (the acquisition
/// residual never activates on this seed). The acquisition-thread counters
/// remain in the diagnostic for seeds / GP profiles where a locked seller owns
/// **no** feedstock tile. Verify the next extraction slice by confirming
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateImprovedTileOwnedTurns` rise for gp3 before expecting OW
/// gain to move.
///
/// ## S7-D refresh (captured 2026-06-05 — lumber bootstrap waiver slice,
///     Refs #2847)
///
/// The level-0 `build_improvement` **lumber waiver** (scoped to improvement-
/// input feedstock tiles `timber` / `iron` only — not regiment-build-input
/// `wool` / `cotton`) waives both `lumber` and `castIron` when the seller
/// holds neither, breaking the chicken-and-egg where improving the owned
/// `timber` tile requires `lumber` the seller does not yet hold. Re-running
/// this diagnostic on the change:
///
/// | GP | OW gain | lumber affordable | valid candidate | improved tile owned |
/// |----|---------|------------------:|----------------:|--------------------:|
/// | gp1 | +6 ✅ | 0 | 0 | 0 |
/// | gp2 | +6 ✅ | 0 | 0 | 0 |
/// | gp3 | +2 ❌ | **14** (was 0) | **14** (was 0) | **23** (was 0) |
/// | gp4 | +1 ❌ | 0 | 0 | 0 |
/// | gp5 | +1 ❌ | **15** (was 2) | **15** (was 2) | 35 (was 49) |
/// | gp6 | +2 ❌ | **14** (was 12) | **14** (was 1) | **38** (was 20) |
///
/// **Decisive localization:** the lumber bootstrap **unblocks the owned-tile
/// extraction path** for gp3 / gp5 / gp6 (`gpFeedstockGateImprovementLumberAffordableTurns` and `gpFeedstockGateImprovedTileOwnedTurns` rise materially; gp3 moves off the all-zero floor). OW gain is **unchanged** at the turn-100 gate (gp3 +2, gp4 +1, gp5 +1, gp6 +2) — the slice is **correct groundwork but verified necessary-but-insufficient** on seed 42, mirroring prior H8 slices. The +6 baseline (gp1 / gp2) is preserved. A broader unscoped waiver that also zero-cost-improved `wool` / `cotton` fabric feedstock **regressed gp5 OW gain to −7**; scoping to improvement-input feedstock only restored gp5 to +1.
///
/// **Re-pointed next slice:** downstream of the now-improving feedstock tiles —
/// confirm `gpCastIronFeedstockHeldAtTurn99` `timber` / `iron` rise, domestic
/// `lumber` / `castIron` production assigns, and the fabric → regiment → OW
/// conquest chain completes before expecting OW gain to reach +3.
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
/// `seed42_s7d_feedstock_helpers_test.dart`).
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
/// `playerFoodOnHand` in `seed42_s7d_feedstock_helpers_test.dart`).
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
