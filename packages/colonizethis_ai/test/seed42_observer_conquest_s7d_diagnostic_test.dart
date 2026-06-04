import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show kTreasuryOfferPriorityUrgent;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        allUnitsFromWorld,
        regimentBuildInputFeedstockExtractionResourceIds,
        supplierImprovementInputFeedstockExtractionResourceIds;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';

/// Seed-42 turn-100 EXPAND-arm S7-D diagnostic (Refs #2847).
///
/// Per the issue's S7-D subtask, this test runs the 100-turn seed-42
/// scenario (matching `seed42_observer_conquest_regression_test`) and
/// records, **per GP per turn**:
///
///   * `observerGoalPhaseFor` phase classification (EXPAND /
///     COLONIAL-lite / COLONIAL / DEVELOP).
///   * `planExpandDeclareWar` target (or `null` — none of the priority
///     arms qualified this turn).
///   * `planExpandPeace` peace-target set.
///   * `planExpandEconomy` arm flags (forceCheapestRegimentBuild /
///     boostTreasuryRecoveryCargo).
///   * Key snapshot fields gating the EXPAND arms: invadable OW count,
///     adjacent owner set, at-war set, treasury, regimentCount,
///     OW provinces owned.
///
/// The aggregated per-GP rollup (phase distribution, declare-war target
/// distribution, peace-target distribution, OW gain) is printed to
/// stdout for inclusion in the S7-D diagnostic note posted to the
/// issue / PR description. The test asserts only that diagnostic data
/// was collected (per-GP phase count totals match turn count) — it
/// does **not** pin any arm-fire counts so the diagnostic surface can
/// move freely as the planner is tuned in subsequent slices.
///
/// The run uses a faithful Full-AI handoff (every player `isHuman: false`,
/// every GP AI-controlled) so the diplomacy intervention resolver
/// auto-resolves AI interventions instead of pausing with
/// `TurnResolutionPendingIntervention` (which only arises for human players).
/// Without this, gp1 (init default `isHuman: i == 0`) pauses the run the
/// moment it becomes intervention-eligible, and the Step-0 lock-recovery
/// metrics no longer reflect faithful full-AI observer semantics (Refs
/// #2924, matching `seed42_observer_world_market_lock_recovery_regression_test`).
///
/// ## S7-D findings (captured 2026-05-26)
///
/// First run on `dev` @ `e6b4fff225` produced the per-GP rollup pasted
/// into the issue's S7-D diagnostic note. Headline observations:
///
///   * **gp1 / gp2 PASS** the +3 OW gate (+6 each). gp2's previously
///     unconfirmed status is therefore **PASS** — the failing set is
///     exactly `gp3, gp4, gp5, gp6` as the original skip message said.
///   * **gp3, gp4, gp5 stay in EXPAND for all 100 turns** (gp6 reaches
///     COLONIAL only at turn 94+). They never satisfy
///     `kObserverConquestMinOwProvincesPerGp` (OW ≥ 10).
///   * **`planExpandDeclareWar` returns `null` 93–98% of the time** for
///     every GP. The treasury floor on arms 1 and 3 (≥
///     `cheapestRegimentBuildTreasuryCost` = 2000) is the dominant
///     skip clause: every GP spends 97 of 100 turns with `treasury <
///     2000`.
///   * **`boostTreasuryRecoveryCargo` fires 91–97 turns per GP** for
///     `gp3..gp6` (vs 2–4 for `gp1`/`gp2`). The failing GPs are
///     chronically below the cheapest regiment cost.
///   * **gp3 ↔ gp4 stay at war 53 turns; gp5 ↔ gp6 stay at war 45
///     turns.** Both pairs are mutual-plateau peers locked in below-
///     quota GP wars; `planExpandPeace` picks the peer ~44–45% of
///     turns but the war never permanently closes.
///   * **Targets exist for the failing GPs** — turn-99 snapshot shows
///     gp3/gp4/gp5/gp6 with 6–8 invadable OW provinces each, yet only
///     1–2 regiments and treasury 0–50.
///   * **Geographic peer-war lock (turn-99 snapshot, all four failing
///     GPs)** — `adjacentOwnerFactionIdsSorted` collapses to a single
///     entry per GP: `gp4` for gp3, `gp3` for gp4, `gp6` for gp5,
///     `gp5` for gp6. Every invadable OW province is owned by that
///     peer; the at-war minors in `ThreatSummary.atWarWith` are not
///     adjacent and therefore never reach the `atWarMinors` set
///     inside `planExpandDeclareWar`. This is the proximate cause
///     of the arm-2 underfire — refutes H1 and elevates the new
///     hypothesis H4 below.
///
/// ## S7-T tuning surface (issue § S7-T hypotheses, ordered by S7-D
///     evidence)
///
/// **H1 refuted** (re-run 2026-05-26, captured in
/// `expand_phase_planner_declare_war_test.dart` ›
/// `Refs #2847 S7-D H1 refutation` pin). The turn-99 snapshot for
/// every failing GP shows `adjacentOwnerFactionIdsSorted` containing
/// **only the at-war peer GP** (gp4 for gp3, gp3 for gp4, gp6 for gp5,
/// gp5 for gp6). Because `ConquestSummary.invadableProvinceIdsSorted`
/// is a P–P neighbor scan, **no at-war minor owns any invadable
/// province by mid-late game** for the failing GPs — they are
/// geographically surrounded by their peer GP and cut off from the
/// minor frontier. Arm 2 therefore has zero candidates structurally,
/// not because of a candidate-filtering bug. Tuning the `atWarMinors`
/// set construction or the `adjacentOwners` cross-check will not
/// produce arm-2 fires the planner is currently missing because the
/// inputs already correctly exclude non-adjacent minors. The 3 arm-2
/// fires gp3 does emit (`minor1` ×3) occur in earlier turns when the
/// geography still routes through a minor.
///
///   * **H1 [refuted]: planExpandDeclareWar arm-2 candidate filtering.**
///     Spec gives no arm for at-war minors that own no invadable
///     province. The proximate cause for the missing arm-2 fires is
///     **upstream of the planner** — the geographic peer-war lock
///     (see H4) keeps the at-war minor owners outside the invadable
///     set in the first place.
///   * **H2: mutual-plateau peer-war exit is too lax for the gp3↔gp4
///     and gp5↔gp6 pairs.** Both pairs spend ~45 turns at war with
///     each other while invadable minor targets remain on the wider
///     map (just not reachable from the failing GP's own anchors).
///     The `belowQuotaPeerGpPeaceTargets` /
///     `mutualExhaustedBelowQuotaGpStalematePeaceTargets` deciders
///     fire ~44% of turns but the war reopens. Investigate whether
///     the declare-war path re-opens the war the same turn peace is
///     offered, or whether a later EXPAND decider override is
///     keeping the peer war live.
///   * **H3: economy rebuild arm A flag does not translate to
///     regiment builds.** `forceCheapestRegimentBuild` fires only 3
///     turns per GP across the entire 100-turn run (every GP),
///     including `gp3..gp6` who spend ≥91 turns flagged for cargo
///     boost. Investigate why arm A's `regimentCount == 0` gate
///     rarely triggers despite the failing GPs holding 1–2
///     regiments — does the build pipeline cap arm A to once-per-
///     drop-to-zero, or is the arm gate semantically wrong for the
///     "1–2 regiments stuck" case?
///   * **H4 [highest signal]: geographic peer-war lock starves
///     the failing GPs of reachable conquest targets.** For each of
///     the four failing GPs, `adjacentOwnerFactionIdsSorted` collapses
///     to a single at-war peer GP by mid-game, every invadable OW
///     province is owned by that peer, and the
///     `kStalledMinRegimentCountWhenGpBlockerAtWar` (22) plus
///     province-deficit scaling pushes the `minRegimentFloor`
///     above 22 while the GP has 1–2 regiments and treasury 0–50.
///     `boostTreasuryRecoveryCargo` fires 91–97 turns per failing
///     GP but treasury never climbs to `cheapestRegimentBuildTreasuryCost`
///     (2000). The peer war cannot be broken via declare-war
///     (already at war), army-move (insufficient regiments), or
///     peace (45-turn mutual offer + war reopens). Two follow-up
///     tuning surfaces remain:
///
///     **H4-a [implemented]:** widen the `planExpandPeace` carve-out
///     so peace fires on every at-war turn when adjacency collapses
///     to a single at-war peer GP, regardless of whether uninvaded
///     OW minors remain elsewhere on the map. Landed in this PR via
///     the new [expandIsGeographicPeerWarLock] helper and a parallel
///     carve-out arm inside [planExpandPeace]; SPEC update at
///     `SPEC/ai/ai-architecture.md` § EXPAND and
///     `SPEC/ai/phase-planner-architecture.md` AC list (Refs #2847
///     § H4-a). Lifts the peace-fire ratio from ~45 / 53 at-war
///     turns toward 53 / 53 in the seed-42 gp3↔gp4 and gp5↔gp6
///     locks; a refreshed S7-D run after this lands should show
///     the gain.
///
///     **H4-b [deferred — refresh evidence below]:** extend the
///     stalled-expansion own-territory frontier-march in
///     `runConquestArmyMovePlanner` (`SPEC/ai/phase-planner-architecture.md`
///     § Acceptance criteria #2) to at-war minor / tribe owned OW
///     provinces reachable *through* the at-war peer GP's
///     territory. The post-H4-a refresh below shows the failing
///     GPs hold **1 regiment + 0 treasury** at turn 99 — a
///     longer reach without offensive strength would not close
///     the gate. This is now deferred behind H5 / H3 below.
///
/// ## S7-D refresh (captured 2026-05-26 against `feat/issue-2847-s7d-diagnostic`
///     with the H4-a peace-widening slice in place)
///
/// Re-running the diagnostic with the H4-a `planExpandPeace`
/// carve-out landed (commit `0f1f0a7295`) reveals that **H4-a
/// alone does not close the +3 OW gate**. Headline numbers:
///
///   * **OW gain (+3 gate):** gp3=+2, gp4=+1, gp5=+1, gp6=+2
///     (all still failing — same band as the original baseline).
///     gp1=+6, gp2=+2 (unchanged passes).
///   * **Phase distribution unchanged:** gp3 / gp4 / gp5 stay in
///     EXPAND for all 100 turns; gp6 reaches COLONIAL only at
///     turn 94+ (94 expand / 6 colonial). H4-a does not unlock
///     the EXPAND → COLONIAL transition for the failing GPs.
///   * **Peer-war at-war turn count drops modestly:**
///     gp3↔gp4 stays at war 45 / 100 (down from 53 / 100 in the
///     pre-H4-a baseline — the peace fires every turn now via
///     the carve-out, but the war is **re-declared** by the peer
///     a few turns later because both sides still satisfy the
///     same EXPAND declare-war priority arms). gp5↔gp6 stays at
///     war 45 / 100 (already at 45 in baseline, no movement).
///   * **Economy bottleneck dominates:** every failing GP holds
///     **1 regiment + 0 treasury** at turn 99 with
///     `cheapestRegimentBuildTreasuryCost = 2000`.
///     `boostTreasuryRecoveryCargo` fires 91–97 turns per failing
///     GP but treasury never crosses 2000 because the failing GPs
///     hold zero NW provinces and have no overseas riches to
///     deliver — `boostTreasuryRecoveryCargo` boosts cargo
///     preference for an income path that does not exist.
///     `forceCheapestRegimentBuild` fires only **3 turns** per GP
///     (Arm A's `regimentCount == 0` gate; Arm B requires
///     `effectiveTreasury >= 2000` which never happens).
///   * **Geographic peer-war lock unchanged at turn 99:**
///     `adjacentOwnerFactionIdsSorted` still collapses to a single
///     at-war (or recently-at-war) peer per failing GP — gp4 for
///     gp3, gp3 for gp4, gp6 for gp5, gp5 for gp6 — and the
///     invadable OW set (5–8 provinces per GP) is owned entirely
///     by that peer.
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
/// ## How to refresh
///
/// Skipped by default (long-running, ~4 minutes on the project
/// reference host). Run manually with:
///
/// ```
/// (cd packages/colonizethis_ai && dart test \
///     test/seed42_observer_conquest_s7d_diagnostic_test.dart \
///     --run-skipped)
/// ```
///
/// and copy the `S7D_DIAGNOSTIC_JSON_*`-delimited block into a fresh
/// comment on issue #2847 if the diagnostic surface shifts after a
/// tuning slice lands.
///
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
/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) and is still unimproved
/// (improvement level < 1) — i.e. a Builder target a lock-recovery seller could
/// extract to feed the `fabricFrom*` recipes. Read-only scan over owned
/// provinces; Refs #2847 H8-supply feedstock-stage diagnostic.
bool _ownsUnimprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = tryGetProvince(ws, entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId == null || !feedstockIds.contains(resourceId)) {
          continue;
        }
        if (ws.tileState.improvementLevel(tileKey) < 1) return true;
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one province tile that hosts a fabric
/// feedstock resource (a member of [feedstockIds]) that is already improved
/// (improvement level >= 1) — i.e. a Builder has finished extracting the tile.
///
/// Companion to [_ownsUnimprovedFeedstockResourceTile] for the H8-extraction
/// execution-gap disambiguation (Refs #2847). When the feedstock-extraction
/// gate is active and an unimproved feedstock tile is owned all run, a near-zero
/// improved-tile count localizes the break to the routing / Builder-availability
/// stage (the Builder never finishes the improvement), whereas a high
/// improved-tile count alongside a near-zero `gpFeedstockInStockpileTurns`
/// localizes it to the extraction / transport-connectivity stage (the improved
/// tile yields no commodity into the stockpile because it is not extraction-
/// connected). Read-only scan over owned provinces.
bool _ownsImprovedFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final byProvince in ws.tileKeysByRegionAndProvince.values) {
    for (final entry in byProvince.entries) {
      final province = tryGetProvince(ws, entry.key);
      if (province == null || province.ownerId != playerId) continue;
      for (final tileKey in entry.value) {
        final resourceId = ws.resourceByTileKey[tileKey];
        if (resourceId == null || !feedstockIds.contains(resourceId)) {
          continue;
        }
        if (ws.tileState.improvementLevel(tileKey) >= 1) return true;
      }
    }
  }
  return false;
}

