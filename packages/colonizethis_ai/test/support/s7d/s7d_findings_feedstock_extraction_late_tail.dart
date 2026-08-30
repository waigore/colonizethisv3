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
