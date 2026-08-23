/// Feedstock-stage / H8 extraction S7-D findings (Refs #2847 / #3972).
///
/// Early H8 feedstock-stage disambiguation and treasury-independent
/// routing / retention diagnostics (pre per-component affordability split).
///
library;

// ignore_for_file: dangling_library_doc_comments

/// ## S7-D refresh (captured 2026-06-04 on merged `dev` @ `0ef7919e`, after
///     the H8-supply wool market path (#3233), the H8-extraction feedstock
///     tile priority (#3234), and the civilian-work force-on gate (#3235)
///     all merged — feedstock-stage instrumentation added in this slice)
///
/// The H8-supply market + extraction slices did **not** move the binding
/// metric: `gpCheapestRegimentInputsInStockpileTurns` (fabric on hand) is
/// still **2 / 2 / 2** for gp3 / gp5 / gp6 (gp4 = 61) and
/// `gpRegimentInputDealsAsBuyer` is still **0** for every GP. OW gain is
/// unchanged: gp1 = +6, gp2 = +6 (PASS); gp3 = +2, gp4 = +1, gp5 = +1,
/// gp6 = +2 (FAIL).
///
/// New feedstock-stage fields localize the domestic `wool` / `cotton` ->
/// `fabric` production break **precisely**, and refute the prior "no feedstock
/// / create a fabric seller" framing of the H8-supply surface:
///
///   * `gpUnimprovedFeedstockTileOwnedTurns` = **100** for every GP — the
///     failing GPs own an unimproved `wool` / `cotton` resource tile a Builder
///     could extract on *every* turn. Feedstock geography is **not** the
///     blocker.
///   * `gpFeedstockExtractionGateActiveTurns` = **29 / 52 / 51** for
///     gp3 / gp5 / gp6 (0 for gp1 / gp2 / gp4) — the #3234 / #3235
///     Builder-routing gate (`regimentBuildInputFeedstockExtractionResourceIds`)
///     fires on exactly the rebuild-ready turns, as designed.
///   * `gpFeedstockInStockpileTurns` = **1** for every GP — yet `wool` /
///     `cotton` reaches the stockpile only a single turn the entire run.
///   * `gpFabricRecipeFeasibleTurns` = **1** for every GP — a `fabricFrom*`
///     recipe is feasible for >= 1 run only that same single turn.
///
/// Conclusion: the feedstock tile **exists** and the extraction-routing gate
/// **fires** for 29-52 turns, but the feedstock never lands in the stockpile.
/// The break is therefore **upstream of recipe feasibility and world-market
/// supply** — the routed Builder is not improving the feedstock tile (or the
/// improved tile is not extracting `wool` / `cotton` into the stockpile) under
/// the lock. The next slice must look at Builder availability / work
/// assignment and the extraction step, not at recipe scoring or a world-market
/// `fabric` seller.
///
/// ### H8-extraction execution-gap disambiguation (this slice, Refs #2847)
///
/// Two read-only sub-counters split the gate-active turns by Builder
/// availability and improvement completion (`dart test --run-skipped`, merged
/// `dev` baseline):
///
///   * `gpFeedstockGateIdleBuilderPresentTurns` = **29 / 52 / 51** for
///     gp3 / gp5 / gp6 — **equal to** `gpFeedstockExtractionGateActiveTurns`.
///     A free Builder (`currentWork == null`) is available on **every**
///     gate-active turn. The "no idle Builder to route" cause is **ruled out**.
///   * `gpFeedstockGateImprovedTileOwnedTurns` = **0** for **every** GP — the
///     Builder **never** finishes improving a feedstock tile across the whole
///     run, even though one is owned (`gpUnimprovedFeedstockTileOwnedTurns` =
///     100) and a free Builder exists every gate-active turn.
///
/// This **refutes** the transport-cap / extraction-step hypothesis (which would
/// show `gpFeedstockGateImprovedTileOwnedTurns` high with
/// `gpFeedstockInStockpileTurns` near-zero) and **also** the "improvement
/// preempted mid-work" hypothesis (which would still leave the tile improved on
/// the turn it completes). The improved-tile count is flat **zero**, so the
/// break is precisely at **work assignment → improvement completion**: a free
/// Builder and an unimproved feedstock tile coexist for 29-52 turns, yet the
/// `build_improvement` is never taken on that tile. The next slice (H8-extraction
/// production fix) must determine why `suggestWorkOrders` never yields a
/// `build_improvement` candidate for the owned unimproved feedstock tile for the
/// idle Builder — the #3234 score boost can only bias a candidate that exists,
/// so a missing candidate (Builder→tile reachability / suggestion gating), not
/// the boost magnitude, is the live suspect — and verify by re-running this
/// diagnostic and confirming `gpFeedstockGateImprovedTileOwnedTurns` and
/// (downstream) `gpFeedstockInStockpileTurns` rise for gp3 / gp5 / gp6.
///
/// ### H8-extraction missing-candidate disambiguation (this slice, Refs #2847)
///
/// Two further read-only sub-counters split the "work assignment →
/// improvement completion" gap by (a) whether the work-order engine accepts a
/// feedstock `build_improvement` candidate at all and (b) whether the GP can
/// afford the level-0 improvement cost (`dart test --run-skipped`, merged `dev`
/// baseline):
///
///   * `gpFeedstockGateValidBuildImprovementCandidateTurns` = **0** for
///     **every** GP — `getValidWorkOrderTileKeys` (the same validator chain
///     `suggestWorkOrders` runs) **never** accepts a `build_improvement` on an
///     owned unimproved feedstock tile for the idle Builder. This **confirms**
///     the candidate is suppressed by the work-order validator before any
///     selection score boost (#3234) can apply, exactly as the missing-candidate
///     hypothesis predicted.
///   * `gpFeedstockGateImprovementCostAffordableTurns` = **0** for **every**
///     GP — the GP **never** holds the level-0 `build_improvement` material cost
///     (1 lumber + 1 cast iron, `work_order_costs.dart`) on a gate-active turn.
///
/// Both counts are flat **zero in lockstep**. The validator checks the
/// material-cost gate (`work_order_validator.dart` § `_validateWorkMaterialCosts`)
/// and rejects any `build_improvement` whose lumber / cast-iron cost the
/// stockpile cannot cover. With cost-affordable == 0 every gate-active turn,
/// the suppression is pinned to that gate — a **lumber / cast-iron deadlock**:
/// the locked GP must improve a `wool` / `cotton` tile to produce `fabric` for
/// its cheapest regiment, but the improvement itself costs lumber + cast iron it
/// never holds. This re-points the next slice off "Builder→tile reachability"
/// (control / visibility) and onto **improvement-input supply** — the routed
/// Builder cannot be assigned until the GP holds 1 lumber + 1 cast iron. Verify
/// by re-running this diagnostic and confirming
/// `gpFeedstockGateImprovementCostAffordableTurns`,
/// `gpFeedstockGateValidBuildImprovementCandidateTurns`,
/// `gpFeedstockGateImprovedTileOwnedTurns`, and (downstream)
/// `gpFeedstockInStockpileTurns` rise for gp3 / gp5 / gp6.
///
/// ## Updated S7-T tuning surface (ordered by the feedstock-stage split)
///
/// Constraint per issue § Scope constraint unchanged: **phase-planner /
/// orchestrator logic only**, **no new config constants**, **no value
/// changes** to existing constants in
/// `packages/colonizethis_data/lib/src/ai_victory_config.dart`.
///
///   1. **H8-extraction (new, highest signal): feedstock Builder work
///      assignment.** Gate active 29-52 turns + unimproved feedstock tile owned
///      100 turns + **idle Builder present every gate-active turn**
///      (`gpFeedstockGateIdleBuilderPresentTurns` == gate-active turns), yet
///      `gpFeedstockGateImprovedTileOwnedTurns` == 0 and
///      `gpFeedstockInStockpileTurns` == 1. The missing-candidate disambiguation
///      above pins the cause to the **work-order validator material-cost gate**:
///      `gpFeedstockGateValidBuildImprovementCandidateTurns` == 0 and
///      `gpFeedstockGateImprovementCostAffordableTurns` == 0 every gate-active
///      turn, so the feedstock `build_improvement` candidate is rejected because
///      the GP cannot afford the level-0 cost (1 lumber + 1 cast iron) — a
///      lumber / cast-iron deadlock, not Builder availability, control /
///      visibility, recipe scoring, transport-cap extraction, the #3234 boost
///      magnitude, or a world-market `fabric` seller. The next slice must supply
///      the improvement inputs (domestic lumber / cast-iron extraction or
///      market acquisition for the lock-recovery seller, or a scoped
///      affordability relaxation analogous to the first-naval-transport
///      bootstrap). Verify by re-running this diagnostic and confirming
///      `gpFeedstockGateImprovementCostAffordableTurns`,
///      `gpFeedstockGateValidBuildImprovementCandidateTurns`,
///      `gpFeedstockGateImprovedTileOwnedTurns`, `gpFeedstockInStockpileTurns`,
///      and (downstream) `gpCheapestRegimentInputsInStockpileTurns` rise for
///      gp3 / gp5 / gp6.
///   2. **H4-b (regiment-holding case): gp4 reach / offensive strength**
///      against the locked peer (unchanged; see #3224).
///   3. **H2 (still open): residual peer-war re-declare oscillation.**
///
/// ## S7-D refresh (captured 2026-06-04 on branch
///     `fix/issue-2847-h8-extraction-improvement-input`, after the lock-recovery
///     improvement-input bid carve-out (#3238) **and** the supply-side
///     treasury-gate removal + improvement-input localization added in this
///     slice)
///
/// The improvement-input bid carve-out alone (#3238) did **not** move the
/// binding metric: `gpFeedstockGateImprovementCostAffordableTurns` stayed
/// **0 / 0 / 0** for gp3 / gp5 / gp6 and `gpRegimentInputDealsAsBuyer` stayed
/// **0**, with OW gain unchanged (gp1 = +6, gp2 = +6 PASS; gp3 = +2, gp4 = +1,
/// gp5 = +1, gp6 = +2 FAIL). The new improvement-input counters
/// (`improvementInputCommodityIds = [castIron, lumber]`) localize the remaining
/// break **decisively**:
///
export 's7d_findings_feedstock_extraction_early_refresh.dart';
