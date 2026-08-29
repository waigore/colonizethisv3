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
