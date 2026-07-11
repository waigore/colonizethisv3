/// World-market lock-recovery S7-D findings (Refs #2924 / #2847 / #3972).
///
/// Step-0 lock-recovery metrics surface and the decisive global castIron
/// labour-wall refresh that supersedes prior peasant-recruit fabric framing.
///
library;

// ignore_for_file: dangling_library_doc_comments

/// ## Refs #2924 Step 0 — world-market lock-recovery metrics
///
/// The same run now also emits a separate
/// `ISSUE2924_STEP0_JSON_*`-delimited block scoped to the
/// world-market lock-recovery path required by issue #2924
/// § Recommended sequencing Step 0. The block records per-GP
/// totals for: trade orders the AI emits each turn (offers / bids
/// plus urgent-priority offers at
/// [kTreasuryOfferPriorityUrgent]); deals matched in phase 13
/// counted as seller / buyer; treasury credited (seller side
/// notional) and debited (buyer side notional); transitions of
/// post-turn treasury across [cheapestRegimentBuildTreasuryCost]
/// (and the first turn each GP first reaches the threshold);
/// plus the pre-existing
/// `gpTreasuryUnderCheapestRegimentTurns` count from the #2847
/// surface. Copy this block into a fresh comment on issue #2924
/// when refreshing the Step 0 decision-gate evidence.
///
/// ## S7-D refresh (captured 2026-06-08 on `dev` HEAD — decisive **global
///     castIron labour wall**; the #3354 fabric-offer counters are dormant /
///     inconclusive this run; Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD relocates the binding
/// constraint and **supersedes** every prior "next slice" framed around the
/// castIron-labour peasant-recruit fabric path. OW gain: gp1 = +6, gp2 = +6
/// (PASS); gp3 = 0, gp4 = +3, gp5 = −7, gp6 = +10 — gp3 and gp5 FAIL. The +6
/// baseline holds.
///
///   * **castIron is labour-unproducible for EVERY great power, suppliers
///     included.** `gpCastIronRecipeLabourFeasibleTurns` = **0 for all six
///     GPs**, while `castIronMinLabourPerOutput` = **5** and every GP's turn-99
///     `rawLabourSupply` is **≤ 3** (gp4 = 3; gp1/gp2/gp3/gp5/gp6 = 2). gp1 is
///     castIron *material*-feasible 35 turns (holds `timber` + `iron`) yet
///     labour-feasible **0** — even the richest supplier cannot run the recipe.
///     `gpCastIronHeldAtTurn99` = 0 for all six and
///     `gpCastIronProductionAssignedTurns` = 0 for all six: no castIron is ever
///     produced or held anywhere in the game.
///   * **The level-0 `build_improvement` chain is therefore globally severed at
///     its castIron input.** Its cost is 1 `lumber` + 1 `castIron`
///     (`work_order_costs.dart` § `workOrderCostBuildImprovement`). The
///     `lumber` half is reachable (gp3 `gpFeedstockGateImprovementLumber
///     AffordableTurns` = 22) but the castIron half never is
///     (`gpFeedstockGateImprovementCastIronAffordableTurns` = 0 for all,
///     `gpFeedstockGateImprovementCostAffordableTurns` = 0 for all), and the
///     market cannot supply it either (`gpCastIronMarketOfferAbsentTurns` gp3 =
///     46 — no other GP ever offers `castIron`, because none holds any). So the
///     failing GPs' recovery chain (extract `cotton`/`wool` via
///     `build_improvement` → produce `fabric` → build `peasant_levies` →
///     conquer) is cut at the castIron step that no GP can produce or sell.
///   * **gp3 is gated purely on one unobtainable `fabric`.** Turn-99: treasury
///     2164 (≥ the 2000 regiment cost), **0 regiments**, **4 invadable OW
///     provinces**, rebuild-ready 45 turns, **all** of them missing-input
///     (`gpRebuildReadyNoBuildMissingInputTurns` gp3 = 45; the missing input is
///     the cheapest regiment's lone `fabric`). It has the treasury and the
///     targets to clear the +3 gate; it cannot because the only routes to
///     `fabric` (domestic conversion of extracted `cotton`/`wool`, or the
///     market) both dead-end at the global castIron wall above.
///   * **gp5 is a distinct peer-war attrition collapse, not the castIron
///     wall.** It loses all 7 OW provinces (7 → 0), stays in EXPAND all 100
///     turns, hoards treasury (1999) yet bleeds OW while at war with
///     `tribe1`/`tribe6`/`gp6` (`gpInvadableEmptyTurns` gp5 = 44). This is the
///     pre-existing attrition-war failure class, orthogonal to gp3's supply
///     wall.
///   * **The #3354 `gpFabricMarketOfferPresentTurns` / `…AbsentTurns` counters
///     are 0 / 0 for every GP — dormant, not informative, this run.** The
///     castIron-labour peasant-recruit fabric path never activates
///     (`gpCastIronLabourPeasantRecruitGateTurns` = 0 for all): its precondition
///     `isCastIronLabourPopulationBoundForLockRecoverySeller` requires castIron
///     *material* feasibility (both `timber` + `iron` held), which gp3/gp5 never
///     reach (`iron` = 0). The peasant-recruit fabric framing of the prior
///     "next slice" is therefore moot for the current failing GPs — the wall is
///     one stage upstream (the `build_improvement` castIron input), and is
///     global.
///
/// **Re-pointed next slice (supersedes the peasant-recruit fabric / fabric
/// offer-side / castIron offer-tier candidates):** the binding constraint is a
/// **rules-level global castIron labour wall** — the only `castIron` recipe
/// needs `labourPerOutput == 5` while no GP's raw labour ceiling exceeds 3, so
/// castIron is unproducible game-wide and the level-0 `build_improvement`
/// (the gate to the failing GPs' `fabric` → regiment recovery) can never be
/// afforded or sourced. **No AI-planner lever can close this**: supplier
/// over-production, offer-tier alignment, peasant-recruit fabric staging, and
/// buyer-side bidding all presuppose a castIron supply that does not and cannot
/// exist. The lever is **out of #2847's AI-planner scope** (the issue's scope
/// constraint forbids `ai_victory_config.dart` and rules changes): it requires
/// a rules/economy change — lower the `castIron` recipe `labourPerOutput` (or
/// the `build_improvement` castIron requirement), or a raw-labour bootstrap
/// that lifts a lock-recovery seller's labour ceiling toward 5 without the
/// `fabric`-gated peasant recruit — and should be escalated to the #2509
/// umbrella or a dedicated rules issue. gp5's attrition collapse remains a
/// separate peer-war class needing an EXPAND attrition-war escape, likewise
/// beyond a single non-regressive planner slice. This refresh is a read-only
/// diagnostic-ledger localization (no behaviour change, no config constants, no
/// gate-threshold changes).
