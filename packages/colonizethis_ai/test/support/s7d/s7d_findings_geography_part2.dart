/// Geography / peer-war lock S7-D findings (continued; Refs #4365 Slice B).

library;

///
/// ## Updated S7-T tuning surface (ordered by post-H4-a evidence)
///
/// Constraint per issue § Scope constraint stays unchanged:
/// **phase-planner logic only**, **no new config constants**,
/// **no value changes** to existing constants in
/// `packages/colonizethis_data/lib/src/ai_victory_config.dart`.
///
///   1. **H5 (new, highest signal): treasury-recovery cargo
///      futility under geographic peer-war lock.**
///      `boostTreasuryRecoveryCargo` is set on 91–97 turns per
///      failing GP but `gpTreasuryUnderCheapestRegimentTurns` /
///      treasury / `gpOwGain` show the boost never lifts the
///      regiment-build gate — the failing GPs hold **zero NW
///      provinces** and **zero NW invadables in EXPAND** (NW
///      acquisition is structurally suppressed in EXPAND) so the
///      cargo-preference signal targets an income path that the
///      GP cannot reach. The single highest-signal slice is to
///      detect the geographic peer-war lock + zero NW ownership +
///      EXPAND combination and either suppress the futile cargo
///      boost, route the economy-weight bonus toward a different
///      income arm (OW trade with neighbors, OW build queue,
///      forced cheapest-regiment build under a relaxed treasury
///      gate), or surface the dead-end as a deferred-survival
///      signal so a future SPEC slice can authorise an OW-only
///      trade-recovery arm. Phase-planner-only; no new constants.
///   2. **H3 (still open): `planExpandEconomy` Arm A semantics
///      under the lock.** Arm A's `regimentCount == 0` gate fires
///      only 3 turns per GP because the failing GPs **always have
///      ≥ 1 regiment** (the EXPAND-trap predicate
///      `isBelowQuotaPeaceInsufficientRegiments` was already
///      lifted to Arm B but Arm B requires `effectiveTreasury >=
///      cheapestRegimentBuildTreasuryCost`). Investigate widening
///      Arm A — `forceCheapestRegimentBuild: true` — to also fire
///      under geographic peer-war lock + below quota +
///      insufficient regiments **without** the affordable-treasury
///      gate, paired with H5. The build pipeline still applies
///      its own affordability check, so this is a directive change
///      not a budget change.
///   3. **H4-b [deferred]: stalled-expansion frontier-march
///      extension through peer-GP territory.** The +3 OW gate
///      cannot close while the failing GPs hold 1 regiment and
///      0 treasury — extending reach without fixing the offensive
///      strength gap would still leave combat outcomes
///      unfavourable. Re-evaluate after H5 / H3 lift the
///      regiment / treasury floor.
///   4. **H2 (still open): mutual-plateau peer-war exit lax.**
///      H4-a is the canonical fix here; the residual peer-war
///      re-declare oscillation (45-turn at-war count after H4-a)
///      remains and can be tuned in a follow-up declare-war
///      cooldown slice.
///
/// ## S7-D refresh (captured 2026-06-04 on merged `dev` @ `b4c79488`,
///     after the World Market treasury-recovery path (#2924 / #2994),
///     EXPAND universal colonial dispatch (#3179), and the stalled-EXPAND
///     minor-transit army-move routing (#3224) all merged)
///
/// The diagnostic surface has **shifted materially** — the dominant
/// EXPAND-lock blocker is **no longer treasury starvation**:
///
///   * **OW gain (+3 gate):** gp1=+6, gp2=+6 (PASS). gp3=+2, gp4=+1,
///     gp5=+1, gp6=+2 — all four still failing, but back in the low
///     +1/+2 band. #3224's minor-transit routing recovered gp5 from
///     the −7 zero-sum collapse seen in the 2026-06-03 on-branch run
///     to +1; the symmetric −7 / +10 winner/loser split no longer
///     appears on merged `dev`.
///   * **Treasury is solved.** The four failing GPs hold ~2029–2170
///     treasury at turn 99 (above `cheapestRegimentBuildTreasuryCost`
///     = 2000) and sit at-or-above the cheapest-regiment cost for
///     32–56 of 100 turns (vs 3 turns pre-World-Market). The old
///     H5 "treasury-recovery cargo futility" diagnosis no longer
///     holds — the World Market lifts treasury for the locked GPs.
///   * **New dominant bottleneck: regiment rebuilds are barely
///     emitted.** The new instrument fields (added in this slice)
///     isolate the proximate cause, and they **refute** the naive
///     "build one, lose it, rebuild every turn" churn hypothesis:
///     - `gpMilitaryBuildOrdersEmitted` = **2 / 4 / 2 / 2** for
///       gp3 / gp4 / gp5 / gp6 across the whole 100-turn run (gp1 / gp2
///       also only 2). So military `BuildUnitOrder`s are *rare* for
///       everyone — even though `forceCheapestRegimentBuild` fires
///       85–100 turns for the failing GPs and treasury is affordable
///       32–56 turns. The planner directive is **not** converting into
///       emitted build orders.
///     - `gpRegimentPeak` = **3** for every failing GP — they begin the
///       game with regiments rather than building up to a standing
///       army.
///     - `gpRegimentTurnsAtZero` = **39 / 1 / 59 / 59** for
///       gp3 / gp4 / gp5 / gp6. gp5 and gp6 spend the majority of the
///       run with **zero** regiments after their starting army is lost,
///       and almost never rebuild (2 emitted builds). gp4 is the
///       opposite case: it holds regiments nearly every turn (1 turn at
///       zero) yet still only gains +1 — for gp4 the blocker is reach /
///       offensive strength against the locked peer, not a missing
///       rebuild.
///   * **Two distinct failure modes** now separate cleanly:
///     (a) gp5 / gp6 (and partly gp3) — the `forceCheapestRegimentBuild`
///     directive does not reach the build pipeline as an emitted
///     military build, so the lost starting army is never replaced; and
///     (b) gp4 — regiments are present but cannot convert the
///     peer-locked invadable frontier into OW gains.
///
/// ## Updated S7-T tuning surface (ordered by 2026-06-04 evidence)
///
/// Constraint per issue § Scope constraint unchanged: **phase-planner
/// logic only**, **no new config constants**, **no value changes** to
/// existing constants in
/// `packages/colonizethis_data/lib/src/ai_victory_config.dart`.
///
///   1. **H8 (new, highest signal): regiment-rebuild directive →
///      emitted build conversion gap.** The 2026-06-04 instrument shows
///      `forceCheapestRegimentBuild` fires 85–100 turns for the failing
///      GPs while `gpMilitaryBuildOrdersEmitted` is only 2–4 and
///      `gpRegimentTurnsAtZero` is 39–59 for gp3 / gp5 / gp6. The
///      directive is set but the build pipeline rarely emits the
///      cheapest-regiment `BuildUnitOrder`, so the lost starting army is
///      never replaced. The highest-signal slice is to find why
///      `forceCheapestRegimentBuild` does not produce an emitted
///      military build under the lock with treasury available (e.g.
///      spawn-province eligibility, production-assignment routing, or a
///      build-pick gate) — phase-planner / orchestrator scope, no new
///      constants. Verify any fix by re-running this diagnostic and
///      confirming `gpMilitaryBuildOrdersEmitted` rises and
///      `gpRegimentTurnsAtZero` falls for gp5 / gp6.
///   2. **H4-b (unblocked for the regiment-holding case): minor-transit
///      reach.** gp4 holds regiments almost every turn (1 turn at zero)
///      yet still gains only +1 — its blocker is reach / offensive
///      strength against the locked peer. #3224 routes locked-GP army
///      moves toward at-war minor / tribe OW provinces through the
///      peer's territory and recovered gp5; extending the same routing
///      to gp4 (which #3224 left unchanged) is the natural follow-up for
///      the regiment-holding failure mode.
///   3. **H2 (still open): residual peer-war re-declare oscillation.**
///
/// ## S7-D refresh (captured 2026-06-04 on merged `dev` @ `82984a23`,
///     after the EXPAND regiment-rebuild production boost (#3229) and the
///     lock-recovery seller build-input bid carve-out (#3226) merged —
///     H8 conversion-gap instrumentation added in this slice)
///
/// New per-GP fields isolate the H8 directive → emitted-build gap into its
/// proximate sub-cause. A turn counts as **rebuild-ready** when
/// `forceCheapestRegimentBuild` is set, treasury affords the cheapest
/// regiment (`peasant_levies`, one `fabric`), and the GP holds zero
/// regiments — exactly when the lost starting army should be replaced.
///
///   * **The gap is 100% an input-acquisition problem, not a downstream
///     build/suggestion gate.** `gpRebuildReadyNoBuildInputsPresentTurns`
///     is **0** for every GP, while `gpRebuildReadyNoBuildMissingInputTurns`
///     equals the entire `gpRebuildReadyNoBuildTurns` count: gp3 = 29,
///     gp5 = 52, gp6 = 51. On **every** rebuild-ready turn that emits no
///     military build, the cheapest-regiment input (fabric) is simply not
///     in the stockpile. This exonerates spawn-province eligibility, the
///     `pickBuildOrder` regiments-only filter, and the build-pass
///     threshold — they never get a candidate to reject.
///   * **Fabric is absent essentially the whole game for the failing GPs.**
///     `gpCheapestRegimentInputsInStockpileTurns` = 2 / 2 / 2 for
///     gp3 / gp5 / gp6 (vs gp4 = 61, the one failing GP that holds
///     regiments and emits the most builds, 4). The failing GPs cannot
///     produce fabric (no wool / cotton feedstock reaches the fabric
///     recipe) for ~98 of 100 turns.
///   * **The #3226 build-input bid is placed but the market never supplies
///     fabric.** `isLockRecoverySeller` is true for gp3 / gp5 / gp6
///     (OW >= 2, below quota, zero NW), so the treasury-planner build-input
///     bid carve-out injects a fabric bid: `gpRegimentInputBidsEmitted` =
///     1 / 1 / 1 (a single *fresh* emission per GP — on later turns the
///     unfilled bid persists as a carry-forward, so the carve-out's
///     `held < input.value` guard correctly suppresses a duplicate). The
///     decisive number is `gpRegimentInputDealsAsBuyer` = **0** for every
///     GP across all 100 turns: the fabric bid never matches a deal because
///     no GP / tribe sells fabric into the world market. The bottleneck has
///     moved off the planner entirely and onto **fabric supply** — the
///     failing GPs can neither produce fabric (no feedstock) nor buy it
///     (no seller).
///
/// ## Updated S7-T tuning surface (ordered by the conversion-gap split)
///
/// Constraint per issue § Scope constraint unchanged: **phase-planner
/// logic only**, **no new config constants**, **no value changes** to
/// existing constants in
/// `packages/colonizethis_data/lib/src/ai_victory_config.dart`.
///
///   1. **H8-supply (new, highest signal): fabric supply for the
///      zero-regiment lock-recovery sellers.** The directive, treasury,
///      build-pass threshold, regiments-only filter, and build-input bid
///      mechanism are all working; the missing piece is fabric **supply**.
///      The next slice must either (a) make the failing GPs *produce*
///      fabric — ensure the regiment build-input production boost also
///      pulls the transitive wool / cotton feedstock so a fabric recipe
///      becomes feasible — or (b) create world-market fabric **sellers**
///      (e.g. a fabric-surplus GP offers down) so the existing #3226 bid
///      can fill. Verify by re-running this diagnostic and confirming
///      `gpCheapestRegimentInputsInStockpileTurns`,
///      `gpMilitaryBuildOrdersEmitted`, and (downstream)
///      `gpRegimentTurnsAtZero` all improve for gp5 / gp6.
///   2. **H4-b (unblocked for the regiment-holding case): minor-transit
///      reach.** gp4 holds regiments almost every turn yet still gains
///      only +1 — its blocker is reach / offensive strength against the
///      locked peer (see #3224).
///   3. **H2 (still open): residual peer-war re-declare oscillation.**
///
