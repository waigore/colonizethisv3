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
/// ### H8-extraction produced build-input retention (this slice, Refs #2847)
///
/// This slice closes the offer-side **symmetry gap** in the lock-recovery
/// seller carve-out: the planner already withholds the fabric **feedstock**
/// (`wool` / `cotton`) from a recovered zero-regiment seller's offers
/// (treasury-planner.md § Build-input feedstock reservation), but it did **not**
/// withhold the **produced build input** (`fabric`) itself. A recovered
/// below-quota zero-NW seller is a strong-cargo Path-F seller that offers its
/// surplus urgently every turn, so the `fabric` the economy-planner production
/// boost produced was sold back into the world market before it could
/// accumulate to the `peasant_levies` build cost. The fix withholds every
/// `peasant_levies` build-input commodity under the **same** rebuild gate
/// (below-quota zero-NW lock-recovery seller, `treasury >= cheapest cost`,
/// zero regiments); it self-clears the turn a regiment lands. See
/// treasury-planner.md § Produced build-input retention.
///
/// **Effect on the seed-42 surface (post-fix refresh):** the +6 OW baseline is
/// preserved (gp1 = +6, gp2 = +6, gpRegimentPeak gp1 / gp2 = 5 / 5 unchanged)
/// and behaviour is no longer byte-identical to the post-waiver baseline
/// (gp5 / gp6 swap +2 / +1 → +1 / +2; gp5 now spends 15 colonial turns vs 1),
/// but **no failing GP reaches the +3 floor** — the turn-100 OW gate stays
/// open (gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2).
///
/// **Re-localization (binding constraint after this slice):** retention is
/// **necessary but not sufficient** — it keeps produced `fabric`, but `fabric`
/// is not *produced* on most feasible turns. For gp5 / gp6 the fabric recipe is
/// feasible ~44 turns (`gpFabricRecipeFeasibleTurns` = 46 / 42, feedstock on
/// hand 48 / 43) yet `gpRebuildReadyNoBuildMissingInputTurns` stays 7 / 11 and
/// gp3 = 29 (and `gpRebuildReadyNoBuildInputsPresentTurns` = 0 for all — when
/// the input *is* present they build). So on most rebuild-ready turns `fabric`
/// is missing despite a feasible recipe: the economy-planner regiment
/// build-input production boost is not actually assigning the `fabricFrom*`
/// recipe. gp3 additionally never accumulates feedstock
/// (`gpFeedstockInStockpileTurns` = 1 despite `gpFeedstockGateImprovedTileOwnedTurns`
/// = 27). The next slice must target **fabric production allocation** (make the
/// economy planner run the `fabricFrom*` recipe on feasible rebuild turns for
/// the lock-recovery seller), not the offer side (feedstock reservation and
/// build-input retention are both now in place). Verify by re-running this
/// diagnostic and confirming `gpRebuildReadyNoBuildMissingInputTurns` falls for
/// gp5 / gp6 before expecting OW gain to move.
///
/// ### H8 treasury-independent production allocation (this slice, Refs #2847)
///
/// This slice de-gates the regiment build-input **production boost**
/// (economy-planner.md § Regiment build-input production priority
/// § Treasury-independent staging) and the offer-side **retention** /
/// **feedstock reservation** (treasury-planner.md) from
/// `player.treasury >= cheapestRegimentBuildTreasuryCost()`. The phase planner
/// already sets `forceCheapestRegimentBuild` (arm A) regardless of treasury "so
/// the rebuild trap cannot stick", but the prior treasury clause re-imposed
/// that trap on the *input*: the cheap build input was only produced on the
/// rare recovered turn, never staged ahead of it, so the multi-turn
/// `feedstock → fabric → build` chain could not finish inside the brief
/// recovery window. Production / retention now stage the input while broke
/// (they spend no treasury); only the market **bids** and the actual build
/// order remain treasury-gated.
///
/// **Effect on the seed-42 surface (post-fix refresh, 100-turn local run):**
///
///   * **+6 OW baseline preserved** — gp1 = +6, gp2 = +6, `gpRegimentPeak`
///     5 / 5 unchanged. No failing GP regressed below its prior gain; the
///     turn-100 OW gate aggregate stays gp3 / gp4 / gp5 / gp6 = +2 / +1 / +2 / +1
///     (gp5 / gp6 swap +1 / +2 → +2 / +1, a deterministic reshuffle, net zero).
///   * **Staging mechanism now works** — gp4 holds `fabric` 61 of 100 turns
///     (`gpCheapestRegimentInputsInStockpileTurns` gp4 = 61) where the prior
///     treasury-gated boost banked it on only a handful, confirming the input
///     is staged ahead of treasury and consumed into builds
///     (`gpMilitaryBuildOrdersEmitted` gp4 = 4, gp5 / gp6 = 3 / 4).
///
/// **Re-localization (binding constraint after this slice):** fabric production
/// is no longer the gp5 / gp6 bottleneck. `gpRebuildReadyNoBuildMissingInputTurns`
/// stays 7 / 11 for gp5 / gp6 **not** because fabric is unproducible but because
/// each turn the GP loses a regiment to its peer war it re-enters the
/// missing-input window before the next staged `fabric` lands:
/// `gpRegimentTurnsAtZero` = 15 / 20 for gp5 / gp6 while they *do* build
/// 3 regiments each (`gpRegimentPeak` 3 / 3). The constraint has therefore moved
/// to **peer-war regiment attrition** (hypotheses H2 / H4: the gp3↔gp4 and
/// gp5↔gp6 mutual peer-war lock) — the failing GPs rebuild but cannot hold or
/// grow regiments faster than the peer war strips them. gp3 remains a separate
/// **feedstock-extraction** residual (`gpFeedstockInStockpileTurns` = 1 despite
/// `gpRebuildReadyNoBuildMissingInputTurns` = 29): its civilian-work feedstock
/// gate is still treasury-gated (deliberately out of scope for this slice), so
/// gp3 holds no `wool` / `cotton` to convert. The next slices should target the
/// peer-war attrition exit for gp5 / gp6 and de-gate the feedstock-extraction
/// civilian-work boost for gp3 — not the fabric production / offer side, which
/// is now treasury-independent.
///
/// ### H8 treasury-independent feedstock-extraction routing (this slice, Refs #2847)
///
/// This slice closes the **last treasury-gated link** the #3252 re-localization
/// named: the civilian-work feedstock-extraction routing gate
/// (`regimentBuildInputFeedstockExtractionResourceIds`,
/// `full_ai_civilian_work_selection.dart`) still required
/// `player.treasury >= cheapestRegimentBuildTreasuryCost()`. #3252 had already
/// de-gated the regiment build-input *production* boost and the offer-side
/// retention / feedstock reservation from treasury, but the *routing* boost that
/// puts the seller's idle Builder on its own `wool` / `cotton` tile was still
/// only active on the rare recovered turn. Routing a Builder spends no treasury,
/// so gating it re-imposed the rebuild trap on the input. The fix drops the
/// treasury clause; the `regimentCount == 0` / below-quota / zero-NW / missing-
/// input scoping is unchanged, so the +6 baseline GPs (which hold regiments) are
/// never routed, and the market **bids** stay treasury-gated at their
/// `treasury_planner.dart` call site (economy-planner.md § Treasury-independent
/// feedstock extraction; the parenthetical mirrors § Treasury-independent
/// staging for production).
///
/// **Effect on the seed-42 surface (post-fix refresh, 100-turn local run):**
///
///   * **+6 OW baseline preserved** — gp1 = +6, gp2 = +6 (PASS),
///     `gpRegimentPeak` 5 / 5 unchanged. No failing GP regressed: OW gain stays
///     gp3 / gp4 / gp5 / gp6 = +2 / +1 / +2 / +1, byte-identical to the
///     post-#3252 baseline.
///   * **Routing now fires treasury-independently** — `gpFeedstockExtraction
///     GateActiveTurns` rises gp3 29 → 32, gp5 7 → 13, gp6 11 → 19 (the boost
///     now activates on broke turns), confirming the de-gate is effective at its
///     scope.
///
/// **Re-localization (binding constraint after this slice):** the extra
/// gate-active turns do **not** convert into held feedstock for gp3
/// (`gpFeedstockInStockpileTurns` gp3 = 1 despite `gpFeedstockGateImprovedTile
/// OwnedTurns` gp3 = 27): gp3's owned feedstock tile *is* improved on most gate
/// turns yet yields no `wool` / `cotton` into the stockpile — the **transport /
/// extraction-connectivity** stage (the improved tile is not extraction-
/// connected), one stage downstream of routing. The next slice for gp3 must
/// target that connectivity (e.g. route a Builder onto rail / transport for the
/// improved feedstock tile), **not** the routing gate (now treasury-independent)
/// or the production / offer side (treasury-independent since #3252). gp5 / gp6
/// remain the peer-war regiment-attrition residual (H2 / H4). Verify a gp3
/// connectivity slice by confirming `gpFeedstockInStockpileTurns` gp3 rises
/// above 1 before expecting OW gain to move.
///
