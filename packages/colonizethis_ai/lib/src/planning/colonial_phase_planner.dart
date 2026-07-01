/// COLONIAL-phase planner (Refs #2509 S3 / S10).
///
/// Phase planner module from the single-goal architecture in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. The planner is a
/// pure-function module that makes one primary decision per domain with no
/// cross-phase score aggregation.
///
/// COLONIAL phase goal: transfer every `newWorld|` province to GP ownership
/// using the fastest legal acquisition path (Join Empire, `purchase_land`,
/// or `declareWar` + invasion). Callers are expected to dispatch to this
/// module **only** when `observerGoalPhaseFor` resolves to
/// `ObserverGoalPhase.colonial`; the planner functions themselves do not
/// re-check the phase, matching the convention established by
/// `develop_phase_planner.dart` (Refs #2509 S4) and
/// `expand_phase_planner.dart` (Refs #2509 S2).
///
/// Orchestrator wiring (#2509 S5) is now in place: `phase_planner_dispatch.dart`
/// calls `planColonialPeace`, `planColonialAcquisition`,
/// `planColonialMilitary`, `planColonialNaval`, and `planColonialCivilian`
/// for every COLONIAL-phase player and threads the result through
/// `PhasePlanOutcome`; `domain_planner_orchestrator.dart` consumes the
/// outcome via `gpPeaceTargetsFromPhasePlan` /
/// `gpColonialDeclareWarTargetFromPhasePlan` /
/// `colonialMilitaryPlanFromPhasePlan` so COLONIAL domain decisions reach
/// the resolver without re-checking the phase. The legacy
/// `colonialPhaseGpPeaceTargets` helper still lives in
/// `observer_goal_phase.dart` because the no-`phasePlan` fallback path
/// through `collectStalledGreatPowerPeaceTargets` keeps it on the production
/// hot path alongside the EXPAND ratchet aggregator;
/// `colonial_pressure.dart` and `diplomacy_planner_peace_targets.dart` were
/// removed in #2509 S1, with their helpers canonical in the phase-planner
/// modules and in `observer_goal_phase.dart` for the cross-phase composite
/// peace aggregators. Both `colonialPhaseGpPeaceTargets` and
/// `planColonialPeace` are pinned at the function-unit level.
///
/// In-module contracts shipped to date (see issue #2509 § COLONIAL phase
/// planner for the full set):
///
///   `planColonialPeace(game, snapshot) → List<String>`
///     Returns the deterministic list of at-war Great Powers the active
///     player should `offerPeace` toward in COLONIAL. Defaults to peacing
///     **all** at-war GPs except the one identified by
///     [primaryColonialGpBlocker] (the GP owning the most invadable
///     `newWorld|` provinces -- the primary colonial NW frontier blocker).
///     The new spec text from issue #2509 § COLONIAL phase planner §
///     planColonialPeace is "Peace all at-war Great Powers, with ONE
///     exception: Keep fighting a GP that owns a province blocking the
///     primary colonial NW target". Tribe and minor at-war factions are
///     filtered out via [Game.playerById] returning `null` for non-player
///     ids -- COLONIAL diplomatic peace is GP-vs-GP only; tribe/minor
///     colonial wars are pursued through other phase-planner contracts
///     (`planColonialAcquisition` for `establishOverture` / Join Empire
///     / `purchase_land`, [planColonialMilitary] for NW conquest army
///     moves).
///
///   `planColonialAcquisition(game, snapshot) → ColonialAcquisitionTarget?`
///     Returns the deterministic acquisition target for the active
///     COLONIAL player when one is achievable this turn, or `null`
///     when no method is reachable. Iterates over
///     [ColonialSummary.invadableNewWorldProvinceIdsByDistance] (the
///     spec-mandated "sorted by adjacency distance to owned territory"
///     ordering, populated by the perception-snapshot builder via
///     [reachableNonOwnedProvinceDistancesViaSeas]) when topology was
///     available at snapshot build time, otherwise falls back to
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (lex
///     order) for synthetic fixtures built without a topology. The
///     planner tries methods in priority order:
///
///       1. **Join Empire** (Acquisition method 1) — first NW
///          province whose tribe/minor owner has an
///          [OvertureStage.nap] with the active player, Friendly+
///          relations, and treasury covering
///          [joinEmpireCostForMinorOrTribe]. The cheapest, fastest
///          path; always preferred first across all candidate
///          provinces.
///       2. **`purchase_land`** (Acquisition method 2) — only
///          considered when the Join Empire pass yielded no target.
///          Active player must hold at least one idle Merchant unit;
///          per-province gates mirror
///          `precheckPurchaseLand` in `work_order_target_prechecks.dart`
///          (tribe / minor owner, not at war, embassy with that
///          tribe / minor, plus at least one tile in the province
///          with a non-empty resource that is unprospected-mineral
///          safe, not already purchased, and whose
///          [purchaseLandCost] is within treasury).
///       3. **`declareWar`** (Acquisition method 3) — only considered
///          when both the Join Empire and `purchase_land` passes
///          yielded no target. Outer gates require the active player
///          to hold at least one standing regiment (so the spec's
///          "Generate declareWar(tribe) + NW army move" follow-up is
///          feasible) and treasury covering the cheapest regiment
///          build cost (mirrors the EXPAND declare-war planner's
///          `_cheapestRegimentBuildTreasuryCost` gate). Per-province
///          gates: owner is a tribe / minor (GPs structurally
///          excluded; same `game.playerById(ownerId) != null` skip as
///          the earlier passes); the active player is not already at
///          war with that owner (the order-engine
///          `declareWarSubValidator` rejects with "Already at war
///          with that faction" when [RelationState.atWar]). Sea
///          reachability is structurally satisfied because every
///          candidate appears in
///          [ColonialSummary.invadableNewWorldProvinceIdsSorted],
///          which the perception-snapshot builder restricts to
///          provinces reachable from owned anchors via
///          [reachableNonOwnedProvinceIdsViaSeas]. The structural
///          priority Method 1 → 2 → 3 implements the spec's
///          "deprioritize war behind Join Empire and purchase_land"
///          guidance — the cheaper paths always run first, so the
///          turn-110 inversion the spec calls out is a no-op for
///          today's planner.
///
///   `planColonialMilitary(game, snapshot,
///                         colonialDeclaredWarTargetFactionId)
///                                                 → ColonialMilitaryPlan`
///     Returns the deterministic NW-only conquest destination filter for
///     the active COLONIAL player. The plan carries the priority subset
///     of [ColonialSummary.invadableNewWorldProvinceIdsSorted] (always
///     NW by construction in the perception-snapshot builder) that
///     conquest army moves should target this turn: provinces owned by
///     the colonial declare-war target when one was chosen, otherwise
///     provinces owned by any at-war faction (tribe / minor / GP).
///     Returns [ColonialMilitaryPlan.defaultPlan] (no constraint) for
///     the outer COLONIAL guards (below quota, missing player, empty
///     NW invadable frontier) and for the priority arms that resolve
///     to an empty province set; the orchestrator (#2509 S5) treats
///     `defaultPlan` as "free choice within NW invadable" and a
///     non-default plan as "restrict NW conquest army moves to this
///     subset" (Refs #2509 § COLONIAL phase planner § planColonialMilitary
///     "Use runConquestArmyMovePlanner with NW destination filter").
///
///   `planColonialLiteOvertures(game, snapshot) → List<String>`
///     Returns the deterministic list of NW tribe / minor faction ids
///     the active COLONIAL-lite player should `establishOverture` toward
///     this turn. COLONIAL-lite is the parallel safeguard inside EXPAND
///     (issue #2509 § COLONIAL-lite, schedule turn ≥120 with OW = 9 and
///     global NW carrying non-GP ownership). Never emit `declareWar`,
///     `joinEmpire` chain advance, or `purchase_land` here. Tiebreak:
///     lowest factionId".
///
///   `planColonialNaval(game, snapshot,
///                       colonialDeclaredWarTargetFactionId)
///                                                 → ColonialNavalPlan`
///     Returns the deterministic COLONIAL naval **invasion-transport**
///     directive for the active player as a [ColonialNavalPlan]. The
///     plan carries the priority subset of
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] that
///     invasion-transport naval moves should treat as the
///     regiment-landing focus this turn (issue #2509 § COLONIAL phase
///     planner § planColonialNaval "Transport regiments to NW invasion
///     staging"). Priority arms mirror [planColonialMilitary]:
///     (1) declared colonial target's NW invadable provinces;
///     (2) at-war fallback (union of NW invadable provinces owned by
///     any faction in [ThreatSummary.atWarWith]). Returns
///     [ColonialNavalPlan.defaultPlan] (no invasion-transport
///     constraint) for the outer COLONIAL guards (below quota, missing
///     player, empty NW invadable) and for the priority-arm
///     fall-through. Unlike [planColonialLiteNaval], GP-owned NW
///     invadable provinces are **not** structurally filtered -- COLONIAL
///     allows full-scale invasion (declare-war + transport) against any
///     faction class per issue #2509 § planColonialAcquisition step 3.
///     The exploration + cargo arms of the spec
///     ("Explore unrevealed NW tiles. Cargo routing for overseas
///     extraction.") continue at the orchestrator layer (#2509 S5) via
///     the existing `colonial_naval_scoring.dart` helpers --
///     `defaultPlan` therefore means "no invasion-transport directive
///     this turn; orchestrator runs the legacy free-choice colonial
///     naval pipeline as exploration / cargo only".
///
///   `planColonialLiteNaval(game, snapshot) → ColonialLiteNavalPlan`
///     Returns the deterministic COLONIAL-lite naval directive for the
///     active player as a [ColonialLiteNavalPlan]. The plan carries the
///     subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
///     that the orchestrator (#2509 S5) should treat as the naval
///     exploration / cargo focus this turn, restricted to provinces
///     owned by tribes or minor nations. Great-Power-owned NW invadable
///     provinces are structurally excluded because COLONIAL-lite is the
///     sole sanctioned NW exception inside EXPAND for **tribe / minor**
///     NW penetration; invasion transport and NW army staging are
///     suppressed by spec (issue #2509 § COLONIAL-lite § planColonialLiteNaval
///     "Never suggest invasion transport or NW army staging here").
///     The orchestrator combines [priorityNwProvinceIdsSorted] with
///     `MapTopology` (via the existing
///     `newWorldSeaZonesAdjacentToInvadableProvinces` helper in
///     `colonial_naval_scoring.dart`) to derive the actual naval-move
///     sea-zone destinations; the OW-stockpile cargo routing arm in
///     the spec is satisfied at the orchestrator layer by the existing
///     colonial naval pathing the directive does not override.
///     [ColonialLiteNavalPlan.defaultPlan] (no constraint) is returned
///     for the outer defensive guards (missing player, empty NW
///     invadable) and for the priority-arm fall-through (no
///     tribe / minor faction owns any NW invadable province).
///
///   `planColonialCivilian(game, snapshot) → List<WorkOrder>`
///     Returns deterministic `build_improvement` work orders for the
///     active player's idle Builder units, targeting unimproved
///     extractable resource tiles on **New World** GP-owned land (issue
///     #2509 § Suppressions in COLONIAL: "No OW build_improvement except
///     tiles needed for port/supply to active NW objectives"). The
///     planner emits NW-only orders as the structural COLONIAL-phase
///     posture; the narrow OW port/supply allowance is deferred to a
///     follow-up slice (no orchestrator consumer needs it on the
///     landed post-S5 dispatch path, and the SPEC text scopes it
///     tightly to active NW objectives).
///     Same yield-score key as `planDevelopCivilian`
///     (`kBuildImprovementExtractableResourceScore` plus the NW + owned-NW
///     bonuses) so the orchestrator sees consistent priority rankings
///     across phases on the landed post-S5 dispatch path.
library;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_phase_planner.dart' as expand_phase_planner;
import 'observer_goal_phase.dart' show primaryColonialGpBlocker;
import 'phase_priority_weights.dart' show isNwLockRecoveryPathEActive;
import 'planning_helpers.dart' show gpFactionIdsAtWarWith, planningListEquals;

