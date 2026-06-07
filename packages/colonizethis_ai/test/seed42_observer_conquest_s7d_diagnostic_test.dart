import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricMarketPathActive;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show
        cheapestRegimentBuildTreasuryCost,
        expandSellerFeedstockTileAcquisitionTarget;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        hasIdleExplorerUnit,
        ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile,
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile,
        ownsProspectedOldWorldMineralFeedstockTile,
        regimentBuildInputFeedstockExtractionResourceIds,
        colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates,
        suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile,
        supplierImprovementInputFeedstockExtractionResourceIds;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';
import 'support/seed42_s7d_feedstock_helpers.dart';

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
/// ## S7-D refresh (captured 2026-06-05 on merged `dev`, per-component
///     affordability split — this slice, Refs #2847)
///
/// The level-0 `build_improvement` cost is purely material
/// (`work_order_costs.dart` § `workOrderCostBuildImprovement(0)` = 1 `lumber` +
/// 1 `castIron`) — there is **no** treasury or recipe-cost gate, so the
/// combined `gpFeedstockGateImprovementCostAffordableTurns` (which requires
/// **both** materials at once) is split into two read-only per-component
/// counters measured on feedstock-extraction-gate-active turns:
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateImprovementCastIronAffordableTurns`. This localizes *which*
/// material binds during the gate window, not only at the turn-99 snapshot.
///
/// **Result (seed 42, turn 100; OW gate unchanged — gp1/gp2 = +6 PASS, gp3 =
/// +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL):**
///
/// | GP | gate-active | valid candidate | combined affordable | lumber affordable | castIron affordable |
/// |----|------------:|----------------:|--------------------:|------------------:|--------------------:|
/// | gp3 | 32 | 0 | 0 | **0** | **0** |
/// | gp5 | 13 | 2 | 0 | **2** | **0** |
/// | gp6 | 59 | 1 | 0 | **1** | **0** |
///
/// (gp1/gp2/gp4 hold the gate inactive — 0 gate-active turns — so all their
/// counters are 0 by construction; gp1/gp2 win OW without the feedstock chain.)
///
/// **Decisive localization:** `castIron` is the **universal binding material** —
/// `gpFeedstockGateImprovementCastIronAffordableTurns` is **0** for every
/// failing GP, so no GP ever holds the `castIron` share on any gate-active turn.
/// The combined counter tracks the `castIron` component exactly (0 / 0 / 0),
/// while the `lumber` component is occasionally satisfied (gp5 = 2, gp6 = 1,
/// matching their valid-candidate turns). gp3 is a distinct, more severe class:
/// it holds **neither** `lumber` nor `castIron` on **any** of its 32
/// gate-active turns (both = 0), consistent with its flat
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` = 0.
///
/// **Re-pointed next slice:** the binding shortfall is **`castIron` supply**,
/// not `lumber` and not a treasury/affordability *threshold* (treasury at
/// turn 99 now sits at gp3 = 2029, gp4 = 2170, gp5 = 2036, gp6 = 2036 — all
/// above `cheapestRegimentBuildTreasuryCost` = 2000, so treasury is no longer
/// the binding constraint). The next behavioural slice must make a locked
/// seller actually **produce or acquire its first `castIron`** (domestic
/// `castIron` from co-available `timber` + `iron`, per the prior co-availability
/// finding), and for gp3 additionally secure `lumber`. This split de-risks that
/// slice by confirming `lumber` is *not* the universal blocker. Per the scope
/// boundary, this remains the #2847 OW-conquest material-chain bootstrap (not
/// the colonial economy / Merchant gates scoped to #2852). Verify the next
/// slice by re-running this diagnostic and confirming
/// `gpFeedstockGateImprovementCastIronAffordableTurns` rises above 0 for
/// gp3 / gp5 / gp6 before expecting OW gain to move.
///
/// ## S7-D refresh (captured 2026-06-05 on current `dev` HEAD post-#3264 —
///     lumber re-localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (after the gp1 Old World
/// feedstock-prospect localization #3262 / #3263 / #3264) reproduces the prior
/// surface at the OW gate (gp1 / gp2 = +6 PASS; gp3 = +2, gp4 = +1, gp5 = +1,
/// gp6 = +2 FAIL) and at the feedstock affordability split
/// (`gpFeedstockGateImprovementCastIronAffordableTurns` = 0 for every GP;
/// `gpFeedstockGateImprovementLumberAffordableTurns` = gp5 2 / gp6 1 / gp3 0).
/// #3262 / #3263 / #3264 therefore did **not** move this surface.
///
/// **Correction to the prior "`castIron` is the universal binding material"
/// pointer (above):** the gate the next slice must actually move is the
/// production work-order **validator** candidate
/// (`gpFeedstockGateValidBuildImprovementCandidateTurns` = gp5 2 / gp6 1 /
/// gp3 0), measured through `getValidWorkOrderTileKeys` — which applies the
/// level-0 `castIron` **waiver**
/// (`feedstockBootstrapBuildImprovementCastIronWaived`: when the feedstock-
/// extraction gate is active and the GP holds the `lumber` share but not the
/// `castIron` share, the level-0 `build_improvement` may omit `castIron`).
/// The valid-candidate count tracks the **`lumber`** component exactly
/// (gp5 2 = 2, gp6 1 = 1, gp3 0 = 0) and is independent of the `castIron`
/// component (0 / 0 / 0): under the waiver `castIron` is **not** required to
/// extract the feedstock tile, so `castIron`-affordability = 0 does not gate
/// the `build_improvement` — **`lumber`** does.
///
/// **What `castIron` actually starves is one stage downstream.** Even where the
/// tile is extracted, the multi-input `castIron` recipe is never assigned by any
/// GP (`gpCastIronProductionAssignedTurns` = 0 for all six) because `iron` never
/// reaches any stockpile (`gpCastIronFeedstockHeldAtTurn99` iron = 0 for all
/// six; gp2 holds `timber` = 46 but `iron` = 0), even though the affluent
/// suppliers own a prospected, unimproved `iron` feedstock tile all 59
/// supplier-gate turns (`gpSupplierActiveUnimprovedCastIronFeedstockTileTurns`
/// gp1 / gp2 iron = 59; `gpSupplierProspectedMineralFeedstockTileTurns`
/// gp1 / gp2 = 59). The supplier's prospected `iron` tile is never *improved*
/// for the same reason: improving it also costs one `lumber` (+ waived
/// `castIron`), and only gp2 ever offers `lumber`
/// (`gpImprovementInputOffersEmitted` gp2 = 11; gp1 = 0), of which gp5 / gp6 win
/// a couple (`gpImprovementInputDealsAsBuyer` gp5 2 / gp6 1) and gp3 wins none
/// (0).
///
/// **Re-pointed next slice (supersedes the `castIron`-supply pointer above):**
/// the universal binding shortfall is **`lumber` supply for the level-0
/// `build_improvement`**, not `castIron`. Both the seller's own fabric-feedstock
/// extraction and the supplier's `iron` extraction are gated on holding one
/// `lumber` (with `castIron` waived), and the world market under-supplies it
/// (one offerer, gp1 silent). The next behavioural slice should make affluent
/// suppliers **over-produce and release `lumber`** for peer locked sellers
/// (mirroring the existing `castIron` supplier-release path, which today targets
/// only `kDomesticProductionImprovementInputIds = {castIron}`) and / or let a
/// locked seller domestically produce `lumber` from owned `timber`, so the
/// waived `build_improvement` becomes affordable on more than 0-2 turns. Verify
/// by re-running this diagnostic and confirming
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` rise for gp3 / gp5 / gp6
/// (and, one stage on, `gpCastIronProductionAssignedTurns` > 0 once `iron`
/// extracts) before expecting OW gain to move. The +6 baseline GPs (gp1 / gp2)
/// stay unaffected: a `lumber` supplier-release boost reuses the existing
/// leftover-labour-only sizing argument that keeps the conquest economy intact.
///
/// **Post-implementation refresh (supplier `lumber`-release slice landed).**
/// The supplier-release set was generalized from the hardcoded
/// `kDomesticProductionImprovementInputIds = {castIron}` to
/// `peerLockRecoverySellerNeededProducibleImprovementInputs(...)` (now exported
/// from `ai_api.dart`), so an affluent supplier over-produces whichever
/// producible improvement input a peer lock-recovery seller actually binds on —
/// `lumber` here, not the waived `castIron`. The economy- and treasury-planner
/// triggers were generalized to match, with positive + negative-control unit
/// coverage in `economy_planner_regiment_build_input_production_test.dart`.
/// Re-running this diagnostic on the change produces a **byte-identical** seed-42
/// surface: `gpImprovementInputOffersEmitted` unchanged (gp1 = 0, gp2 = 11),
/// `gpFeedstockGateImprovementLumberAffordableTurns` /
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` unchanged
/// (gp5 = 2, gp6 = 1, gp3 = 0), `gpImprovementInputDealsAsBuyer` unchanged
/// (gp5 = 2, gp6 = 1, gp3 = 0), and OW gain unchanged. The release boost is
/// therefore **correct groundwork but verified necessary-but-insufficient** on
/// this seed: it re-prioritizes leftover supplier labour toward the binding
/// material, but it cannot release `lumber` the suppliers do not produce/hold —
/// gp1 stays silent (0 offers) and gp2's 11 offers are its pre-existing output,
/// neither of which the prioritization-only boost increases.
///
/// **Re-pointed lever (supersedes the supplier-release pointer above).** The
/// binding shortfall is `lumber` **production/supply capacity**, not its release
/// prioritization. The next slice should make the locked seller domestically
/// produce `lumber` from its own `timber` (option b above) — gp3 holds
/// `timber` = 7 (`gpCastIronFeedstockHeldAtTurn99`), so a seller-side
/// `lumber_from_timber` assignment removes the dependence on a thin one-offerer
/// market — and/or raise the supplier's `timber`->`lumber` throughput so the
/// release set has surplus to ship. Verify the same way: confirm
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateValidBuildImprovementCandidateTurns` rise for gp3 / gp5 / gp6
/// before expecting OW gain to move.
///
/// **Post-implementation refresh (seller domestic `lumber`-production slice
/// landed; captured 2026-06-05 on current `dev` HEAD post-#3267, Refs #2847).**
/// Option (b) above is now implemented: the locked seller's domestic-production
/// set was generalized from the market-absent `castIron`-only filter to
/// `selfLockRecoverySellerNeededProducibleImprovementInputs(...)`, so a seller
/// short the **binding** level-0 `lumber` input now boosts `lumber_from_timber`
/// from its own `timber` instead of depending on the thin one-offerer market,
/// and the single-input `lumber` output is excluded from the seller's feedstock
/// reserve so it draws only *surplus* `timber` (preserving the multi-input
/// `castIron` co-availability guarantee). Positive + negative-control unit
/// coverage in `economy_planner_regiment_build_input_production_test.dart` and a
/// logic contract test in
/// `full_ai_civilian_work_regiment_build_input_feedstock_extraction_test.dart`;
/// SPEC updated in `SPEC/ai/economy-planner.md` § Domestic improvement-input
/// production.
///
/// This slice is **correct groundwork but verified byte-identical
/// (necessary-but-insufficient)** on seed 42: OW gain unchanged (gp1/gp2 **+6**
/// PASS; gp3 +2, gp4 +1, gp5 +1, gp6 +2 FAIL),
/// `gpFeedstockGateImprovementLumberAffordableTurns` unchanged (gp5 2 / gp6 1 /
/// gp3 0), `gpLumberHeldAtTurn99` still 0 for every failing GP. The decisive
/// reason: **the failing sellers hold no `timber`** to convert —
/// `gpCastIronFeedstockHeldAtTurn99` shows `timber = 0` (and `iron = 0`) for
/// gp3 / gp4 / gp5 / gp6 at turn 99 (only the suppliers gp2 holds `timber 44`).
/// `lumber_from_timber` therefore stays infeasible for the very GPs that bind on
/// `lumber`, so the now-enabled domestic path has no feedstock to run — the
/// mirror of #3267's supplier-release slice, which could not release `lumber`
/// the suppliers do not hold.
///
/// **Re-pointed lever — now landed.** The binding precondition was **seller
/// `timber` holdings**: the locked seller owns unimproved `timber` tiles but
/// holds zero `timber`, so neither `lumber_from_timber` nor
/// `castIron_from_timber_iron_coal` had feedstock. That lever is now
/// implemented: `sellerImprovementInputFeedstockExtractionResourceIds`
/// (`full_ai_civilian_work_selection.dart`) extends the H8 feedstock-extraction
/// gate (via `feedstockExtractionResourceIdsForPlayer`) to the seller's own
/// `lumber` / `castIron` improvement-input feedstock (`timber` / `iron`), not
/// only the `fabric`-recipe feedstock `wool` / `cotton`, so the locked seller's
/// idle Builder is routed onto its own unimproved `timber` tile (improving a
/// `timber` surface tile is itself level-0 `build_improvement`, covered by the
/// same `castIron`-waiver once one `lumber` is on hand), and the Old World
/// feedstock unit reservation holds that Builder in the Old World.
/// `gpFeedstockGateIdleBuilderPresentTurns` (gp3 32 / gp5 13 / gp6 59) confirms
/// an idle Builder is available to route. Verify by confirming
/// `gpCastIronFeedstockHeldAtTurn99` `timber` rises above 0 for gp3 / gp5 / gp6,
/// then `gpFeedstockGateImprovementLumberAffordableTurns` rises, before
/// expecting OW gain to move. The residual lever for a seller that owns **no**
/// `timber` tile at all is feedstock-tile acquisition (further #2847 work).
///
/// ## S7-D refresh (captured 2026-06-05 on merged `dev` post-#3274 —
///     acquisition-thread localization, this slice, Refs #2847)
///
/// Post-#3274 (conquest army-move target bias for flagged seller feedstock
/// province), the OW gate is unchanged (gp1/gp2 **+6** PASS; gp3 +2, gp4 +1,
/// gp5 +1, gp6 +2 FAIL). Two new read-only counters localize whether the
/// seller feedstock-tile **acquisition** thread (declare-war bias #3273 +
/// army-move bias #3274) engages on seed 42:
///
///   * `gpFeedstockAcquisitionTargetActiveTurns` — turns where
///     `expandSellerFeedstockTileAcquisitionTarget(game, snap)` returns a
///     non-null conquest-reachable Old World feedstock province.
///   * `gpFeedstockAcquisitionTargetWithFieldArmyTurns` — subset where the GP
///     also owns a non-home field army to execute the march.
///
/// **Result: both counters are 0 for every GP (gp1–gp6) on all 100 turns.**
///
/// **Decisive localization:** the acquisition residual
/// (`sellerNeedsImprovementInputFeedstockTileAcquisition`) is **inactive** for
/// every failing GP on seed 42 because each already **owns** an unimproved
/// feedstock tile (`gpUnimprovedFeedstockTileOwnedTurns` = 100 for all six GPs).
/// The acquisition path fires only when the seller owns **no** feedstock tile at
/// all; the failing GPs instead need to **improve** tiles they already hold
/// (blocked on `lumber` supply per the prior refresh). The #3271–#3274 conquest-
/// acquisition thread (detection → target pick → declare-war bias → army-move
/// bias) is therefore **structurally present and unit-tested** but **inert on
/// this seed** — it does not apply to the current failing-GP profile. gp3's
/// `gpFeedstockGateImprovedTileOwnedTurns` = 0 despite 32 gate-active turns
/// with an idle Builder confirms the break remains on the **extraction /
/// lumber-supply** path (improve the owned tile), not on conquest acquisition.
///
/// **Re-pointed next slice (supersedes the acquisition-thread pointer above):**
/// continue the **lumber-supply / owned-tile extraction** lever for gp3 / gp5 /
/// gp6 (`gpFeedstockGateImprovementLumberAffordableTurns` gp5 = 2 / gp6 = 12 /
/// gp3 = 0; `gpFeedstockGateImprovedTileOwnedTurns` gp5 = 49 / gp6 = 20 / gp3 =
/// 0), **not** further conquest-acquisition bias slices (the acquisition
/// residual never activates on this seed). The acquisition-thread counters
/// remain in the diagnostic for seeds / GP profiles where a locked seller owns
/// **no** feedstock tile. Verify the next extraction slice by confirming
/// `gpFeedstockGateImprovementLumberAffordableTurns` and
/// `gpFeedstockGateImprovedTileOwnedTurns` rise for gp3 before expecting OW
/// gain to move.
///
/// ## S7-D refresh (captured 2026-06-05 — lumber bootstrap waiver slice,
///     Refs #2847)
///
/// The level-0 `build_improvement` **lumber waiver** (scoped to improvement-
/// input feedstock tiles `timber` / `iron` only — not regiment-build-input
/// `wool` / `cotton`) waives both `lumber` and `castIron` when the seller
/// holds neither, breaking the chicken-and-egg where improving the owned
/// `timber` tile requires `lumber` the seller does not yet hold. Re-running
/// this diagnostic on the change:
///
/// | GP | OW gain | lumber affordable | valid candidate | improved tile owned |
/// |----|---------|------------------:|----------------:|--------------------:|
/// | gp1 | +6 ✅ | 0 | 0 | 0 |
/// | gp2 | +6 ✅ | 0 | 0 | 0 |
/// | gp3 | +2 ❌ | **14** (was 0) | **14** (was 0) | **23** (was 0) |
/// | gp4 | +1 ❌ | 0 | 0 | 0 |
/// | gp5 | +1 ❌ | **15** (was 2) | **15** (was 2) | 35 (was 49) |
/// | gp6 | +2 ❌ | **14** (was 12) | **14** (was 1) | **38** (was 20) |
///
/// **Decisive localization:** the lumber bootstrap **unblocks the owned-tile
/// extraction path** for gp3 / gp5 / gp6 (`gpFeedstockGateImprovementLumberAffordableTurns` and `gpFeedstockGateImprovedTileOwnedTurns` rise materially; gp3 moves off the all-zero floor). OW gain is **unchanged** at the turn-100 gate (gp3 +2, gp4 +1, gp5 +1, gp6 +2) — the slice is **correct groundwork but verified necessary-but-insufficient** on seed 42, mirroring prior H8 slices. The +6 baseline (gp1 / gp2) is preserved. A broader unscoped waiver that also zero-cost-improved `wool` / `cotton` fabric feedstock **regressed gp5 OW gain to −7**; scoping to improvement-input feedstock only restored gp5 to +1.
///
/// **Re-pointed next slice:** downstream of the now-improving feedstock tiles —
/// confirm `gpCastIronFeedstockHeldAtTurn99` `timber` / `iron` rise, domestic
/// `lumber` / `castIron` production assigns, and the fabric → regiment → OW
/// conquest chain completes before expecting OW gain to reach +3.
///
/// ## S7-D refresh (captured 2026-06-06 on current `dev` HEAD — castIron
///     production-assignment localization, this slice, Refs #2847)
///
/// Re-running the diagnostic on the merged `dev` HEAD (post the seller
/// feedstock-tile acquisition thread #3271–#3276 and the lumber bootstrap
/// waiver) confirms the prior re-pointed step is now reached: the owned-tile
/// extraction path **works** for gp5 / gp6 — `gpFeedstockInStockpileTurns` =
/// gp5 49 / gp6 44 (was 1) and `gpCastIronFeedstockHeldAtTurn99` shows **gp5
/// co-holds `timber` = 71 and `iron` = 64** at turn 99 (gp6 `timber` = 214 /
/// `iron` = 0; gp3 / gp4 still 0 / 0). OW gain is unchanged (gp1 / gp2 = +6
/// PASS; gp3 = +2, gp4 = +1, gp5 = +1, gp6 = +2 FAIL).
///
/// **Decisive new localization:** `gpCastIronProductionAssignedTurns` is **0
/// for every GP including gp5**, yet the only `castIron` recipe
/// (`castIron_from_timber_iron_coal`) consumes only `timber` × 2 + `iron` × 2
/// (no coal in `inputQuantities`) — so gp5's turn-99 holdings (71 / 64) make it
/// **materially feasible**. This slice adds the missing per-turn signal,
/// `gpCastIronRecipeFeasibleTurns` (built on the read-only pure helper
/// `stockpileAffordsAnyProductionRecipe`, mirroring the existing inline
/// `fabricRecipes` feasibility check), to confirm the feasibility holds across
/// the run, not only at the terminal snapshot. A non-zero
/// `gpCastIronRecipeFeasibleTurns` alongside `gpCastIronProductionAssignedTurns`
/// = 0 splits the residual decisively: the `castIron` chain is no longer
/// blocked on **feedstock supply** (the extraction lever landed) but on
/// **production allocation** — the economy planner never assigns the feasible
/// `castIron` recipe for the lock-recovery seller.
///
/// **Re-pointed next slice (supersedes the "confirm downstream production
/// assigns" pointer above):** target **`castIron` production-recipe
/// assignment** for a below-quota zero-NW lock-recovery seller that already
/// holds (or can co-extract) `timber` + `iron` — i.e. make the economy
/// planner stage the domestic `castIron` run on feasible turns (mirroring the
/// treasury-independent `fabricFrom*` and `lumber_from_timber` staging already
/// landed for the same gate), **not** further feedstock-extraction or
/// supplier-release work (gp5 already co-holds both feedstocks). Verify by
/// re-running this diagnostic and confirming `gpCastIronProductionAssignedTurns`
/// rises above 0 for gp5 / gp6 (and, one stage on,
/// `gpRebuildReadyNoBuildMissingInputTurns` falls) before expecting OW gain to
/// move. The +6 baseline (gp1 / gp2) stays unaffected: they assign / hold
/// `castIron` independently and never enter the lock-recovery seller gate.
///
/// ## S7-D refresh (captured 2026-06-06 — castIron staging path landed,
///     Refs #2847, PR #3289)
///
/// The economy planner now adds
/// `selfLockRecoverySellerStageableImprovementInputs(game, playerId)` to the
/// domestic production boost: the producible **multi-input** level-0
/// improvement input (`castIron`) a below-quota zero-NW lock-recovery seller
/// (zero regiments) is short of **and still owns a `timber` / `iron` feedstock
/// tile for**, so the seller can stage the run even after its fabric-feedstock
/// improvement-cost gate goes inactive. Unit coverage:
/// `self_lock_recovery_seller_stageable_improvement_inputs_test.dart` (logic)
/// and `economy_planner_regiment_build_input_production_test.dart` (AI);
/// SPEC updated in `SPEC/ai/economy-planner.md` § Domestic castIron staging
/// after the fabric gate goes inactive.
///
/// Re-running this diagnostic on the change is **necessary-but-insufficient**
/// on seed 42: the +6 baseline is preserved (gp1 / gp2 **+6** PASS; gp3 +2,
/// gp4 +1, gp5 +1, gp6 +2 FAIL — OW gain identical to the pre-change capture),
/// `gpCastIronRecipeFeasibleTurns` unchanged (gp5 = 53, gp1 = 48), and
/// `gpCastIronProductionAssignedTurns` **stays 0 for every GP**. The staging
/// path is correct groundwork but does not yet fire for gp5 on this seed: the
/// binding constraint sits one stage deeper than "castIron absent from the
/// boosted set" — either gp5's `timber` / `iron` is held without owning a
/// resource tile on the feasible turns (so the tile-ownership gate stays shut),
/// or the materially-feasible turns (`stockpileAffordsAnyProductionRecipe`,
/// material-only) are not **labour**-feasible (`feasibleRuns` is labour-capped)
/// once mandatory food production consumes the seller's small effective labour.
///
/// **Re-pointed next slice:** localize which of the two holds for gp5 — add a
/// read-only counter splitting `castIronRecipeFeasibleTurns` (material) into
/// labour-feasible vs labour-starved, and a counter for whether the seller owns
/// a `timber` / `iron` resource tile on the feasible turns. If tile-ownership
/// is the blocker, broaden the staging gate to fire on held feedstock (and move
/// the gate-inactive co-availability negative controls accordingly); if labour
/// is the blocker, the lever moves to effective-labour / food-reservation, not
/// the production boost. Verify by confirming `gpCastIronProductionAssignedTurns`
/// rises above 0 for gp5 before expecting OW gain to move; the +6 baseline
/// (gp1 / gp2) stays unaffected by construction (regiment-holding gate).
///
/// ## S7-D refresh (captured 2026-06-06 — castIron production-allocation fork
///     resolved, Refs #2847, PR #3289 follow-up)
///
/// This slice lands the two read-only counters the prior refresh re-pointed and
/// re-runs the diagnostic. The fork **resolves decisively to labour**, not tile
/// ownership:
///
///   * `gpCastIronRecipeFeasibleTurns` (material-only): gp1 = 48, gp5 = 53,
///     0 for every other GP — unchanged.
///   * `gpCastIronFeasibleOwnsFeedstockTileTurns`: gp1 = 48, gp5 = 53 — **equal
///     to the material-feasible count**, so on **every** castIron
///     material-feasible turn the seller still owns a `timber` / `iron` resource
///     tile. The staging gate's `_ownsFeedstockResourceTile` precondition is
///     therefore **satisfied**; tile ownership is **not** the blocker, and
///     broadening the staging gate to fire on held feedstock would not help.
///   * `gpCastIronRecipeLabourFeasibleTurns`: **0 for every GP**, including
///     gp5's 53 material-feasible turns. The castIron recipe
///     (`labourPerOutput == 5`) is **never** labour-feasible against the
///     seller's full `effectiveLabourForWorkers` — its effective labour, after
///     mandatory food upkeep, never funds even one run. This is exactly the
///     "labour-capped `feasibleRuns`" branch the prior refresh hypothesised.
///   * `gpCastIronProductionAssignedTurns` stays 0 for every GP, now explained:
///     the recipe is materially feasible and tile-backed but labour-starved, so
///     the planner's own `feasibleRuns` gate never clears.
///   * The +6 baseline is preserved (gp1 / gp2 **+6** PASS); the failing-GP gate
///     is unchanged in kind by this read-only slice.
///
/// **Re-pointed next slice (supersedes the tile-ownership fork):** the binding
/// constraint for the lock-recovery seller's first domestic `castIron` run is
/// **effective labour**, not feedstock supply, tile ownership, or the staging
/// boost. The next *behaviour* slice must give a below-quota zero-NW
/// zero-regiment lock-recovery seller enough spare labour to fund one
/// `castIron` run on a materially-feasible turn — e.g. reserving / freeing
/// effective labour from lower-priority recipes (or a food-reservation that
/// leaves a `labourPerOutput`-sized slice) under the same self-clearing
/// lock-recovery-seller gate that keeps the +6 baseline GPs (gp1 / gp2,
/// regiment-holding) out by construction. Verify by confirming
/// `gpCastIronRecipeLabourFeasibleTurns` then `gpCastIronProductionAssignedTurns`
/// rise above 0 for gp5 before expecting OW gain to move. Broadening the staging
/// gate or adding feedstock supply is explicitly **not** the lever (both are
/// already satisfied on the feasible turns). This slice is read-only diagnostic
/// instrumentation (no behaviour change, no config constants, no gate-threshold
/// changes; positive + negative unit tests for the two helpers in
/// `seed42_s7d_feedstock_helpers_test.dart`).
///
/// ## S7-D refresh (captured 2026-06-06 — castIron labour-starvation sub-cause
///     fork resolved: population-bound, not food-starved; Refs #2847)
///
/// The prior refresh re-pointed the behaviour lever to "effective labour" but
/// left the *sub-cause* open: is the labour shortfall a **food** problem
/// (workers exist but too few are fed) or a **population** problem (too few
/// workers even if all fed)? Its hypothesised lever — "reserve / free effective
/// labour from lower-priority recipes, or a food-reservation" — assumed the
/// former. This slice adds two read-only counters
/// (`gpCastIronLabourFoodStarvedTurns` vs `gpCastIronLabourPopulationBoundTurns`,
/// a partition of the material-feasible-but-labour-infeasible turns, forked on
/// whether the food-ungated ceiling `playerRawLabourSupply` would itself fund one
/// `castIron` run of `castIronMinLabourPerOutput == 5`) plus a turn-99
/// effective-labour / raw-supply / food-on-hand snapshot. The fork resolves
/// **decisively to population**, and **falsifies the food hypothesis**:
///
///   * `gpCastIronLabourFoodStarvedTurns` = **0 for every GP** — on no
///     material-feasible turn would feeding more workers reach one run.
///   * `gpCastIronLabourPopulationBoundTurns` = gp1 = 48, gp5 = 53 (**equal to
///     the full material-feasible count**) — on *every* such turn the seller's
///     fully-fed labour ceiling is itself below `labourPerOutput == 5`.
///   * Turn-99 snapshot: every GP has `effectiveLabour == rawLabourSupply`
///     (so **all** workers are already fed — food is not gating labour) while
///     that ceiling is tiny: gp5 = **1**, gp1 / gp2 / gp3 / gp4 = **2**, far
///     below 5. Food on hand is simultaneously **abundant** (gp5 = 289,
///     gp3 = 203, gp6 = 193), confirming the seller is drowning in food yet
///     starved of *workers*, not food.
///
/// **Re-pointed next slice (supersedes the food-reservation hypothesis):** the
/// binding constraint is the lock-recovery seller's **worker population**, not
/// food supply, feedstock, tile ownership, or recipe competition. A below-quota
/// zero-NW zero-regiment seller holds only ~1-2 total labour against the
/// `castIron` recipe's 5, with surplus food and idle feedstock — so neither
/// freeing labour from other recipes (there is almost none to free) nor a
/// food-reservation (food is not the gate) can ever clear `feasibleRuns > 0`.
/// The next *behaviour* slice must grow the seller's labour pool — e.g. convert
/// the abundant food into worker growth / peasant recruitment for the same
/// self-clearing lock-recovery-seller cohort — until the fully-fed ceiling
/// reaches `castIronMinLabourPerOutput`, gated to exclude the regiment-holding
/// +6 baseline GPs (gp1 / gp2) by construction. Verify by confirming
/// `gpCastIronLabourPopulationBoundTurns` falls as `rawLabourSupply` rises past
/// 5, then `gpCastIronRecipeLabourFeasibleTurns` and
/// `gpCastIronProductionAssignedTurns` rise above 0 for gp5. This slice is
/// read-only diagnostic instrumentation (no behaviour change, no config
/// constants, no gate-threshold changes; positive + negative unit tests for the
/// three helpers `playerEffectiveLabour` / `playerRawLabourSupply` /
/// `playerFoodOnHand` in `seed42_s7d_feedstock_helpers_test.dart`).
///
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
      Map<String, int> zeroPerGp() => {for (final gpId in gpIds) gpId: 0};
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
      final treasuryUnderCheapestTurns = zeroPerGp();
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
      final regimentTurnsAtZero = zeroPerGp();
      final treasuryAtOrAboveCheapestTurns = zeroPerGp();
      final militaryBuildOrdersEmitted = zeroPerGp();

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
      final fabricInStockpileTurns = zeroPerGp();
      final rebuildReadyTurns = zeroPerGp();
      final rebuildReadyNoBuildTurns = zeroPerGp();
      final rebuildReadyNoBuildMissingInputTurns = zeroPerGp();
      final rebuildReadyNoBuildInputsPresentTurns = zeroPerGp();
      // Cheapest-regiment input commodity ids (e.g. fabric) and the bid /
      // fill counters that prove whether the #3226 lock-recovery build-input
      // bid carve-out actually secures the input from the world market. A
      // high bid count with a near-zero fill count localizes the gap to
      // world-market *supply* (no seller / no production feedstock) rather
      // than the planner failing to bid.
      final regimentInputCommodityIds = cheapestRegimentInputs.keys.toSet();
      final regimentInputBidsEmitted = zeroPerGp();
      final regimentInputDealsAsBuyer = zeroPerGp();

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
      final improvementInputOffersEmitted = zeroPerGpCounter(gpIds);
      final improvementInputBidsEmitted = zeroPerGpCounter(gpIds);
      final improvementInputDealsAsBuyer = zeroPerGpCounter(gpIds);
      final improvementInputHeldAtTurn99 = zeroPerGpCounter(gpIds);

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
      final castIronRecipes = <ProductionRecipe>[
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
      final fabricRecipeIds = <String>{
        ProductionRecipesCatalog.fabricFromWool.id,
        ProductionRecipesCatalog.fabricFromCotton.id,
      };
      final fabricProductionAssignedTurns = zeroPerGpCounter(gpIds);
      final castIronFeedstockBidsEmitted = zeroPerGpCounter(gpIds);
      final castIronFeedstockOffersEmitted = zeroPerGpCounter(gpIds);
      final castIronFeedstockDealsAsBuyer = zeroPerGpCounter(gpIds);
      final castIronProductionAssignedTurns = zeroPerGpCounter(gpIds);
      final lumberHeldAtTurn99 = zeroPerGpCounter(gpIds);
      final castIronHeldAtTurn99 = zeroPerGpCounter(gpIds);
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

      // Refs #2847 H8-extraction Old World mineral feedstock prospect
      // localization (post-#3257 reservation). The reservation holds back an
      // idle Builder/Explorer for Old World feedstock work, yet
      // `gpCastIronFeedstockHeldAtTurn99` still shows `iron == 0` for every
      // supplier (`iron` is never extracted) while surface `timber` is. A
      // mineral `build_improvement` is rejected until the tile is prospected
      // (`work_order_target_prechecks.dart`), and only an **idle** Explorer is
      // reservable, so these two counters split the residual `iron` break,
      // captured while the supplier castIron gate is active:
      //
      //   * `supplierIdleExplorerPresentTurns` — the supplier owns an idle
      //     Explorer this turn (a unit the reservation could route onto the
      //     `iron` prospect). A near-zero count localizes the break to
      //     **Explorer availability** (all Explorers busy / dispatched to
      //     multi-turn New World exploration, so the reservation never has an
      //     idle Explorer to hold).
      //   * `supplierProspectedMineralFeedstockTileTurns` — the supplier owns a
      //     **prospected** Old World `iron` mineral feedstock tile. A non-zero
      //     count alongside `iron` held == 0 instead localizes the break
      //     **downstream** of prospecting (the Builder never improves the
      //     prospected tile / cannot afford the improvement); a flat zero
      //     confirms the prospect itself never happens.
      //   * `supplierIdleExplorerColocatedFeedstockTileTurns` — the supplier
      //     owns an idle Explorer standing **in the same province** as an
      //     unprospected Old World `iron` mineral feedstock tile. `prospect`
      //     candidate generation only reaches an Explorer positioned on (or
      //     single-hop from) the feedstock province, and the reservation holds
      //     the lexicographically-smallest idle Explorer **without
      //     repositioning it**. A flat zero alongside
      //     `supplierIdleExplorerPresentTurns > 0` localizes the residual to
      //     reservation **positioning** (no idle Explorer ever reaches the
      //     feedstock province, so no `prospect` candidate generates); a
      //     non-zero count instead points at candidate-generation eligibility
      //     (mineral-tile gate / validator) or selection ranking for an
      //     already-positioned Explorer.
      //   * `supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns` —
      //     the supplier owns an idle Explorer co-located with an unprospected
      //     Old World `iron` mineral feedstock tile that **also** passes the
      //     live mineral-eligibility terrain check (`isMineralEligibleTile`
      //     under the seed-42 `tileMapByRegion`). This is the next gate the
      //     `prospect` candidate must clear in
      //     `_allAcceptedProspectTilesInProvince`. Comparing it against
      //     `supplierIdleExplorerColocatedFeedstockTileTurns` splits the
      //     residual finer: a flat zero here while the resource-only co-located
      //     count is non-zero localizes the break to **terrain
      //     mineral-eligibility** at candidate generation (the owned `iron`
      //     tile sits on non-prospectable terrain); equal non-zero counts
      //     instead point **downstream** of eligibility (validator material
      //     cost / visibility precheck or selection ranking).
      //   * `supplierIdleExplorerColocatedSuggestedProspectTileTurns` — the
      //     **real** `suggestWorkOrders` pass actually emits a `prospect`
      //     candidate for the co-located mineral-eligible feedstock tile. This
      //     is the next gate past terrain eligibility: it runs the live
      //     generation pass (province visibility, move-leg validation, and the
      //     incremental-validator material-cost / visibility precheck all live
      //     inside it) rather than re-deriving one gate. Comparing it against
      //     `supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns`
      //     resolves the final fork: a non-zero count proves the prospect is
      //     generated + validator-accepted, so the residual is **selection
      //     ranking** (the accepted `prospect` loses to a competing `explore`
      //     in `selectFullAiCivilianWorkOrders`); a flat zero while the
      //     mineral-eligible count is non-zero localizes the residual **inside
      //     generation** (the visibility / move-leg / validator gates), not
      //     ranking.
      //
      // Read-only; the (freely tunable) counts can move as later slices land.
      final supplierIdleExplorerPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final supplierProspectedMineralFeedstockTileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final supplierIdleExplorerColocatedFeedstockTileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedSuggestedProspectTileTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      final supplierIdleExplorerColocatedFeedstockProspectValidatorTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};

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
      // Refs #2847 § S7-D castIron-feedstock order-matching off-critical path
      // (read-only). Affluent suppliers now *offer* `timber` / `iron`
      // (`gpCastIronFeedstockOffersEmitted` non-zero — supplier feedstock
      // extraction landed), yet a below-quota zero-NW lock-recovery seller's
      // castIron-feedstock bids still fill 0 deals
      // (`gpCastIronFeedstockDealsAsBuyer == 0`, a `timber` / `iron` offer-tier
      // mismatch). This counter records the feedstock-extraction-gate-active
      // turns on which the seller's fully-fed raw labour ceiling is below the
      // castIron `labourPerOutput`, so even a *fully filled* feedstock bid could
      // not yield a labour-feasible domestic castIron run. A count equal to
      // `gpFeedstockExtractionGateActiveTurns` proves the order-matching gap is
      // **off the critical path** — closing it (offer-tier alignment / supplier
      // release) cannot move the gate while the seller stays population-bound —
      // and re-points the next behaviour lever to worker-population growth.
      // Generalises `gpCastIronLabourPopulationBoundTurns` (measured only on
      // castIron material-feasible turns, which gp3 never reaches) to the gate
      // turns where the seller is still bidding the feedstock. Read-only; the
      // (freely tunable) counts can move as later slices land.
      final castIronFeedstockExtractionLabourFutileTurns = <String, int>{
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
      // Refs #2847 § S7-D fabric circular-labour localization (read-only). The
      // #3303/#3315 castIron-labour peasant-recruit boost stages domestic
      // `fabric` so a lock-recovery seller can pay the 2-`fabric` peasant
      // recruit that would grow its castIron labour. The post-#3315 refresh
      // shows the recruit gate fires for gp5 (8 turns) yet is fabric-starved on
      // every one (`gpCastIronLabourPeasantRecruitAffordableTurns == 0`), while
      // `gpFabricRecipeFeasibleTurns` (material-only) is high (gp5 47) but
      // `gpFabricProductionAssignedTurns` is ~2. This counter splits the
      // material-feasible fabric turns by the planner's own labour gate
      // (`feasibleRuns(...) > 0` against full `effectiveLabourForWorkers`,
      // mirroring `gpCastIronRecipeLabourFeasibleTurns`). A near-zero count
      // while the material count is high localizes the unbuilt recruit-fabric
      // to **labour starvation of the fabric recipe itself** (`fabric_from_*`
      // carries `labourPerOutput == 2`, above the seller's effective labour of
      // 1), i.e. the recruit boost is a circular deadlock — the next lever must
      // grow raw population by a non-`fabric` path, not stage more domestic
      // fabric. Read-only; the (freely tunable) counts can move as later slices
      // land.
      final fabricRecipeLabourFeasibleTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8 castIron production-assignment localization (read-only).
      // The castIron recipe `castIron_from_timber_iron_coal` consumes only
      // `timber` + `iron` (no coal in `inputQuantities`), so it is materially
      // feasible whenever both feedstocks are on hand. This counter (built on
      // `stockpileAffordsAnyProductionRecipe`) splits a flat
      // `gpCastIronProductionAssignedTurns == 0` into "never materially
      // feasible" (a feedstock-supply gap) vs "feasible yet never assigned" (a
      // production-allocation / planner gate downstream of supply).
      final castIronRecipeFeasibleTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8 castIron production-allocation localization (read-only;
      // S7-D castIron production-assignment, PR #3289 follow-up). The staging
      // path landed in #3289 still leaves `gpCastIronProductionAssignedTurns`
      // flat zero for every GP, including gp5 which is materially feasible for
      // ~53 turns (`gpCastIronRecipeFeasibleTurns`). Two read-only counters
      // split that flat residual on the material-feasible turns:
      //   * `castIronRecipeLabourFeasibleTurns` — the castIron recipe also
      //     clears the planner's own labour gate (`feasibleRuns(...) > 0`
      //     against the full `effectiveLabourForWorkers`, the same compute
      //     `economy_planner.dart` § `_allocateLabour` runs). A near-zero count
      //     here while `gpCastIronRecipeFeasibleTurns` is high localizes the
      //     break to **labour starvation** (effective labour, after mandatory
      //     food upkeep, cannot fund even one `labourPerOutput` run), moving the
      //     lever to effective-labour / food-reservation; a count close to the
      //     material-feasible count instead clears raw labour as the cause and
      //     re-points downstream to allocation competition / the staging gate.
      //   * `castIronFeasibleOwnsFeedstockTileTurns` — the seller still owns a
      //     `timber` / `iron` feedstock resource tile at any improvement level
      //     (the staging gate's `_ownsFeedstockResourceTile` precondition). A
      //     flat zero here while the seller *holds* `timber` / `iron`
      //     commodities localizes the unfired staging gate to **tile
      //     ownership** (feedstock accumulated but no resource tile owned),
      //     re-pointing the next behaviour slice to broaden the gate to fire on
      //     held feedstock; a non-zero count clears tile ownership as the cause.
      // Read-only; the (freely tunable) counts can move as later slices land.
      final castIronRecipeLabourFeasibleTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronFeasibleOwnsFeedstockTileTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8 castIron labour-starvation sub-cause split (read-only).
      // `gpCastIronRecipeLabourFeasibleTurns == 0` while
      // `gpCastIronRecipeFeasibleTurns` / `gpCastIronFeasibleOwnsFeedstockTile
      // Turns` are high decisively localized the binding constraint to
      // effective labour (the seller can never fund one `castIron`
      // `labourPerOutput` run after mandatory food upkeep). These two counters
      // fork *why* effective labour falls short on those material-feasible
      // turns so the next behaviour slice can pick the correct lever:
      //   * `castIronLabourFoodStarvedTurns` — the raw (food-ungated) labour
      //     ceiling (`playerRawLabourSupply`) **would** fund one run if every
      //     worker were fed, but `playerEffectiveLabour` does not: workers exist
      //     yet too few are food-fed. Lever: food supply / food-reservation.
      //   * `castIronLabourPopulationBoundTurns` — even the fully-fed ceiling is
      //     below one run's `labourPerOutput`: the seller simply lacks workers.
      //     Lever: worker growth / recruitment, not food.
      // Counted only on castIron material-feasible but labour-infeasible turns,
      // so the two are a partition of (recipeFeasible AND NOT labourFeasible).
      // Read-only; the (freely tunable) counts can move as later slices land.
      final castIronLabourFoodStarvedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPopulationBoundTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 — peasant-recruit effectiveness localization for the
      // #3303 castIron-labour boost. #3303 wired an EXPAND orchestrator pass
      // that emits one peasant `RecruitWorkerOrder` whenever
      // `isCastIronLabourPopulationBoundForLockRecoverySeller` holds (the
      // lock-recovery seller is material-feasible for one castIron run yet its
      // raw population ceiling supplies < `labourPerOutput` labour). The S7-D
      // refresh after #3303 shows `gpCastIronRecipeLabourFeasibleTurns` is
      // STILL 0 for every GP, i.e. the boost never makes a castIron run
      // labour-feasible. These counters localize *why* by measuring, per GP:
      //   * `castIronLabourPeasantRecruitGateTurns` — turns the #3303 gate
      //     predicate itself holds (the boost's distinguishing condition);
      //   * `castIronLabourPeasantRecruitAffordableTurns` — of those, turns the
      //     seller can actually pay the peasant recruit cost row
      //     (`WorkerActionEconomyCatalog.peasant`, which costs 2 `fabric`);
      //   * `castIronLabourPeasantRecruitFabricStarvedTurns` — of those, turns
      //     it CANNOT (the suspected circular dependency: recruiting the
      //     peasant that would grow castIron labour itself needs `fabric`, the
      //     very downstream commodity the castIron chain exists to unblock).
      // If FabricStarved == GateTurns the #3303 boost is a structural no-op:
      // every gate-active turn it probes a peasant recruit the validator must
      // reject for want of fabric. Read-only; counts move freely as later
      // slices land.
      final castIronLabourPeasantRecruitGateTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitAffordableTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitFabricStarvedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 § S7-D market-fabric localization (post-#3317 re-point). Of
      // the fabric-starved peasant-recruit turns above, the subset where NO
      // other great power holds any `fabric` either — so the seller can
      // neither *produce* the 2-`fabric` recruit cost (the #3317
      // circular-labour deadlock: `fabric_from_*` needs 2 labour, the seller
      // has 1) NOR *buy* it from the world market. The peasant recruit is the
      // only raw-population-growth row in `WorkerActionEconomyCatalog`
      // (apprentice/journeyman/master consume an existing peasant), and it is
      // `fabric`-gated, so there is no non-`fabric` worker-action lever. When
      // this counter equals `castIronLabourPeasantRecruitFabricStarvedTurns`,
      // the market door is closed on every fabric-starved turn too, which
      // re-points the next slice off "find a non-`fabric` recruit row" (none
      // exists) and onto a rules-level bootstrap. Read-only; counts move
      // freely as later slices land.
      final castIronLabourPeasantRecruitMarketFabricStarvedTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      // Refs #2847 § S7-D market-fabric offer/acquisition localization: the
      // complementary subset of the fabric-starved turns where other great
      // powers DO hold `fabric` (so this is not market-starved) yet none of it
      // is offerable — every holder is itself a below-quota zero-NW zero-
      // regiment lock-recovery seller withholding its `fabric` by the regiment-
      // rebuild offer-retention carve-out (`otherGreatPowerOfferableFabricHeld
      // <= 0` while `otherGreatPowerFabricHeld > 0`). A high count here forks
      // the residual onto the offer/retention layer (no counterparty offers
      // `fabric`); a low count with holdings present instead re-points it to the
      // starved seller's own buy/bid path. Read-only; counts move freely as
      // later slices land.
      final castIronLabourPeasantRecruitMarketFabricUnofferedTurns =
          <String, int>{for (final gpId in gpIds) gpId: 0};
      // Refs #2847 § S7-D buyer-side fabric acquisition localization: on
      // fabric-starved peasant-recruit turns where offerable `fabric` exists
      // (`otherGreatPowerOfferableFabricHeld > 0`), whether the starved seller
      // emits a `fabric` bid and whether a deal fills as buyer. Read-only;
      // counts move freely as later slices land.
      final castIronLabourPeasantRecruitFabricBidEmittedTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitFabricBidAbsentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronLabourPeasantRecruitFabricDealAsBuyerTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 § castIron market-supply wall: on feedstock-extraction
      // gate-active turns, whether any *other* faction offered `castIron` (the
      // manufactured level-0 `build_improvement` input) on the world market —
      // i.e. whether the seller's direct-acquisition branch had any supply to
      // bid against. A flat-zero present count across the run proves the
      // direct castIron purchase path is permanently closed (every GP consumes
      // its castIron for Old World military builds), leaving only the
      // labour-walled domestic run. Read-only; counts move freely as later
      // supply slices land.
      final castIronMarketOfferPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final castIronMarketOfferAbsentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 § fabric offer-side split: on peasant-recruit fabric market
      // path-active turns, whether any *other* faction emitted a `fabric` sell
      // offer in trade orders (the trade-order emission layer between
      // offerable-holdings proxy and buyer-side bid/deal counters).
      final fabricMarketOfferPresentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final fabricMarketOfferAbsentTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Minimum `labourPerOutput` across the castIron recipes — the cheapest
      // single run's effective-labour requirement, used as the food-starved /
      // population-bound fork threshold above.
      final castIronMinLabourPerOutput = castIronRecipes.isEmpty
          ? 0
          : castIronRecipes
                .map((recipe) => recipe.labourPerOutput)
                .reduce((a, b) => a < b ? a : b);
      // Food commodities (grain + meat) consumed by worker upkeep
      // (`economy_consumption.dart`), summed for the turn-99 food-on-hand
      // snapshot that corroborates the food-starved lever.
      final castIronLabourFoodCommodityIds = <String>{
        CommodityCatalog.grain.id,
        CommodityCatalog.meat.id,
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
      // Refs #2847 H8-extraction affordability localization: the level-0
      // `build_improvement` cost is purely material (1 lumber + 1 cast iron,
      // `work_order_costs.dart`) — no treasury or recipe gate. When the
      // combined `gpFeedstockGateImprovementCostAffordableTurns` stays flat at
      // zero, these per-component counters split it into its proximate
      // shortfall: how many gate-active turns the GP holds the `lumber` share
      // vs the `castIron` share. Pins the binding missing material during the
      // gate window (not just at the turn-99 snapshot) so the next slice can
      // target lumber supply, castIron supply, or both. Read-only.
      final improvementLumberId = CommodityCatalog.lumber.id;
      final improvementCastIronId = CommodityCatalog.castIron.id;
      final feedstockGateImprovementLumberAffordableTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockGateImprovementCastIronAffordableTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      // Refs #2847 H8-extraction acquisition-thread localization (read-only).
      // Post-#3274 the seller feedstock-tile acquisition thread (declare-war
      // target bias #3273 + conquest army-move target bias #3274) drives a
      // flagged below-quota zero-NW lock-recovery seller toward the Old World
      // feedstock province it must conquer when it owns no extractable feedstock
      // tile of its own. These split *why* a flagged seller that still owns 0
      // improved feedstock tiles (e.g. gp3) never completes the acquisition into
      // its proximate stage:
      //   * `feedstockAcquisitionTargetActiveTurns` —
      //     `expandSellerFeedstockTileAcquisitionTarget(game, snap)` returns a
      //     non-null conquest-reachable Old World feedstock province this turn,
      //     so the acquisition thread engages. Zero here localizes the residual
      //     upstream of the declare-war / army-move bias to "no conquest-
      //     reachable feedstock target" (the needed feedstock province is never
      //     invadable) — the bias has nothing to redirect.
      //   * `feedstockAcquisitionTargetWithFieldArmyTurns` — subset of the above
      //     where the GP also owns at least one non-home field army able to
      //     execute the march. Near-zero here with a positive active count
      //     localizes the residual to "target reachable but no field army to
      //     march it" (peer-war regiment attrition); a high count alongside a
      //     flat `gpFeedstockGateImprovedTileOwnedTurns` re-points the break to
      //     march/capture completion downstream of the army-move bias. Both stay
      //     0 by construction for the +6 baseline GPs gp1/gp2 (never flagged, so
      //     the acquisition target is always null).
      final feedstockAcquisitionTargetActiveTurns = <String, int>{
        for (final gpId in gpIds) gpId: 0,
      };
      final feedstockAcquisitionTargetWithFieldArmyTurns = <String, int>{
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
        final fabricStarvedThisTurn = <String>{};
        // Refs #2847 § fabric offer-side split: GPs whose castIron-labour
        // peasant-recruit fabric market path is active this turn.
        final fabricMarketPathActiveThisTurn = <String>{};
        // Refs #2847 § castIron market-supply wall: GPs whose feedstock-
        // extraction gate is active this turn, scanned post-merge for castIron
        // market-offer presence/absence.
        final feedstockGateActiveThisTurn = <String>{};
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
            feedstockGateActiveThisTurn.add(gpId);
            feedstockExtractionGateActiveTurns[gpId] =
                (feedstockExtractionGateActiveTurns[gpId] ?? 0) + 1;
            // Refs #2847 H8-extraction execution-gap disambiguation: split the
            // gate-active turns by Builder availability and improvement
            // completion so the next slice can target the exact stage.
            if (hasIdleBuilderUnit(game, gpId)) {
              feedstockGateIdleBuilderPresentTurns[gpId] =
                  (feedstockGateIdleBuilderPresentTurns[gpId] ?? 0) + 1;
            }
            if (ownsImprovedFeedstockResourceTile(
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
            if (hasValidBuildImprovementOnUnimprovedFeedstockTile(
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
            if (affordsBuildImprovementLevelZero(game, gpId)) {
              feedstockGateImprovementCostAffordableTurns[gpId] =
                  (feedstockGateImprovementCostAffordableTurns[gpId] ?? 0) + 1;
            }
            // Per-component split of the combined affordability gate above:
            // pins which material (lumber / castIron) binds on gate-active
            // turns. Refs #2847 H8-extraction.
            if (affordsBuildImprovementComponent(
              game,
              gpId,
              improvementLumberId,
            )) {
              feedstockGateImprovementLumberAffordableTurns[gpId] =
                  (feedstockGateImprovementLumberAffordableTurns[gpId] ?? 0) +
                  1;
            }
            if (affordsBuildImprovementComponent(
              game,
              gpId,
              improvementCastIronId,
            )) {
              feedstockGateImprovementCastIronAffordableTurns[gpId] =
                  (feedstockGateImprovementCastIronAffordableTurns[gpId] ?? 0) +
                  1;
            }
            // Refs #2847 § S7-D castIron-feedstock order-matching off-critical
            // path: on a gate-active turn whose fully-fed raw labour ceiling is
            // below the castIron `labourPerOutput`, even a fully-filled
            // `timber` / `iron` feedstock bid could not yield a labour-feasible
            // domestic castIron run, so the order-matching gap is not on the
            // critical path — the binding constraint stays worker population.
            if (castIronFeedstockExtractionLabourFutile(
              game,
              gpId,
              castIronMinLabourPerOutput,
            )) {
              castIronFeedstockExtractionLabourFutileTurns[gpId] =
                  (castIronFeedstockExtractionLabourFutileTurns[gpId] ?? 0) + 1;
            }
          }
          if (ownsUnimprovedFeedstockResourceTile(
            game,
            gpId,
            fabricFeedstockIds,
          )) {
            unimprovedFeedstockTileOwnedTurns[gpId] =
                (unimprovedFeedstockTileOwnedTurns[gpId] ?? 0) + 1;
          }
          // Refs #2847 H8-extraction acquisition-thread localization
          // (read-only). Records whether the post-#3274 seller feedstock-tile
          // acquisition thread engages for this GP this turn (a non-null
          // conquest-reachable feedstock target) and, when it does, whether a
          // non-home field army is available to execute the conquest march.
          // `expandSellerFeedstockTileAcquisitionTarget` returns null for every
          // player whose acquisition residual is inactive, so gp1/gp2 stay 0.
          final acquisitionTarget = expandSellerFeedstockTileAcquisitionTarget(
            game: game,
            snapshot: snap,
          );
          if (acquisitionTarget != null) {
            feedstockAcquisitionTargetActiveTurns[gpId] =
                (feedstockAcquisitionTargetActiveTurns[gpId] ?? 0) + 1;
            if (hasFieldArmy(game, gpId)) {
              feedstockAcquisitionTargetWithFieldArmyTurns[gpId] =
                  (feedstockAcquisitionTargetWithFieldArmyTurns[gpId] ?? 0) + 1;
            }
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
              if (ownsUnimprovedFeedstockResourceTile(game, gpId, {
                feedstockId,
              })) {
                feedstockTiles[feedstockId] =
                    (feedstockTiles[feedstockId] ?? 0) + 1;
              }
            }
            // Refs #2847 H8-extraction prospect localization: split the
            // never-extracted `iron` residual into Explorer availability vs a
            // downstream (prospect-done / improvement) break.
            if (hasIdleExplorerUnit(game, gpId)) {
              supplierIdleExplorerPresentTurns[gpId] =
                  (supplierIdleExplorerPresentTurns[gpId] ?? 0) + 1;
            }
            if (ownsProspectedOldWorldMineralFeedstockTile(
              game,
              gpId,
              castIronFeedstockIds,
            )) {
              supplierProspectedMineralFeedstockTileTurns[gpId] =
                  (supplierProspectedMineralFeedstockTileTurns[gpId] ?? 0) + 1;
            }
            if (ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
              game,
              gpId,
              castIronFeedstockIds,
            )) {
              supplierIdleExplorerColocatedFeedstockTileTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockTileTurns[gpId] ?? 0) +
                  1;
            }
            if (ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
              game,
              gpId,
              castIronFeedstockIds,
              tileMap,
            )) {
              supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns[gpId] =
                  (supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns[gpId] ??
                      0) +
                  1;
            }
            if (suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile(
              game,
              topo,
              view,
              gpId,
              castIronFeedstockIds,
              tileMap,
            )) {
              supplierIdleExplorerColocatedSuggestedProspectTileTurns[gpId] =
                  (supplierIdleExplorerColocatedSuggestedProspectTileTurns[gpId] ??
                      0) +
                  1;
            }
            final intraPassGates =
                colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates(
                  game: game,
                  topology: topo,
                  view: view,
                  playerId: gpId,
                  feedstockIds: castIronFeedstockIds,
                  tileMapByRegion: tileMap,
                );
            if (intraPassGates.provinceFoggedVisibility) {
              supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns[gpId] ??
                      0) +
                  1;
            }
            if (intraPassGates.bundledMoveLeg) {
              supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns[gpId] ??
                      0) +
                  1;
            }
            if (intraPassGates.validatorAccepted) {
              supplierIdleExplorerColocatedFeedstockProspectValidatorTurns[gpId] =
                  (supplierIdleExplorerColocatedFeedstockProspectValidatorTurns[gpId] ??
                      0) +
                  1;
            }
          }
          if (player != null) {
            // Refs #2847 — per-turn castIron-labour stage localization. The
            // measure bundles the read-only flags (the #3303 peasant-recruit
            // gate + affordability, fabric feedstock/recipe feasibility, and
            // the castIron material/labour/food/tile fork); the caller only
            // applies counter bumps. The fabric-starved peasant-recruit subset
            // isolates the suspected circular dependency that renders the
            // #3303 boost a no-op.
            final ci = seed42S7dCastIronLabourTurnMeasure(
              game: game,
              playerId: gpId,
              fabricFeedstockIds: fabricFeedstockIds,
              fabricRecipes: fabricRecipes,
              castIronRecipes: castIronRecipes,
              castIronFeedstockIds: castIronFeedstockIds,
              castIronMinLabourPerOutput: castIronMinLabourPerOutput,
            );
            if (isCastIronLabourPeasantRecruitFabricMarketPathActive(
              game: game,
              playerId: gpId,
              projected: player.stockpile,
            )) {
              fabricMarketPathActiveThisTurn.add(gpId);
            }
            recordSeed42S7dCastIronLabourCounters(
              game: game,
              gpId: gpId,
              ci: ci,
              fabricStarvedThisTurn: fabricStarvedThisTurn,
              castIronLabourPeasantRecruitGateTurns:
                  castIronLabourPeasantRecruitGateTurns,
              castIronLabourPeasantRecruitAffordableTurns:
                  castIronLabourPeasantRecruitAffordableTurns,
              castIronLabourPeasantRecruitFabricStarvedTurns:
                  castIronLabourPeasantRecruitFabricStarvedTurns,
              castIronLabourPeasantRecruitMarketFabricStarvedTurns:
                  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
              castIronLabourPeasantRecruitMarketFabricUnofferedTurns:
                  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
              feedstockInStockpileTurns: feedstockInStockpileTurns,
              fabricRecipeFeasibleTurns: fabricRecipeFeasibleTurns,
              fabricRecipeLabourFeasibleTurns: fabricRecipeLabourFeasibleTurns,
              castIronRecipeFeasibleTurns: castIronRecipeFeasibleTurns,
              castIronRecipeLabourFeasibleTurns:
                  castIronRecipeLabourFeasibleTurns,
              castIronLabourFoodStarvedTurns: castIronLabourFoodStarvedTurns,
              castIronLabourPopulationBoundTurns:
                  castIronLabourPopulationBoundTurns,
              castIronFeasibleOwnsFeedstockTileTurns:
                  castIronFeasibleOwnsFeedstockTileTurns,
            );
          }
          // Cache the turn-99 snapshot fields for the final rollup.
          if (t == 99) {
            lastSnapshotFields[gpId] = seed42S7dTurn99SnapshotFields(
              game: game,
              playerId: gpId,
              snap: snap,
              foodCommodityIds: castIronLabourFoodCommodityIds,
            );
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
          if (plan != null &&
              plan.productionAssignments.any(
                (a) => fabricRecipeIds.contains(a.recipeId),
              )) {
            fabricProductionAssignedTurns[gpId] =
                (fabricProductionAssignedTurns[gpId] ?? 0) + 1;
          }
        }

        // Refs #2924 Step 0 — count submitted trade orders per GP
        // from the merged order list that the resolver will apply.
        // Carry-forward bids/offers re-injected by the world-market
        // phase are not counted here; this metric reflects what the
        // AI actively emits each turn.
        recordSeed42S7dTradeOrderCounters(
          gpIds: gpIds,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          regimentInputCommodityIds: regimentInputCommodityIds,
          improvementInputCommodityIds: improvementInputCommodityIds,
          castIronFeedstockIds: castIronFeedstockIds,
          tradeOfferCount: tradeOfferCount,
          tradeUrgentOfferCount: tradeUrgentOfferCount,
          tradeBidCount: tradeBidCount,
          improvementInputOffersEmitted: improvementInputOffersEmitted,
          castIronFeedstockOffersEmitted: castIronFeedstockOffersEmitted,
          regimentInputBidsEmitted: regimentInputBidsEmitted,
          improvementInputBidsEmitted: improvementInputBidsEmitted,
          castIronFeedstockBidsEmitted: castIronFeedstockBidsEmitted,
        );

        // Refs #2847 § S7-D buyer-side fabric acquisition: on fabric-starved
        // peasant-recruit turns with offerable counterparty supply, record
        // whether the seller emitted a `fabric` bid this turn.
        recordSeed42S7dFabricBidCounters(
          game: game,
          fabricStarvedThisTurn: fabricStarvedThisTurn,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          emittedTurns: castIronLabourPeasantRecruitFabricBidEmittedTurns,
          absentTurns: castIronLabourPeasantRecruitFabricBidAbsentTurns,
        );

        // Refs #2847 § fabric offer-side split: on peasant-recruit fabric
        // market-path-active turns, record whether any other faction offered
        // `fabric` in trade orders this turn.
        recordSeed42S7dFabricMarketOfferCounters(
          fabricMarketPathActiveThisTurn: fabricMarketPathActiveThisTurn,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          presentTurns: fabricMarketOfferPresentTurns,
          absentTurns: fabricMarketOfferAbsentTurns,
        );

        // Refs #2847 § castIron market-supply wall: on the feedstock-extraction
        // gate-active turns, record whether any other faction offered castIron
        // (the manufactured level-0 build_improvement input) this turn.
        recordSeed42S7dCastIronMarketOfferCounters(
          feedstockGateActiveThisTurn: feedstockGateActiveThisTurn,
          tradeOrdersByPlayerId: merged.tradeOrdersByPlayerId,
          castIronCommodityId:
              castIronProductionRecipe?.outputCommodityId ?? 'castIron',
          presentTurns: castIronMarketOfferPresentTurns,
          absentTurns: castIronMarketOfferAbsentTurns,
        );

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
              if (fabricStarvedThisTurn.contains(buyer) &&
                  deal.commodityId == 'fabric') {
                bumpCounter(
                  castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
                  buyer,
                );
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
        'gpFabricProductionAssignedTurns': fabricProductionAssignedTurns,
        'gpSupplierFeedstockExtractionGateActiveTurns':
            supplierFeedstockExtractionGateActiveTurns,
        'gpSupplierActiveUnimprovedCastIronFeedstockTileTurns':
            supplierActiveUnimprovedCastIronFeedstockTileTurns,
        'gpSupplierIdleExplorerPresentTurns': supplierIdleExplorerPresentTurns,
        'gpSupplierProspectedMineralFeedstockTileTurns':
            supplierProspectedMineralFeedstockTileTurns,
        'gpSupplierIdleExplorerColocatedFeedstockTileTurns':
            supplierIdleExplorerColocatedFeedstockTileTurns,
        'gpSupplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns':
            supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns,
        'gpSupplierIdleExplorerColocatedSuggestedProspectTileTurns':
            supplierIdleExplorerColocatedSuggestedProspectTileTurns,
        'gpSupplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns':
            supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns,
        'gpSupplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns':
            supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns,
        'gpSupplierIdleExplorerColocatedFeedstockProspectValidatorTurns':
            supplierIdleExplorerColocatedFeedstockProspectValidatorTurns,
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
        'gpFeedstockGateImprovementLumberAffordableTurns':
            feedstockGateImprovementLumberAffordableTurns,
        'gpFeedstockGateImprovementCastIronAffordableTurns':
            feedstockGateImprovementCastIronAffordableTurns,
        'gpFeedstockAcquisitionTargetActiveTurns':
            feedstockAcquisitionTargetActiveTurns,
        'gpFeedstockAcquisitionTargetWithFieldArmyTurns':
            feedstockAcquisitionTargetWithFieldArmyTurns,
        'gpFeedstockInStockpileTurns': feedstockInStockpileTurns,
        'gpFabricRecipeFeasibleTurns': fabricRecipeFeasibleTurns,
        'gpFabricRecipeLabourFeasibleTurns': fabricRecipeLabourFeasibleTurns,
        'gpCastIronRecipeFeasibleTurns': castIronRecipeFeasibleTurns,
        'gpCastIronRecipeLabourFeasibleTurns':
            castIronRecipeLabourFeasibleTurns,
        'gpCastIronFeasibleOwnsFeedstockTileTurns':
            castIronFeasibleOwnsFeedstockTileTurns,
        'gpCastIronLabourFoodStarvedTurns': castIronLabourFoodStarvedTurns,
        'gpCastIronLabourPopulationBoundTurns':
            castIronLabourPopulationBoundTurns,
        'gpCastIronLabourPeasantRecruitGateTurns':
            castIronLabourPeasantRecruitGateTurns,
        'gpCastIronLabourPeasantRecruitAffordableTurns':
            castIronLabourPeasantRecruitAffordableTurns,
        'gpCastIronLabourPeasantRecruitFabricStarvedTurns':
            castIronLabourPeasantRecruitFabricStarvedTurns,
        'gpCastIronLabourPeasantRecruitMarketFabricStarvedTurns':
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        'gpCastIronLabourPeasantRecruitMarketFabricUnofferedTurns':
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
        'gpCastIronLabourPeasantRecruitFabricBidEmittedTurns':
            castIronLabourPeasantRecruitFabricBidEmittedTurns,
        'gpCastIronLabourPeasantRecruitFabricBidAbsentTurns':
            castIronLabourPeasantRecruitFabricBidAbsentTurns,
        'gpCastIronLabourPeasantRecruitFabricDealAsBuyerTurns':
            castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
        'gpCastIronMarketOfferPresentTurns': castIronMarketOfferPresentTurns,
        'gpCastIronMarketOfferAbsentTurns': castIronMarketOfferAbsentTurns,
        'gpFabricMarketOfferPresentTurns': fabricMarketOfferPresentTurns,
        'gpFabricMarketOfferAbsentTurns': fabricMarketOfferAbsentTurns,
        'gpCastIronFeedstockExtractionLabourFutileTurns':
            castIronFeedstockExtractionLabourFutileTurns,
        'castIronMinLabourPerOutput': castIronMinLabourPerOutput,
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
      // in S7-T without churn here. The structural invariants over the
      // per-GP counter maps are asserted by the extracted support helper
      // (kept out of this file for the non-comment line-size budget).
      assertSeed42S7dStructuralInvariants(
        gpIds: gpIds,
        phaseCounts: phaseCounts,
        rebuildReadyNoBuildTurns: rebuildReadyNoBuildTurns,
        rebuildReadyNoBuildMissingInputTurns:
            rebuildReadyNoBuildMissingInputTurns,
        rebuildReadyNoBuildInputsPresentTurns:
            rebuildReadyNoBuildInputsPresentTurns,
        feedstockExtractionGateActiveTurns: feedstockExtractionGateActiveTurns,
        feedstockGateIdleBuilderPresentTurns:
            feedstockGateIdleBuilderPresentTurns,
        feedstockGateImprovedTileOwnedTurns:
            feedstockGateImprovedTileOwnedTurns,
        feedstockGateValidBuildImprovementCandidateTurns:
            feedstockGateValidBuildImprovementCandidateTurns,
        feedstockGateImprovementCostAffordableTurns:
            feedstockGateImprovementCostAffordableTurns,
        feedstockGateImprovementLumberAffordableTurns:
            feedstockGateImprovementLumberAffordableTurns,
        feedstockGateImprovementCastIronAffordableTurns:
            feedstockGateImprovementCastIronAffordableTurns,
        feedstockAcquisitionTargetActiveTurns:
            feedstockAcquisitionTargetActiveTurns,
        feedstockAcquisitionTargetWithFieldArmyTurns:
            feedstockAcquisitionTargetWithFieldArmyTurns,
        castIronLabourPeasantRecruitGateTurns:
            castIronLabourPeasantRecruitGateTurns,
        castIronLabourPeasantRecruitAffordableTurns:
            castIronLabourPeasantRecruitAffordableTurns,
        castIronLabourPeasantRecruitFabricStarvedTurns:
            castIronLabourPeasantRecruitFabricStarvedTurns,
        castIronLabourPeasantRecruitMarketFabricStarvedTurns:
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        castIronLabourPeasantRecruitMarketFabricUnofferedTurns:
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
        castIronLabourPeasantRecruitFabricBidEmittedTurns:
            castIronLabourPeasantRecruitFabricBidEmittedTurns,
        castIronLabourPeasantRecruitFabricBidAbsentTurns:
            castIronLabourPeasantRecruitFabricBidAbsentTurns,
        castIronLabourPeasantRecruitFabricDealAsBuyerTurns:
            castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
        fabricRecipeFeasibleTurns: fabricRecipeFeasibleTurns,
        fabricRecipeLabourFeasibleTurns: fabricRecipeLabourFeasibleTurns,
        castIronMarketOfferPresentTurns: castIronMarketOfferPresentTurns,
        castIronMarketOfferAbsentTurns: castIronMarketOfferAbsentTurns,
        castIronFeedstockExtractionLabourFutileTurns:
            castIronFeedstockExtractionLabourFutileTurns,
      );
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
