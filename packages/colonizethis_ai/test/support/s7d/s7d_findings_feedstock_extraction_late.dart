/// Feedstock-stage / H8 extraction S7-D findings — part 2 (Refs #2847 / #3972).
///
/// Cast-iron / supplier-side diagnostics and post-#3247 instrumentation.
///
library;

// ignore_for_file: dangling_library_doc_comments

/// ## S7-D refresh (captured 2026-06-04 on merged `dev` after #3247 —
///     `gpSupplierActiveUnimprovedCastIronFeedstockTileTurns` and
///     `gpCastIronFeedstockHeldAtTurn99` instrumentation added here)
///
/// #3247 (`economy_planner.dart` feedstock-reservation) reserves one
/// `castIron` run's `timber` + `iron` from competing single-input recipes so
/// the feedstock can co-accumulate. Re-running the diagnostic on the merged
/// post-#3247 `dev` shows **no change** to the gate (gp1 / gp2 = +6 PASS; gp3 =
/// +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL) and `gpCastIronProductionAssignedTurns
/// == 0` for every GP. The two new counters localize *why* the reservation is
/// inert decisively:
///
///   * **The supplier owns an unimproved `iron` tile the whole time:**
///     `gpSupplierActiveUnimprovedCastIronFeedstockTileTurns` = `{timber: 52,
///     iron: 52}` for both gp1 and gp2 (and `{7, 7}` for gp3). The earlier
///     hypothesis that the supplier *lacks* an `iron` tile is **refuted** — an
///     extraction target exists on every gate-active turn.
///   * **Yet `iron` is never extracted:** `gpCastIronFeedstockHeldAtTurn99` =
///     `{timber: 3, iron: 0}` for gp2 (`{0, 0}` for gp1), `gpLumberHeldAtTurn99`
///     gp2 = 44. The supplier still routes its extracted `timber` into `lumber`
///     and the owned `iron` tile stays unimproved, so the reserved `iron` slot
///     can never be filled and `feasibleRuns(castIron)` stays 0.
///
/// **Tested-but-inert next-slice finding (no code shipped for it).** A
/// per-commodity scarcity tie-break in `_buildImprovementWorkScore`
/// (`full_ai_civilian_work_selection.dart`) that boosts the feedstock the GP
/// holds least of — unit-verified in isolation
/// (`full_ai_civilian_work_supplier_feedstock_extraction_test.dart`) to flip a
/// Builder onto the `iron` tile when `timber` is held — produced **byte-identical**
/// seed-42 output. So the supplier's idle Builder never evaluates the OW `iron`
/// `build_improvement` in-sim at all: this is **not** a tile-selection tie-break
/// problem. The next slice must target *why* the owned-unimproved `iron`
/// `build_improvement` is never selected (no free Builder during the gate, the
/// `iron` tile is not emitted as a `build_improvement` suggestion, or it is
/// outranked by New World civilian work the affluent supplier prefers), or pivot
/// away from domestic supplier `castIron` production entirely (relax the level-0
/// `build_improvement` `castIron` requirement for the bootstrap extraction, or a
/// market-sourced `iron` path).
///
/// ## S7-D refresh (captured 2026-06-04 on branch
///     `feat/issue-2847-feedstock-build-improvement-suggestion-priority`, after
///     the worker-pipeline feedstock `build_improvement` suggestion-priority
///     reorder added in PR #3250 — `_prioritizeFeedstockBuildImprovementCandidates`,
///     `order_suggestion_work_worker.dart`)
///
/// PR #3250 targets the post-#3249 hypothesis (b) — "the `iron` tile is not
/// emitted as a `build_improvement` suggestion." The worker suggestion pipeline
/// emits only the **first accepted** `build_improvement` candidate per Builder
/// ([WorkSuggestionPipeline.run] with `includeAllAccepted: false`), so the lone
/// suggested tile was whichever sorted first lexicographically — rarely the
/// feedstock tile. The slice stable-partitions unimproved feedstock tiles ahead
/// so the downstream [kRegimentBuildInputFeedstockExtractionScoreBoost] has a
/// suggestion to re-rank. Re-running the diagnostic on this branch shows the
/// slice is **inert on seed-42 with no regression**:
///
///   * **OW gain byte-identical:** gp1 = +6, gp2 = +6 (PASS); gp3 = +2, gp4 =
///     +1, gp5 = +1, gp6 = +2 (FAIL) — unchanged from the post-#3247 baseline.
///     The reorder does not divert the +6 baseline GPs' conquest.
///   * **`gpCastIronProductionAssignedTurns` = 0 for every GP**, and
///     `gpCastIronHeldAtTurn99` = 0 for every GP — no castIron is ever produced.
///
/// The decisive new localization is `gpFeedstockGateValidBuildImprovementCandidate
/// Turns` = **0 for every GP** alongside `gpFeedstockGateImprovementCostAffordable
/// Turns` = **0 for every GP**: the validator (`getValidWorkOrderTileKeys`, the
/// chain `suggestWorkOrders` runs) **never accepts** a `build_improvement` on the
/// owned unimproved feedstock tile, so the new reorder helper has **nothing to
/// reorder** — the partition is a no-op because both partitions are taken from an
/// already-empty accepted set. This **refutes hypothesis (b) as the *binding*
/// cause**: the suggestion is absent not because of candidate *ordering* but
/// because no *affordable* candidate exists. The level-0 `build_improvement`
/// material cost is `1 lumber + 1 castIron` (`work_order_costs.dart` §
/// `workOrderCostBuildImprovement`), and `gpCastIronHeldAtTurn99` = 0 for every
/// GP, so the validator's `_validateWorkMaterialCosts` rejects the candidate
/// before any ordering or score boost applies. This is the **circular castIron
/// dependency** pinned to its root: extracting the `iron` / `timber` that feeds
/// `castIron` itself *costs* `castIron`, so no GP can bootstrap its first
/// `castIron` from domestic extraction.
///
/// Conclusion: PR #3250 is a **correct-by-construction prerequisite** (the worker
/// should surface the feedstock tile first once a candidate is affordable, and
/// the change is unit-tested in
/// `order_suggestion_work_feedstock_priority_test.dart`) but is **insufficient on
/// seed-42** — it cannot fire until an affordable level-0 `build_improvement`
/// candidate exists. The remaining break is one stage upstream of suggestion
/// ordering: the **unaffordable level-0 `castIron` requirement** for the very
/// first bootstrap extraction. The next slice must therefore pursue the
/// domestic-production *pivot* flagged above — relax the level-0
/// `build_improvement` `castIron` requirement for the first bootstrap extraction
/// under the lock-recovery trigger (SPEC-authorized cost change, scoped to the
/// first extraction only, must preserve the gp1 / gp2 +6 baseline), or wire a
/// market-sourced first-`castIron` path — **not** another suggestion-ordering or
/// tile-selection tweak (no accepted candidate exists for either to act on).
/// Verify by re-running this diagnostic and confirming
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` and
/// `gpFeedstockGateImprovementCostAffordableTurns` rise above 0 before expecting
/// `gpCastIronProductionAssignedTurns` or OW gain to move.
///
/// ## S7-D refresh (captured 2026-06-04 on branch
///     `feat/issue-2847-feedstock-build-improvement-suggestion-priority`,
///     PR #3250, after the level-0 `build_improvement` castIron waiver
///     `e2d139db2`)
///
/// The level-0 `build_improvement` `castIron` waiver
/// (`feedstockBootstrapBuildImprovementCastIronWaived` +
/// player-scoped `WorkOrderCostCalculator`) **does** move the prerequisite
/// metric the prior refresh asked to verify, **without regressing the gp1 / gp2
/// +6 baseline**, but it does **not** close the turn-100 OW gate on its own:
///
///   * **OW gain:** gp1 = +6, gp2 = +6 (PASS, baseline preserved); gp3 = +2,
///     gp4 = +1, gp5 = +2, gp6 = +1 (FAIL). Behaviour is no longer
///     byte-identical to the post-#3247 baseline (gp5 / gp6 swapped +1/+2 →
///     +2/+1) but no failing GP reaches the +3 floor.
///   * **`gpFeedstockGateValidBuildImprovementCandidateTurns` rises above 0 for
///     the first time:** gp3 = 14, gp4 = 0, gp5 = 3, gp6 = 5 (was 0 / 0 / 0 / 0
///     pre-waiver). The waiver makes `getValidWorkOrderTileKeys` (the same
///     validator chain `suggestWorkOrders` runs) **accept** the
///     `build_improvement` on the owned unimproved feedstock tile — the missing
///     candidate the prior six refreshes pinned is now present.
///   * **`gpFeedstockGateImprovementCostAffordableTurns` stays 0 / 0 / 0** — by
///     design: that counter measures affordability of the **full** `1 lumber +
///     1 castIron` cost, which the waiver intentionally bypasses, so it no
///     longer reflects the binding constraint. Use
///     `gpFeedstockGateValidBuildImprovementCandidateTurns` as the live
///     prerequisite signal post-waiver.
///   * **Downstream still flat:** `gpCastIronProductionAssignedTurns` = 0,
///     `gpCastIronHeldAtTurn99` = 0, and `gpCastIronFeedstockHeldAtTurn99`
///     `timber` / `iron` ≈ 0 for every GP. The now-valid candidate does not
///     convert into held feedstock, domestic `castIron` production, or OW
///     conquest within 100 turns.
///
/// Conclusion: the waiver is **correct-by-construction and effective at its
/// scope** — it breaks the circular `castIron` dependency at the validator and
/// surfaces an affordable level-0 feedstock `build_improvement` for the locked
/// sellers (gp3 / gp5 / gp6). It is a valid, SPEC-authorized prerequisite, not a
/// regression. The remaining break is now **downstream of candidate validity**:
/// the routed Builder's extraction does not accumulate `timber` + `iron`
/// together, so no `castIron` run becomes feasible and the OW conquest gate
/// stays open. The next slice must target **feedstock co-availability →
/// `castIron` production → conquest conversion** (e.g. reserve the routed
/// Builder's extracted `timber` / `iron` from the competing feasible `lumber`
/// recipe until one `castIron` run completes), **not** the level-0 cost (already
/// waived) or suggestion ordering (already correct). Verify by re-running this
/// diagnostic and confirming `gpCastIronFeedstockHeldAtTurn99` (`timber` **and**
/// `iron` > 0 simultaneously) then `gpCastIronProductionAssignedTurns` rise for
/// gp3 / gp5 / gp6 before expecting OW gain to move.
///
export 's7d_findings_feedstock_extraction_late_tail.dart';
