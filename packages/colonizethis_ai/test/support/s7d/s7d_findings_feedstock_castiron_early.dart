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
export 's7d_findings_feedstock_castiron_early_lumber_bootstrap.dart';