/// True iff [playerId] owns at least one Builder unit that currently has no
/// work assigned (`currentWork == null`) — i.e. a Builder the Full-AI civilian
/// work selection could route onto a feedstock tile this turn.
///
/// Used by the H8-extraction execution-gap disambiguation (Refs #2847): a
/// near-zero count on feedstock-gate-active turns localizes the break to
/// Builder availability (no free Builder to route), distinguishing it from the
/// "Builder present but improvement never completes / extracts" cases. Read-only
/// scan over all world units.
bool _hasIdleBuilderUnit(Game game, String playerId) {
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork == null) return true;
  }
  return false;
}

/// True iff [playerId]'s stockpile can afford the level-0 `build_improvement`
/// material cost (the cost to raise an unimproved tile to level 1 — 1 lumber +
/// 1 cast iron, `work_order_costs.dart` § `workOrderCostBuildImprovement`).
///
/// The Full-AI civilian work-order validator rejects any `build_improvement`
/// candidate whose material cost the stockpile cannot cover
/// (`work_order_validator.dart` § `_validateWorkMaterialCosts`) **before** the
/// selection score boost (#3234) can bias it. A near-zero count on
/// feedstock-extraction-gate-active turns therefore localizes the
/// missing-candidate break to improvement affordability (the lumber /
/// cast-iron deadlock) rather than tile control, visibility, or occupancy.
/// Read-only over the player's stockpile; Refs #2847 H8-extraction.
bool _affordsBuildImprovementLevelZero(Game game, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) return false;
  final cost = workOrderCostBuildImprovement(0);
  for (final entry in cost.entries) {
    if (player.stockpile.quantityOf(entry.key) < entry.value) return false;
  }
  return true;
}

