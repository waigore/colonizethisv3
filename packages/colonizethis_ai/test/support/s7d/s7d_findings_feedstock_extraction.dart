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
///   * **Supply now exists.** Dropping the `rawTreasury >= threshold` gate on the
///     supplier role (so a GP releasing a *surplus* sells regardless of its own
///     treasury) lifts `gpImprovementInputOffersEmitted` for gp2 from 0 to **40**
///     (`gpImprovementInputHeldAtTurn99` gp2 = **48**). Before this slice no GP
///     released lumber / cast iron because the only holders (gp1 / gp2) sit far
///     below the regiment-affordable band. The supply-side fix works as intended.
///   * **Demand exists.** The locked sellers emit improvement-input bids:
///     `gpImprovementInputBidsEmitted` = **13 / 0 / 22 / 22** for gp3 / gp4 / gp5 /
///     gp6 (gp4's gate is inactive, so 0 is expected).
///   * **Yet zero deals fill.** `gpImprovementInputDealsAsBuyer` = **0** for every
///     GP across all 100 turns. A standing lumber / cast-iron bid (13-22 turns)
///     and a standing offer (40 turns, 48 surplus held) **coexist** but never
///     cross.
///
/// Conclusion: the break has moved one decisive step downstream — from "no
/// supply" (the #3238 / supply-side target) to **world-market order matching**.
/// Both sides of the lumber / cast-iron trade are present every turn yet the
/// matcher never pairs them. This **refutes** the supply-availability framing and
/// **also** the "seller never bids" framing (bids are emitted). The next slice
/// must look at why the bid and offer do not cross — price crossing
/// (`_marketPriceBelowProductionCost` / offer vs bid price), bid priority tier
/// vs the urgent grain-liquidity bid, the per-buyer treasury clamp (#3115), or
/// the `bidTypeCap` slot allocation — **not** supply, bid emission, the validator
/// material-cost gate, Builder availability, or recipe scoring. Verify by
/// re-running this diagnostic and confirming `gpImprovementInputDealsAsBuyer`
/// then (downstream) `gpFeedstockGateImprovementCostAffordableTurns` rise for
/// gp3 / gp5 / gp6.
///
/// ## S7-D refresh (captured 2026-06-04 on merged `dev` @ `168d03df`, post-#3241
///     castIron-domestic-production slice) — castIron-feedstock localization
///
/// #3241 made the locked seller buy `lumber` directly and **produce** `castIron`
/// domestically from its production feedstock (`timber` + `iron`), because no GP
/// offers a `castIron` surplus. The binding metric is unchanged: OW gain gp1/gp2
/// = +6 PASS, gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL, and
/// `gpFeedstockGateImprovementCostAffordableTurns` stays **0 / 0 / 0** for
/// gp3 / gp5 / gp6 — the seller never holds both `lumber` **and** `castIron` at
/// once. The new castIron-feedstock counters localize the residual **decisively**:
///
///   * **The seller bids castIron's feedstock.** `gpCastIronFeedstockBidsEmitted`
///     = **15 / 0 / 26 / 27** for gp3 / gp4 / gp5 / gp6 — the #3241 Pass-2 bid for
///     `timber` + `iron` fires on the rebuild-ready turns.
///   * **But nobody offers it.** `gpCastIronFeedstockOffersEmitted` = **0** for
///     *every* GP — `timber` / `iron` are absent from the supplier release set,
///     and (verified out-of-band by temporarily adding them) gp1 / gp2 hold **no
///     true surplus** of either: they extract `timber` / `iron` only to feed
///     their own `castIron` production, so the surplus
///     (`projectedQty − consumption − inputs`) is zero.
///   * **So the bids never fill and castIron is never produced.**
///     `gpCastIronFeedstockDealsAsBuyer` = **0** and
///     `gpCastIronProductionAssignedTurns` = **0** for every GP. The seller holds
///     `lumber` (`gpLumberHeldAtTurn99` = 1 / 1 / 1) but never any `castIron`
///     (`gpCastIronHeldAtTurn99` = 0), so the level-0 `build_improvement`
///     (1 lumber + 1 castIron) is never affordable.
///
/// Conclusion: the H8-extraction deadlock is now pinned to a **structural castIron
/// scarcity** — every tile improvement (including extracting `timber` / `iron`)
/// costs `castIron`, but no GP holds or can release a `castIron` (or `timber` /
/// `iron`) surplus, so the locked seller can neither buy nor produce its first
/// `castIron`. Adding `timber` / `iron` to the supplier release set alone does
/// **not** help (no holder has surplus to release). The next slice must create a
/// genuine first-castIron source for the locked seller — e.g. an affluent
/// supplier *over-producing* `castIron` (or its `timber` / `iron` feedstock) for
/// release when a lock-recovery seller needs it, or relaxing the level-0
/// feedstock-extraction improvement's `castIron` requirement for the first
/// bootstrap extraction — **not** another supply-set membership or order-matching
/// tweak (offers are structurally absent, not mismatched). Verify by re-running
/// this diagnostic and confirming `gpCastIronFeedstockDealsAsBuyer` /
/// `gpCastIronProductionAssignedTurns`, then
/// `gpFeedstockGateImprovementCostAffordableTurns`, rise for gp3 / gp5 / gp6.
///
/// ## S7-D refresh (captured 2026-06-04 on branch
///     `fix/issue-2847-h8-extraction-next`, after the supplier-side castIron
///     over-production + release + seller direct-bid loop added in this slice)
///
/// This slice wires a genuine first-castIron supplier source per the
/// post-#3241 conclusion above: (A) an affluent supplier (not itself a
/// below-quota zero-NW lock-recovery seller) over-produces `castIron` with a
/// moderate leftover-capacity score boost
/// ([kSupplierBuildInputReleaseProductionScoreBoost] = 5.0) whenever some
/// lock-recovery seller needs the level-0 `castIron` improvement input
/// ([anyLockRecoverySellerNeedsCastIronImprovementInput]); (B) the existing
/// surplus-release path activates earlier so the supplier offers the surplus;
/// and (C) the locked seller bids `castIron` **directly** (instead of routing
/// to domestic `timber` / `iron` feedstock) once a standing `castIron` offer
/// exists in the world market. The change is **safe by construction** — the
/// moderate boost only consumes labour / feedstock left over after the
/// supplier's own shortage-driven essentials, so gp1 / gp2 are never starved.
///
/// The diagnostic confirms **no regression and no emergent bite on seed-42**:
///
///   * **OW gain unchanged:** gp1 = +6, gp2 = +6 (PASS); gp3 = +2, gp4 = +1,
///     gp5 = +1, gp6 = +2 (FAIL) — identical to the post-#3241 baseline. The
///     safe-by-construction boost does not regress the passing GPs.
///   * **`gpCastIronProductionAssignedTurns` = 0 for *every* GP** — including
///     the boosted suppliers gp1 / gp2. The +5 boost ranks `castIron` highly,
///     but `feasibleRuns` is still 0 because the suppliers hold **no `timber` /
///     `iron` feedstock** to run the recipe (they extract neither — gp2's only
///     releasable surplus is `lumber`, `gpLumberHeldAtTurn99` gp2 = 45). So no
///     castIron is ever produced, no `castIron` offer is emitted, the seller's
///     gated direct-`castIron` bid never activates
///     (`gpCastIronFeedstockOffersEmitted` / `gpCastIronFeedstockDealsAsBuyer`
///     stay 0), and `gpFeedstockGateImprovementCostAffordableTurns` stays
///     **0 / 0 / 0** — the deadlock persists.
///
/// Conclusion: the supplier-castIron-source loop is now **structurally present
/// and unit-tested** (`treasury_planner_supplier_castiron_source_test.dart`,
/// `economy_planner_regiment_build_input_production_test.dart`), but inert on
/// seed-42 because the missing link is one stage further upstream than a
/// production *boost* can reach — **no affluent supplier holds or extracts the
/// `timber` / `iron` the castIron recipe consumes**, so over-production is
/// infeasible regardless of boost magnitude. This **refutes** the "a boost
/// alone creates the first castIron" framing. The next slice must give an
/// affluent supplier a genuine `timber` / `iron` source for release-driven
/// castIron over-production (supplier feedstock extraction / improvement under
/// the lock-recovery trigger), or relax the level-0 improvement's `castIron`
/// requirement for the first bootstrap extraction. Verify by re-running this
/// diagnostic and confirming `gpCastIronProductionAssignedTurns` rises for
/// gp1 / gp2 (the suppliers), then `gpCastIronFeedstockDealsAsBuyer` and
/// `gpFeedstockGateImprovementCostAffordableTurns` rise for gp3 / gp5 / gp6.
///
/// ## S7-D refresh (captured 2026-06-04 on branch
///     `fix/issue-2847-supplier-castiron-source`, after the supplier feedstock
///     extraction routing added in this slice — `gpSupplierFeedstockExtraction
///     GateActiveTurns` instrumentation added here)
///
/// This slice closes the post-#3244 conclusion's missing link by routing an
/// affluent supplier's idle Builder onto its own unimproved `timber` / `iron`
/// tile (`supplierImprovementInputFeedstockExtractionResourceIds`,
/// `full_ai_civilian_work_selection.dart`), so the #3244 supplier `castIron`
/// over-production + release loop finally has a feedstock source. The new
/// supplier gate **fires** where it was structurally absent before, and there
/// is **no regression**:
///
///   * **OW gain unchanged:** gp1 = +6, gp2 = +6 (PASS); gp3 = +2, gp4 = +1,
///     gp5 = +1, gp6 = +2 (FAIL) — identical to the post-#3244 baseline. The
///     shared civilian-work routing change does not divert the +6 baseline GPs'
///     conquest.
///   * **Supplier gate now active:** `gpSupplierFeedstockExtractionGateActive
///     Turns` = **52 / 52 / 7 / 0 / 0 / 0** for gp1 / gp2 / gp3 / gp4 / gp5 /
///     gp6. The affluent above-quota suppliers gp1 / gp2 own an unimproved
///     `timber` / `iron` tile and a peer locked seller needs `castIron` on 52
///     turns each, so the Builder-routing boost fires — the structural advance
///     over the prior inert slice (the gate previously did not exist).
///   * **But castIron production stays 0:** `gpCastIronProductionAssignedTurns`
///     = **0** for every GP, `gpCastIronHeldAtTurn99` = **0** for every GP, and
///     `gpCastIronFeedstockOffersEmitted` / `gpCastIronFeedstockDealsAsBuyer`
///     stay **0**. gp2 still converts its extracted `timber` to `lumber`
///     (`gpLumberHeldAtTurn99` gp2 = 45) rather than to `castIron`.
///
/// Conclusion: the supplier-extraction routing is now **structurally present,
/// unit-tested** (`full_ai_civilian_work_supplier_feedstock_extraction_test.dart`)
/// **and firing** (52 turns for gp1 / gp2), but the loop still does not reach
/// `castIron` production. The break has moved one stage downstream — the routed
/// Builder's `timber` / `iron` improvement does not convert into `castIron`
/// over-production, because (a) the `castIron` recipe needs **both** `timber`
/// **and** `iron` and the supplier extracts only the `timber` it routes to
/// `lumber`, and (b) the deliberately small `+5` over-production boost loses to
/// the supplier's shortage-driven `lumber` recipe for the extracted `timber`.
/// The next slice must pin, with a supplier-side `castIron` feedstock-holdings
/// counter, whether the supplier lacks an unimproved **`iron`** tile or whether
/// the over-production boost is simply out-competed for the extracted `timber`,
/// then either route the supplier onto an `iron` tile specifically or lift the
/// supplier `castIron` boost above the competing `lumber` shortage score under
/// the lock-recovery trigger. Verify by re-running this diagnostic and
/// confirming `gpCastIronProductionAssignedTurns` rises for gp1 / gp2.
///
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