part 'colonial_phase_planner_acquisition.dart';
part 'colonial_phase_planner_military.dart';
part 'colonial_phase_planner_naval.dart';

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialPeace + the
/// `phase-planner-architecture.md` below-quota peer AC):
///
///   "Peace all at-war Great Powers, with TWO exceptions:
///    1. Keep fighting a GP that owns a province blocking the primary
///       colonial NW target (`primaryColonialGpBlocker`).
///    2. Keep fighting a Great Power peer whose OW province count is
///       below `kObserverConquestMinOwProvincesPerGp` (the OW quota).
///       This preserves Must-have #5 ('OW pressure preserved while
///       below quota'): a peer still in EXPAND may depend on the
///       active COLONIAL player as their only invadable OW
///       frontier-blocker war, and `war_resolver.dart`'s one-sided
///       GP peace conditions (collapsed survival / consolidation
///       arms) end the peer's war on a single offerer when the
///       offerer is the COLONIAL-phase player.
///
///    Never peace tribe/minor colonial targets until:
///    → Objective met (tribe no longer owns the target NW province), OR
///    → War is unwinnable (zero regiments, no treasury, can't build)."
///
/// The tribe/minor exception is handled structurally by this function: a
/// tribe or minor in [ThreatSummary.atWarWith] does not satisfy
/// `game.playerById(factionId) != null` (only [Player] entries are
/// returned from that lookup), so non-GP factions are filtered out before
/// the blocker pass. `offerPeace` toward tribes / minors therefore is
/// **never** emitted by this planner — the tribe / minor war-continuation
/// rule is preserved by exclusion. Conversely, `establishOverture`,
/// `purchase_land`, and NW conquest are emitted by sibling phase-planner
/// functions (`planColonialAcquisition`, `planColonialMilitary`) rather than reasoned about here.
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to
///     Great Power factions via [Game.playerById]; (b) compute the
///     primary colonial NW frontier blocker via
///     [primaryColonialGpBlocker], which maps the active player's
///     visible invadable NW provinces to their current owners and picks
///     the GP with the largest invadable-NW ownership share; (c) look
///     up each at-war GP's authoritative OW province count via
///     [oldWorldProvinceCountOwnedBy] for the below-quota peer
///     exclusion (post-resolution game state, identical to the source
///     `war_resolver.dart` consumes for one-sided peace evaluation).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith] and
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (consumed
///     transitively by [primaryColonialGpBlocker]).
///
/// Output:
///   - Empty list when no Great Powers are at war with the active
///     player (the GP filter loop produces an empty `gpWars` and the
///     trailing sort is a no-op).
///   - All at-quota GPs sorted ascending when the blocker is `null`
///     (no invadable NW province is owned by a Great Power) or when
///     the blocker is not among the at-war GPs (the membership guard
///     arm). Below-quota peers are dropped from this list.
///   - All at-quota GPs except the blocker sorted ascending when the
///     blocker is among the at-war GPs (canonical COLONIAL-peace
///     happy path: keep fighting the colonial blocker, peace every
///     other at-quota GP front, leave below-quota peers active).
///   - Empty list when every at-war GP is either the colonial blocker
///     or a below-quota peer (the COLONIAL planner has nothing to
///     peace this turn -- the peer expansion is still in progress).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planColonialPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);

  final result = <String>[
    for (final factionId in gpWars)
      if (factionId != blocker &&
          !isBelowObserverConquestQuota(
            oldWorldProvinceCountOwnedBy(game, factionId),
          ))
        factionId,
  ]..sort();
  return result;
}