/// True iff [playerId] owns at least one idle Builder for which the work-order
/// engine **accepts** a `build_improvement` on an owned unimproved feedstock
/// tile (a member of [feedstockIds]) — i.e. `getValidWorkOrderTileKeys` (the
/// same validator chain `suggestWorkOrders` runs) actually emits a candidate
/// the Full-AI civilian selection could route the Builder onto this turn.
///
/// This is the decisive split for the H8-extraction missing-candidate
/// hypothesis (Refs #2847): with an idle Builder present
/// (`gpFeedstockGateIdleBuilderPresentTurns` == gate-active turns) and an
/// unimproved feedstock tile owned (`gpUnimprovedFeedstockTileOwnedTurns` ==
/// 100) yet `gpFeedstockGateImprovedTileOwnedTurns` == 0, a near-zero count
/// here confirms the work-order validator suppresses the candidate before any
/// selection boost applies (the #3234 boost only biases a candidate that
/// exists); a high count would instead re-point the break downstream to the
/// selection / orchestrator / phase-filter stage. Read-only —
/// `getValidWorkOrderTileKeys` does not mutate game state.
bool _hasValidBuildImprovementOnUnimprovedFeedstockTile(
  Game game,
  MapTopology topology,
  String playerId,
  Set<String> feedstockIds, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork != null) continue;
    final valid = getValidWorkOrderTileKeys(
      game,
      topology,
      playerId,
      unit.id,
      kWorkTargetBuildImprovement,
      const Orders(),
      tileMapByRegion: tileMapByRegion,
    );
    for (final tileKey in valid) {
      final resourceId = ws.resourceByTileKey[tileKey];
      if (resourceId == null || !feedstockIds.contains(resourceId)) continue;
      if (ws.tileState.improvementLevel(tileKey) < 1) return true;
    }
  }
  return false;
}

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 S7-D diagnostic: per-GP EXPAND arm decision trace',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = applyFaithfulFullAiTestHandoff(init.game);
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final gpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];
      final owStart = <String, int>{
        for (final gpId in gpIds)
          gpId: game.worldState.oldWorld.provinces
              .where((p) => p.ownerId == gpId)
              .length,
      };

      // Per-GP rollups; populated as the simulation advances.
      final phaseCounts = <String, Map<ObserverGoalPhase, int>>{
        for (final gpId in gpIds)
          gpId: <ObserverGoalPhase, int>{
            for (final ph in ObserverGoalPhase.values) ph: 0,
          },
      };
      final declareWarPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final peaceTargetPicks = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final economyArmCounts = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{
            'forceCheapestRegimentBuild': 0,
            'boostTreasuryRecoveryCargo': 0,
          },
      };
      final invadableEmptyTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final atWarTurnsByPeer = <String, Map<String, int>>{
        for (final gpId in gpIds) gpId: <String, int>{},
      };
      final treasuryUnderCheapestTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final lastSnapshotFields = <String, Map<String, Object?>>{};

      // Refs #2847 regiment-accumulation surface (post-#2924 / World
      // Market merge). Treasury starvation is no longer the dominant
      // EXPAND-lock blocker for the failing GPs; the new question is
      // whether the standing regiment count actually grows once the GP
      // can afford a build. These per-GP rollups capture the regiment
      // trajectory (peak / turns at zero / turns at-or-above the cheapest
      // build cost) and the number of military `BuildUnitOrder`s the AI
      // actually emits each turn, so a future tuning implementer can tell
      // apart "the build order is never emitted/accepted" from "regiments
      // are built but immediately lost in the peer-war zero-sum churn".
      final regimentPeak = <String, int>{for (final gpId in gpIds) gpId: 0};
      final regimentTurnsAtZero = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final treasuryAtOrAboveCheapestTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final militaryBuildOrdersEmitted = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };

      // Refs #2847 H8 conversion-gap isolation. The headline H8 finding is
      // that `forceCheapestRegimentBuild` fires 85-100 turns while
      // `gpMilitaryBuildOrdersEmitted` stays at 2-4 and `gpRegimentTurnsAtZero`
      // is 39-59 for gp3 / gp5 / gp6. These accumulators split the gap into
      // its proximate sub-causes so a tuning implementer can tell apart
      // "the cheapest-regiment input (fabric) is never in the stockpile when
      // the GP is ready to build" (production / market-acquisition gap) from
      // "fabric is present and the GP is ready, yet no military build is
      // emitted" (a downstream suggestion / build-pick gate). A turn counts
      // as *rebuild-ready* when the EXPAND directive is active, treasury can
      // afford the cheapest regiment, and the GP holds zero regiments — the
      // exact condition under which the lost starting army should be
      // replaced. The cheapest regiment (`peasant_levies`) requires a single
      // unit of fabric, so fabric availability is the proximate input gate.
      final cheapestRegimentInputs =
          RegimentEconomyCatalog.peasantLevies.buildInputs;
      final fabricInStockpileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final rebuildReadyTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final rebuildReadyNoBuildTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final rebuildReadyNoBuildMissingInputTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final rebuildReadyNoBuildInputsPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Cheapest-regiment input commodity ids (e.g. fabric) and the bid /
      // fill counters that prove whether the #3226 lock-recovery build-input
      // bid carve-out actually secures the input from the world market. A
      // high bid count with a near-zero fill count localizes the gap to
      // world-market *supply* (no seller / no production feedstock) rather
      // than the planner failing to bid.
      final regimentInputCommodityIds = cheapestRegimentInputs.keys.toSet();
      final regimentInputBidsEmitted = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final regimentInputDealsAsBuyer = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };

      // Refs #2847 H8-extraction supply-side localization. The level-0
      // `build_improvement` material (lumber + cast iron) is the prerequisite a
      // locked seller's routed Builder needs but cannot afford
      // (`gpFeedstockGateImprovementCostAffordableTurns == 0`). The
      // improvement-input bid carve-out and the treasury-independent supplier
      // release set both target these commodities, yet the seller never ends up
      // holding them. These counters split that supply gap into its proximate
      // links so a tuning implementer can tell apart, in order: (a) no GP / tribe
      // *offers* the inputs at all (`gpImprovementInputOffersEmitted` flat zero =>
      // nobody holds a releasable surplus); (b) offers exist but the seller's bid
      // never *fills* (`gpImprovementInputDealsAsBuyer` flat zero alongside
      // non-zero offers => price / priority / bid-cap matching gap); or (c) deals
      // fill but the input is consumed before the gate observes it
      // (`gpImprovementInputHeldAtTurn99` zero alongside non-zero buyer deals).
      // Read-only; the (freely tunable) counts can move as later supply slices
      // land.
      final improvementInputCommodityIds = workOrderCostBuildImprovement(
        0,
      ).keys.toSet();
      final improvementInputOffersEmitted = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final improvementInputBidsEmitted = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final improvementInputDealsAsBuyer = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final improvementInputHeldAtTurn99 = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };

      // Refs #2847 H8-extraction castIron residual localization (post-#3241).
      // The level-0 `build_improvement` material is `lumber + castIron`. #3241
      // makes a lock-recovery seller buy `lumber` directly and produce
      // `castIron` domestically from its production feedstock (timber + iron).
      // The affordability gate
      // (`gpFeedstockGateImprovementCostAffordableTurns`) requires BOTH inputs
      // on hand simultaneously, yet it stays flat zero. These read-only
      // counters split the castIron sub-chain so the next slice can target the
      // exact stage, in order:
      //   (a) the seller bids castIron's production feedstock at all
      //       (`gpCastIronFeedstockBidsEmitted`);
      //   (b) that feedstock is even *offered* on the world market
      //       (`gpCastIronFeedstockOffersEmitted` flat zero => no releasable
      //       supply — `timber` / `iron` are absent from the supplier release
      //       set, so the affluent GPs never offer them);
      //   (c) the bids *fill* (`gpCastIronFeedstockDealsAsBuyer`);
      //   (d) the economy planner ever runs the castIron recipe
      //       (`gpCastIronProductionAssignedTurns`); and
      //   (e) the resulting per-commodity holdings at turn 99
      //       (`gpLumberHeldAtTurn99` / `gpCastIronHeldAtTurn99`) — a non-zero
      //       lumber with zero castIron confirms the production-feedstock break.
      // Pure observation — no production logic changes — so the (freely
      // tunable) counts can move as later supply slices land.
      final castIronRecipes =
          <ProductionRecipe>[
            for (final recipe in ProductionRecipesCatalog.all)
              if (recipe.outputCommodityId == 'castIron') recipe,
          ]..sort((a, b) => a.id.compareTo(b.id));
      final castIronProductionRecipe = castIronRecipes.isEmpty
          ? null
          : castIronRecipes.first;
      final castIronFeedstockIds = <String>{
        ...?castIronProductionRecipe?.inputQuantities.keys,
      };
      final castIronRecipeIds = <String>{
        for (final recipe in castIronRecipes) recipe.id,
      };
      final castIronFeedstockBidsEmitted = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronFeedstockOffersEmitted = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronFeedstockDealsAsBuyer = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronProductionAssignedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final lumberHeldAtTurn99 = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronHeldAtTurn99 = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8-extraction supplier feedstock: per-GP count of turns the
      // supplier-side castIron feedstock extraction gate is active
      // (`supplierImprovementInputFeedstockExtractionResourceIds` non-empty) —
      // i.e. the GP is a non-seller above the quota, a peer locked seller needs
      // the producible `castIron` improvement input, and the GP owns an
      // unimproved `timber` / `iron` tile to extract. A non-zero count for the
      // supplier GPs (gp1 / gp2) paired with a rising
      // `gpCastIronProductionAssignedTurns` confirms the supplier-extraction
      // slice closes the over-production feedstock gap; a flat-zero count for
      // gp1 / gp2 re-points the next slice (the suppliers own no unimproved
      // `timber` / `iron` tile to extract). Read-only; freely tunable.
      final supplierFeedstockExtractionGateActiveTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8-extraction castIron co-availability localization
      // (post-#3247). #3247 reserves the multi-input `castIron` feedstock
      // (`timber` + `iron`) from competing single-input recipes so the
      // feedstock can co-accumulate for one run, yet
      // `gpCastIronProductionAssignedTurns` stays 0 for every GP and the
      // affluent supplier gp2 still converts its extracted `timber` to
      // `lumber`. The reservation cannot help if the supplier never has the
      // *other* feedstock (`iron`) to reserve in the first place. These two
      // counters decide the next slice's direction per feedstock commodity:
      //
      //   * `supplierActiveUnimprovedCastIronFeedstockTileTurns` — while the
      //     supplier feedstock-extraction gate is active, per-commodity count
      //     of turns the GP owns an *unimproved* tile of that castIron
      //     feedstock (a Builder target it could extract). A flat zero for
      //     `iron` on the supplier GPs (gp1 / gp2) means domestic `castIron`
      //     production is structurally impossible (no `iron` tile to extract),
      //     re-pointing the next slice to a market / requirement-relaxation
      //     path; a non-zero `iron` count means the Builder routing simply is
      //     not selecting the `iron` tile, re-pointing to a routing fix.
      //   * `castIronFeedstockHeldAtTurn99` — per-commodity feedstock stock at
      //     turn 99. Confirms which feedstock the supplier actually accumulates
      //     (`timber`) versus never holds (`iron`).
      //
      // Read-only scans; freely tunable diagnostic surface.
      final supplierActiveUnimprovedCastIronFeedstockTileTurns =
          <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{for (final id in castIronFeedstockIds) id: 0},
      };
      final castIronFeedstockHeldAtTurn99 = <String, Map<String, int>>{
        for (final gpId in gpIds)
          gpId: <String, int>{for (final id in castIronFeedstockIds) id: 0},
      };

      // Refs #2847 H8-supply: domestic-production feedstock-stage isolation.
      // The post-#3235 surface shows the world market never supplies fabric
      // (`gpRegimentInputDealsAsBuyer == 0`) and the affluent-supplier release
      // path cannot help (the conquest GPs that might hold textile surplus sit
      // far below the regiment-affluence treasury band), so the only viable
      // fabric source for a locked seller is *domestic production* of the
      // wool / cotton feedstock the `fabricFrom*` recipes consume. These
      // read-only accumulators split that chain into its proximate links so a
      // tuning implementer can tell apart, in order:
      //   1. no Builder routing window — the feedstock-extraction gate
      //      ([regimentBuildInputFeedstockExtractionResourceIds]) never fires;
      //   2. no feedstock tile to improve — the GP owns no unimproved
      //      wool / cotton resource tile a Builder could extract;
      //   3. feedstock never reaches the stockpile — no wool / cotton on hand
      //      despite the gate / tile;
      //   4. feedstock present but not enough for a recipe run — no fabric
      //      recipe is feasible for >=1 run;
      // measured against the existing `gpCheapestRegimentInputsInStockpileTurns`
      // (fabric on hand) so the break point is unambiguous. Pure observation —
      // no production logic changes — so the (freely tunable) counts can move
      // as later supply slices land.
      final fabricRecipes = <ProductionRecipe>[
        for (final recipe in ProductionRecipesCatalog.all)
          if (cheapestRegimentInputs.containsKey(recipe.outputCommodityId))
            recipe,
      ];
      final fabricFeedstockIds = <String>{
        for (final recipe in fabricRecipes) ...recipe.inputQuantities.keys,
      };
      final feedstockExtractionGateActiveTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final unimprovedFeedstockTileOwnedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockInStockpileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final fabricRecipeFeasibleTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8-extraction execution-gap disambiguation (read-only).
      // Both are gated on a feedstock-extraction-gate-active turn so they split
      // the 29-52 gate-active turns into the proximate failure stage:
      //   * `feedstockGateIdleBuilderPresentTurns` — a free Builder exists to
      //     route (rules out "no Builder available");
      //   * `feedstockGateImprovedTileOwnedTurns` — the routed Builder has
      //     actually finished improving a feedstock tile. Near-zero here with
      //     an idle Builder present and `gpUnimprovedFeedstockTileOwnedTurns`
      //     high => the improvement never completes (routing / preemption);
      //     high here with `gpFeedstockInStockpileTurns` near-zero => the
      //     improved tile is not extraction-connected (transport-cap stage).
      final feedstockGateIdleBuilderPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockGateImprovedTileOwnedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8-extraction missing-candidate disambiguation (read-only).
      // Both are gated on a feedstock-extraction-gate-active turn and split the
      // "idle Builder present + unimproved feedstock tile owned, yet improvement
      // never completes" gap into its proximate cause:
      //   * `feedstockGateValidBuildImprovementCandidateTurns` — the work-order
      //     engine (`getValidWorkOrderTileKeys`, the same validator chain
      //     `suggestWorkOrders` runs) actually accepts a `build_improvement`
      //     candidate for an idle Builder on an owned unimproved feedstock tile.
      //     Near-zero here confirms the candidate is suppressed by the validator
      //     before any selection boost (#3234) applies; high here re-points the
      //     break downstream to selection / orchestrator / phase filtering.
      //   * `feedstockGateImprovementCostAffordableTurns` — the GP's stockpile
      //     can afford the level-0 `build_improvement` cost (1 lumber + 1 cast
      //     iron). Near-zero alongside a near-zero candidate count localizes the
      //     suppression to the validator material-cost gate (the lumber /
      //     cast-iron deadlock); high alongside a near-zero candidate count
      //     points instead at tile control / visibility / occupancy gates.
      final feedstockGateValidBuildImprovementCandidateTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockGateImprovementCostAffordableTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };

      // Refs #2924 Step 0 — world-market lock-recovery diagnostics:
      // per-GP rollups capturing (a) trade orders the AI submits each
      // turn (offer/bid counts plus urgent-priority offer counts at
      // [kTreasuryOfferPriorityUrgent]), (b) deals matched in the
      // world-market phase counted by seller/buyer GP plus treasury
      // credited/debited per side, and (c) whether/when the post-turn
      // treasury crosses [cheapestRegimentBuildTreasuryCost]. These
      // surfaces are issue-2924 specific and live alongside the
      // existing #2847 S7-D fields so a single run produces both
      // diagnostic blocks.
      final tradeOfferCount = <String, int>{for (final gpId in gpIds) gpId: 0};
      final tradeUrgentOfferCount = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final tradeBidCount = <String, int>{for (final gpId in gpIds) gpId: 0};
      final dealsAsSeller = <String, int>{for (final gpId in gpIds) gpId: 0};
      final dealsAsBuyer = <String, int>{for (final gpId in gpIds) gpId: 0};
      final treasuryCredited = <String, int>{for (final gpId in gpIds) gpId: 0};
      final treasuryDebited = <String, int>{for (final gpId in gpIds) gpId: 0};
      final regimentThresholdCrossingsUp = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final regimentThresholdFirstReachTurn = <String, int?>{
        for (final gpId in gpIds) gpId: null,
      };
      final treasuryAtTurn99 = <String, int>{for (final gpId in gpIds) gpId: 0};
      // Treasury immediately after the previous turn resolved (seeded
      // from turn-0 pre-resolution treasury so the first crossing
      // detection compares against game start rather than zero).
      final treasuryPrevTurn = <String, int>{
        for (final gpId in gpIds) gpId: game.playerById(gpId)?.treasury ?? 0,
      };

      for (var t = 0; t < 100; t++) {
        // Refs #2847 H8: per-turn rebuild-readiness + cheapest-regiment input
        // availability, populated in the pre-resolution GP loop and reconciled
        // against the emitted military builds after the merge below.
        final turnRebuildReady = <String, bool>{};
        final turnInputsPresent = <String, bool>{};

        // Capture phase / arm decisions *before* the turn resolves so the
        // diagnostic reflects what the planner saw entering turn t+1.
        for (final gpId in gpIds) {
          final view = buildPlayerView(game, topo, gpId);
          final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
          final outcome = runPhasePlanners(game: game, snapshot: snap);
          phaseCounts[gpId]![outcome.phase] =
              (phaseCounts[gpId]![outcome.phase] ?? 0) + 1;
          final dwKey = outcome.expandDeclareWarTargetFactionId ?? '(null)';
          declareWarPicks[gpId]![dwKey] =
              (declareWarPicks[gpId]![dwKey] ?? 0) + 1;
          final peaceKey = outcome.expandPeaceTargetFactionIdsSorted.isEmpty
              ? '(none)'
              : outcome.expandPeaceTargetFactionIdsSorted.join(',');
          peaceTargetPicks[gpId]![peaceKey] =
              (peaceTargetPicks[gpId]![peaceKey] ?? 0) + 1;
          if (outcome.expandEconomyPlan.forceCheapestRegimentBuild) {
            economyArmCounts[gpId]!['forceCheapestRegimentBuild'] =
                (economyArmCounts[gpId]!['forceCheapestRegimentBuild'] ?? 0) +
                1;
          }
          if (outcome.expandEconomyPlan.boostTreasuryRecoveryCargo) {
            economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] =
                (economyArmCounts[gpId]!['boostTreasuryRecoveryCargo'] ?? 0) +
                1;
          }
          if (snap.conquest.invadableProvinceIdsSorted.isEmpty) {
            invadableEmptyTurns[gpId] = (invadableEmptyTurns[gpId] ?? 0) + 1;
          }
          for (final peer in snap.threats.atWarWith) {
            atWarTurnsByPeer[gpId]![peer] =
                (atWarTurnsByPeer[gpId]![peer] ?? 0) + 1;
          }
          final player = game.playerById(gpId);
          if (player != null) {
            final cheapest = cheapestRegimentBuildTreasuryCost();
            if (player.treasury < cheapest) {
              treasuryUnderCheapestTurns[gpId] =
                  (treasuryUnderCheapestTurns[gpId] ?? 0) + 1;
            } else {
              treasuryAtOrAboveCheapestTurns[gpId] =
                  (treasuryAtOrAboveCheapestTurns[gpId] ?? 0) + 1;
            }
          }
          final regiments = regimentCountForPlayer(game, gpId);
          if (regiments > (regimentPeak[gpId] ?? 0)) {
            regimentPeak[gpId] = regiments;
          }
          if (regiments == 0) {
            regimentTurnsAtZero[gpId] = (regimentTurnsAtZero[gpId] ?? 0) + 1;
          }
          // Refs #2847 H8 conversion-gap: classify this GP's pre-resolution
          // rebuild readiness and whether the cheapest-regiment build inputs
          // are already in the stockpile. Reconciled against the emitted
          // military builds after the merge below.
          final inputsPresent =
              player != null &&
              cheapestRegimentInputs.entries.every(
                (e) => player.stockpile.quantityOf(e.key) >= e.value,
              );
          turnInputsPresent[gpId] = inputsPresent;
          if (inputsPresent) {
            fabricInStockpileTurns[gpId] =
                (fabricInStockpileTurns[gpId] ?? 0) + 1;
          }
          final rebuildReady =
              outcome.expandEconomyPlan.forceCheapestRegimentBuild &&
              player != null &&
              player.treasury >= cheapestRegimentBuildTreasuryCost() &&
              regiments == 0;
          turnRebuildReady[gpId] = rebuildReady;
          if (rebuildReady) {
            rebuildReadyTurns[gpId] = (rebuildReadyTurns[gpId] ?? 0) + 1;
          }
          // Refs #2847 H8-supply feedstock-stage isolation (read-only). Splits
          // the domestic wool/cotton -> fabric production chain into its
          // proximate links: Builder-routing gate fired, an unimproved
          // feedstock resource tile is owned, feedstock reached the stockpile,
          // and a fabric recipe is feasible for at least one run.
          final feedstockGateActive =
              regimentBuildInputFeedstockExtractionResourceIds(
                game,
                gpId,
              ).isNotEmpty;
          if (feedstockGateActive) {
            feedstockExtractionGateActiveTurns[gpId] =
                (feedstockExtractionGateActiveTurns[gpId] ?? 0) + 1;
            // Refs #2847 H8-extraction execution-gap disambiguation: split the
            // gate-active turns by Builder availability and improvement
            // completion so the next slice can target the exact stage.
            if (_hasIdleBuilderUnit(game, gpId)) {
              feedstockGateIdleBuilderPresentTurns[gpId] =
                  (feedstockGateIdleBuilderPresentTurns[gpId] ?? 0) + 1;
            }
            if (_ownsImprovedFeedstockResourceTile(
              game,
              gpId,
              fabricFeedstockIds,
            )) {
              feedstockGateImprovedTileOwnedTurns[gpId] =
                  (feedstockGateImprovedTileOwnedTurns[gpId] ?? 0) + 1;
            }
            // Refs #2847 H8-extraction missing-candidate disambiguation: does
            // the work-order engine accept a feedstock `build_improvement`
            // candidate at all, and can the GP afford the level-0 improvement
            // cost? Splits the suppression between the validator material-cost
            // gate and the tile-control / visibility gates.
            if (_hasValidBuildImprovementOnUnimprovedFeedstockTile(
              game,
              topo,
              gpId,
              fabricFeedstockIds,
              tileMapByRegion: tileMap,
            )) {
              feedstockGateValidBuildImprovementCandidateTurns[gpId] =
                  (feedstockGateValidBuildImprovementCandidateTurns[gpId] ??
                      0) +
                  1;
            }
            if (_affordsBuildImprovementLevelZero(game, gpId)) {
              feedstockGateImprovementCostAffordableTurns[gpId] =
                  (feedstockGateImprovementCostAffordableTurns[gpId] ?? 0) + 1;
            }
          }
          if (_ownsUnimprovedFeedstockResourceTile(
            game,
            gpId,
            fabricFeedstockIds,
          )) {
            unimprovedFeedstockTileOwnedTurns[gpId] =
                (unimprovedFeedstockTileOwnedTurns[gpId] ?? 0) + 1;
          }
          if (supplierImprovementInputFeedstockExtractionResourceIds(
            game,
            gpId,
          ).isNotEmpty) {
            supplierFeedstockExtractionGateActiveTurns[gpId] =
                (supplierFeedstockExtractionGateActiveTurns[gpId] ?? 0) + 1;
            // While the supplier gate is active, record per-castIron-feedstock
            // whether the GP owns an unimproved tile of that commodity (a
            // Builder extraction target). Pins whether the supplier ever has an
            // `iron` source to feed domestic `castIron` (Refs #2847).
            final feedstockTiles =
                supplierActiveUnimprovedCastIronFeedstockTileTurns[gpId]!;
            for (final feedstockId in castIronFeedstockIds) {
              if (_ownsUnimprovedFeedstockResourceTile(
                game,
                gpId,
                {feedstockId},
              )) {
                feedstockTiles[feedstockId] =
                    (feedstockTiles[feedstockId] ?? 0) + 1;
              }
            }
          }
          if (player != null) {
            final holdsFeedstock = fabricFeedstockIds.any(
              (id) => player.stockpile.quantityOf(id) > 0,
            );
            if (holdsFeedstock) {
              feedstockInStockpileTurns[gpId] =
                  (feedstockInStockpileTurns[gpId] ?? 0) + 1;
            }
            final recipeFeasible = fabricRecipes.any(
              (recipe) => recipe.inputQuantities.entries.every(
                (e) => player.stockpile.quantityOf(e.key) >= e.value,
              ),
            );
            if (recipeFeasible) {
              fabricRecipeFeasibleTurns[gpId] =
                  (fabricRecipeFeasibleTurns[gpId] ?? 0) + 1;
            }
          }
          // Cache the turn-99 snapshot fields for the final rollup.
          if (t == 99) {
            lastSnapshotFields[gpId] = <String, Object?>{
              'oldWorldProvincesOwned': snap.conquest.oldWorldProvincesOwned,
              'invadableProvinceCount':
                  snap.conquest.invadableProvinceIdsSorted.length,
              'nwInvadableCount':
                  snap.colonial.invadableNewWorldProvinceIdsSorted.length,
              'atWarWith': snap.threats.atWarWith.toList()..sort(),
              'adjacentOwnerFactionIdsSorted':
                  snap.conquest.adjacentOwnerFactionIdsSorted,
              'treasury': player?.treasury,
              'regimentCount': regimentCountForPlayer(game, gpId),
              'cheapestRegimentBuildTreasuryCost':
                  cheapestRegimentBuildTreasuryCost(),
            };
          }
        }

        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );

        // Refs #2847 — count military `BuildUnitOrder`s the AI emits per
        // GP this turn (regiment / warship builds carry `isMilitary ==
        // true`). Compared against the regiment trajectory above, a high
        // emission count with a flat/zero peak indicates builds rejected
        // downstream or units lost as fast as they are produced; a low
        // emission count indicates the planner never queues the build.
        for (final gpId in gpIds) {
          final builds = merged.buildUnitOrdersByPlayerId[gpId];
          var emittedMilitaryThisTurn = false;
          if (builds != null) {
            for (final build in builds) {
              if (build.isMilitary) {
                militaryBuildOrdersEmitted[gpId] =
                    (militaryBuildOrdersEmitted[gpId] ?? 0) + 1;
                emittedMilitaryThisTurn = true;
              }
            }
          }
          // Refs #2847 H8 conversion-gap reconciliation. On a rebuild-ready
          // turn (directive active + treasury affordable + zero regiments)
          // that emitted no military build, attribute the miss to either a
          // missing cheapest-regiment input in the stockpile (production /
          // market-acquisition gap) or inputs-present-yet-no-build (downstream
          // suggestion / build-pick gate).
          if ((turnRebuildReady[gpId] ?? false) && !emittedMilitaryThisTurn) {
            rebuildReadyNoBuildTurns[gpId] =
                (rebuildReadyNoBuildTurns[gpId] ?? 0) + 1;
            if (turnInputsPresent[gpId] ?? false) {
              rebuildReadyNoBuildInputsPresentTurns[gpId] =
                  (rebuildReadyNoBuildInputsPresentTurns[gpId] ?? 0) + 1;
            } else {
              rebuildReadyNoBuildMissingInputTurns[gpId] =
                  (rebuildReadyNoBuildMissingInputTurns[gpId] ?? 0) + 1;
            }
          }
          // Refs #2847 H8-extraction castIron residual: did the economy planner
          // assign a domestic castIron recipe this turn (only possible when the
          // recipe's timber + iron feedstock is on hand for >= 1 full run)?
          final plan = fullAi.economyPlansByPlayerId[gpId];
          if (plan != null &&
              plan.productionAssignments.any(
                (a) => castIronRecipeIds.contains(a.recipeId),
              )) {
            castIronProductionAssignedTurns[gpId] =
                (castIronProductionAssignedTurns[gpId] ?? 0) + 1;
          }
        }

        // Refs #2924 Step 0 — count submitted trade orders per GP
        // from the merged order list that the resolver will apply.
        // Carry-forward bids/offers re-injected by the world-market
        // phase are not counted here; this metric reflects what the
        // AI actively emits each turn.
        for (final gpId in gpIds) {
          final tradeOrders = merged.tradeOrdersByPlayerId[gpId];
          if (tradeOrders == null) continue;
          for (final order in tradeOrders) {
            if (order.type == TradeOrderType.offer) {
              tradeOfferCount[gpId] = (tradeOfferCount[gpId] ?? 0) + 1;
              if (order.priority >= kTreasuryOfferPriorityUrgent) {
                tradeUrgentOfferCount[gpId] =
                    (tradeUrgentOfferCount[gpId] ?? 0) + 1;
              }
              if (improvementInputCommodityIds.contains(order.commodityId)) {
                improvementInputOffersEmitted[gpId] =
                    (improvementInputOffersEmitted[gpId] ?? 0) + 1;
              }
              if (castIronFeedstockIds.contains(order.commodityId)) {
                castIronFeedstockOffersEmitted[gpId] =
                    (castIronFeedstockOffersEmitted[gpId] ?? 0) + 1;
              }
            } else if (order.type == TradeOrderType.bid) {
              tradeBidCount[gpId] = (tradeBidCount[gpId] ?? 0) + 1;
              if (regimentInputCommodityIds.contains(order.commodityId)) {
                regimentInputBidsEmitted[gpId] =
                    (regimentInputBidsEmitted[gpId] ?? 0) + 1;
              }
              if (improvementInputCommodityIds.contains(order.commodityId)) {
                improvementInputBidsEmitted[gpId] =
                    (improvementInputBidsEmitted[gpId] ?? 0) + 1;
              }
              if (castIronFeedstockIds.contains(order.commodityId)) {
                castIronFeedstockBidsEmitted[gpId] =
                    (castIronFeedstockBidsEmitted[gpId] ?? 0) + 1;
              }
            }
          }
        }

        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        game = (result as TurnResolutionComplete).game;

        // Refs #2924 Step 0 — tally deals matched per GP from the
        // post-resolution world-market activity. `lastTurnActivity`
        // holds the deals that filled during phase 13 of the just-
        // resolved turn; we accumulate seller/buyer counts and the
        // resulting treasury credit/debit per GP. Treasury delta is
        // rounded the same way the world-market phase computes the
        // notional transfer per `SPEC/program/world-market-resolution.md`.
        final activity = game.worldMarketState.lastTurnActivity;
        for (final entry in activity.entries) {
          for (final deal in entry.value.deals) {
            final notional = (deal.quantity * deal.pricePerUnit).round();
            final seller = deal.sellerFactionId;
            if (treasuryCredited.containsKey(seller)) {
              dealsAsSeller[seller] = (dealsAsSeller[seller] ?? 0) + 1;
              treasuryCredited[seller] =
                  (treasuryCredited[seller] ?? 0) + notional;
            }
            final buyer = deal.buyerFactionId;
            if (treasuryDebited.containsKey(buyer)) {
              dealsAsBuyer[buyer] = (dealsAsBuyer[buyer] ?? 0) + 1;
              treasuryDebited[buyer] = (treasuryDebited[buyer] ?? 0) + notional;
              if (regimentInputCommodityIds.contains(deal.commodityId)) {
                regimentInputDealsAsBuyer[buyer] =
                    (regimentInputDealsAsBuyer[buyer] ?? 0) + 1;
              }
              if (improvementInputCommodityIds.contains(deal.commodityId)) {
                improvementInputDealsAsBuyer[buyer] =
                    (improvementInputDealsAsBuyer[buyer] ?? 0) + 1;
              }
              if (castIronFeedstockIds.contains(deal.commodityId)) {
                castIronFeedstockDealsAsBuyer[buyer] =
                    (castIronFeedstockDealsAsBuyer[buyer] ?? 0) + 1;
              }
            }
          }
        }

        // Refs #2924 Step 0 — treasury threshold crossings:
        // count turn boundaries where a GP transitions from
        // `treasury < cheapestRegimentBuildTreasuryCost` to
        // `treasury >= cheapestRegimentBuildTreasuryCost` based on
        // post-resolution treasury. First-reach turn captures the
        // earliest turn at which each GP's post-turn treasury can
        // afford the cheapest regiment.
        final cheapest = cheapestRegimentBuildTreasuryCost();
        for (final gpId in gpIds) {
          final after = game.playerById(gpId)?.treasury ?? 0;
          final before = treasuryPrevTurn[gpId] ?? 0;
          if (before < cheapest && after >= cheapest) {
            regimentThresholdCrossingsUp[gpId] =
                (regimentThresholdCrossingsUp[gpId] ?? 0) + 1;
          }
          if (regimentThresholdFirstReachTurn[gpId] == null &&
              after >= cheapest) {
            regimentThresholdFirstReachTurn[gpId] = t;
          }
          treasuryPrevTurn[gpId] = after;
          if (t == 99) {
            treasuryAtTurn99[gpId] = after;
            final player = game.playerById(gpId);
            if (player != null) {
              improvementInputHeldAtTurn99[gpId] = improvementInputCommodityIds
                  .fold<int>(
                    0,
                    (sum, id) => sum + player.stockpile.quantityOf(id),
                  );
              lumberHeldAtTurn99[gpId] = player.stockpile.quantityOf('lumber');
              castIronHeldAtTurn99[gpId] = player.stockpile.quantityOf(
                'castIron',
              );
              final feedstockHeld = castIronFeedstockHeldAtTurn99[gpId]!;
              for (final feedstockId in castIronFeedstockIds) {
                feedstockHeld[feedstockId] = player.stockpile.quantityOf(
                  feedstockId,
                );
              }
            }
          }
        }
      }

      final gains = <String, int>{
        for (final gpId in gpIds)
          gpId:
              game.worldState.oldWorld.provinces
                  .where((p) => p.ownerId == gpId)
                  .length -
              owStart[gpId]!,
      };

      // Structured JSON dump for inclusion in the S7-D diagnostic note.
      final diagnostic = <String, Object?>{
        'issue': 2847,
        'subtask': 'S7-D',
        'seed': 42,
        'turns': 100,
        'gpOwGain': gains,
        'gpOwStart': owStart,
        'gpPhaseTurnCount': {
          for (final gpId in gpIds)
            gpId: {
              for (final entry in phaseCounts[gpId]!.entries)
                entry.key.name: entry.value,
            },
        },
        'gpDeclareWarPickDistribution': declareWarPicks,
        'gpExpandPeacePickDistribution': peaceTargetPicks,
        'gpExpandEconomyArmCounts': economyArmCounts,
        'gpInvadableEmptyTurns': invadableEmptyTurns,
        'gpAtWarTurnsByPeer': atWarTurnsByPeer,
        'gpTreasuryUnderCheapestRegimentTurns': treasuryUnderCheapestTurns,
        'gpTreasuryAtOrAboveCheapestRegimentTurns':
            treasuryAtOrAboveCheapestTurns,
        'gpRegimentPeak': regimentPeak,
        'gpRegimentTurnsAtZero': regimentTurnsAtZero,
        'gpMilitaryBuildOrdersEmitted': militaryBuildOrdersEmitted,
        'gpCheapestRegimentInputsInStockpileTurns': fabricInStockpileTurns,
        'gpRebuildReadyTurns': rebuildReadyTurns,
        'gpRebuildReadyNoBuildTurns': rebuildReadyNoBuildTurns,
        'gpRebuildReadyNoBuildMissingInputTurns':
            rebuildReadyNoBuildMissingInputTurns,
        'gpRebuildReadyNoBuildInputsPresentTurns':
            rebuildReadyNoBuildInputsPresentTurns,
        'regimentInputCommodityIds': regimentInputCommodityIds.toList()..sort(),
        'gpRegimentInputBidsEmitted': regimentInputBidsEmitted,
        'gpRegimentInputDealsAsBuyer': regimentInputDealsAsBuyer,
        'improvementInputCommodityIds': improvementInputCommodityIds.toList()
          ..sort(),
        'gpImprovementInputOffersEmitted': improvementInputOffersEmitted,
        'gpImprovementInputBidsEmitted': improvementInputBidsEmitted,
        'gpImprovementInputDealsAsBuyer': improvementInputDealsAsBuyer,
        'gpImprovementInputHeldAtTurn99': improvementInputHeldAtTurn99,
        'castIronFeedstockCommodityIds': castIronFeedstockIds.toList()..sort(),
        'gpCastIronFeedstockOffersEmitted': castIronFeedstockOffersEmitted,
        'gpCastIronFeedstockBidsEmitted': castIronFeedstockBidsEmitted,
        'gpCastIronFeedstockDealsAsBuyer': castIronFeedstockDealsAsBuyer,
        'gpCastIronProductionAssignedTurns': castIronProductionAssignedTurns,
        'gpSupplierFeedstockExtractionGateActiveTurns':
            supplierFeedstockExtractionGateActiveTurns,
        'gpSupplierActiveUnimprovedCastIronFeedstockTileTurns':
            supplierActiveUnimprovedCastIronFeedstockTileTurns,
        'gpCastIronFeedstockHeldAtTurn99': castIronFeedstockHeldAtTurn99,
        'gpLumberHeldAtTurn99': lumberHeldAtTurn99,
        'gpCastIronHeldAtTurn99': castIronHeldAtTurn99,
        'fabricFeedstockCommodityIds': fabricFeedstockIds.toList()..sort(),
        'gpFeedstockExtractionGateActiveTurns':
            feedstockExtractionGateActiveTurns,
        'gpUnimprovedFeedstockTileOwnedTurns':
            unimprovedFeedstockTileOwnedTurns,
        'gpFeedstockGateIdleBuilderPresentTurns':
            feedstockGateIdleBuilderPresentTurns,
        'gpFeedstockGateImprovedTileOwnedTurns':
            feedstockGateImprovedTileOwnedTurns,
        'gpFeedstockGateValidBuildImprovementCandidateTurns':
            feedstockGateValidBuildImprovementCandidateTurns,
        'gpFeedstockGateImprovementCostAffordableTurns':
            feedstockGateImprovementCostAffordableTurns,
        'gpFeedstockInStockpileTurns': feedstockInStockpileTurns,
        'gpFabricRecipeFeasibleTurns': fabricRecipeFeasibleTurns,
        'gpTurn99Snapshot': lastSnapshotFields,
      };

      // Refs #2924 Step 0 — separate structured block scoped to the
      // world-market lock-recovery diagnostic surface so the issue
      // comment can transcribe just this block without dragging in
      // the wider #2847 S7-D payload. Field names mirror the
      // metrics named in `#2924` § Recommended sequencing Step 0:
      // trade orders emitted, deals matched, treasury credited /
      // debited, `cheapestRegimentBuildTreasuryCost` threshold
      // crossings, and the pre-existing
      // `gpTreasuryUnderCheapestRegimentTurns` counter.
      final lockRecoveryDiagnostic = <String, Object?>{
        'issue': 2924,
        'step': 'Step 0',
        'seed': 42,
        'turns': 100,
        'cheapestRegimentBuildTreasuryCost':
            cheapestRegimentBuildTreasuryCost(),
        'gpTradeOrdersEmitted': {
          for (final gpId in gpIds)
            gpId: <String, int>{
              'offers': tradeOfferCount[gpId] ?? 0,
              'urgentOffers': tradeUrgentOfferCount[gpId] ?? 0,
              'bids': tradeBidCount[gpId] ?? 0,
            },
        },
        'gpDealsMatched': {
          for (final gpId in gpIds)
            gpId: <String, int>{
              'asSeller': dealsAsSeller[gpId] ?? 0,
              'asBuyer': dealsAsBuyer[gpId] ?? 0,
            },
        },
        'gpTreasuryCreditedByDeals': treasuryCredited,
        'gpTreasuryDebitedByDeals': treasuryDebited,
        'gpRegimentThresholdCrossingsUp': regimentThresholdCrossingsUp,
        'gpRegimentThresholdFirstReachTurn': regimentThresholdFirstReachTurn,
        'gpTreasuryUnderCheapestRegimentTurns': treasuryUnderCheapestTurns,
        'gpTreasuryAtTurn99': treasuryAtTurn99,
      };

      // Re-enable info-level logging so the structured diagnostic JSON
      // surfaces in stdout via the package logger (the simulation above
      // intentionally ran with logging off to suppress planner noise).
      // Routing through `aiLogger` keeps this test compliant with the
      // disallowed-AST `avoid_print_suppression` rule while preserving
      // greppable BEGIN/END markers for issue-comment transcription.
      CtLogger.level = Level.info;
      final log = aiLogger('s7d-diagnostic');
      log.i('S7D_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('S7D_DIAGNOSTIC_JSON_END');
      log.i('ISSUE2924_STEP0_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(lockRecoveryDiagnostic));
      log.i('ISSUE2924_STEP0_JSON_END');

      // Lightweight assertion: data was actually collected. The diagnostic
      // does not pin arm-fire counts so the planner can be tuned freely
      // in S7-T without churn here.
      for (final gpId in gpIds) {
        expect(
          phaseCounts[gpId]!.values.fold<int>(0, (a, b) => a + b),
          100,
          reason: '$gpId phase-count total should equal turn count',
        );
        // Refs #2847 H8: structural invariant on the conversion-gap split.
        // Every rebuild-ready turn with no military build is attributed to
        // exactly one of the two mutually exclusive sub-causes, so the parts
        // must sum to the whole. This guards the instrumentation itself
        // without pinning the (freely tunable) per-GP counts.
        expect(
          rebuildReadyNoBuildMissingInputTurns[gpId]! +
              rebuildReadyNoBuildInputsPresentTurns[gpId]!,
          rebuildReadyNoBuildTurns[gpId],
          reason:
              '$gpId rebuild-ready no-build turns must split into '
              'missing-input + inputs-present sub-causes',
        );
        // Refs #2847 H8-extraction: the disambiguation sub-counters are each
        // measured only on a feedstock-gate-active turn, so neither can exceed
        // the gate-active total. Guards the instrumentation gating itself
        // without pinning the (freely tunable) per-GP counts.
        expect(
          feedstockGateIdleBuilderPresentTurns[gpId]!,
          lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
          reason:
              '$gpId idle-Builder-present turns cannot exceed the '
              'feedstock-extraction-gate-active turns',
        );
        expect(
          feedstockGateImprovedTileOwnedTurns[gpId]!,
          lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
          reason:
              '$gpId improved-feedstock-tile-owned turns cannot exceed the '
              'feedstock-extraction-gate-active turns',
        );
        // Refs #2847 H8-extraction missing-candidate disambiguation: both
        // sub-counters are measured only on a feedstock-gate-active turn, so
        // neither can exceed the gate-active total. Guards the instrumentation
        // gating itself without pinning the (freely tunable) per-GP counts.
        expect(
          feedstockGateValidBuildImprovementCandidateTurns[gpId]!,
          lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
          reason:
              '$gpId valid-feedstock-build_improvement-candidate turns cannot '
              'exceed the feedstock-extraction-gate-active turns',
        );
        expect(
          feedstockGateImprovementCostAffordableTurns[gpId]!,
          lessThanOrEqualTo(feedstockExtractionGateActiveTurns[gpId]!),
          reason:
              '$gpId feedstock improvement-cost-affordable turns cannot exceed '
              'the feedstock-extraction-gate-active turns',
        );
      }
    },
    skip:
        'Refs #2847 S7-D: long-running (~4 min) per-GP EXPAND-arm '
        'diagnostic. Captured findings live in the doc comment above '
        'and in the issue\'s S7-D note. Re-run with `dart test '
        '--run-skipped` when the diagnostic surface shifts after a '
        'tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
