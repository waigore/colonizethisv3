/// CastIron / fabric / labour S7-D findings — early sections (Refs #2847 / #4239 Slice C).
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
