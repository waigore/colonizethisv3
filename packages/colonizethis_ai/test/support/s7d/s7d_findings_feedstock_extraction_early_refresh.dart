library;

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
