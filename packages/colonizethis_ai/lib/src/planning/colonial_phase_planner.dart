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
/// Wiring this module into the orchestrator, replacing the legacy
/// `colonialPhaseGpPeaceTargets` helper in `observer_goal_phase.dart`, and
/// retiring the `colonial_pressure.dart` / `diplomacy_planner_peace_targets.dart`
/// ratchet helpers are out of scope for this slice (tracked under S5 / S1
/// of #2509). Both the legacy `colonialPhaseGpPeaceTargets` helper and the
/// new `planColonialPeace` function remain pinned at the function-unit
/// level until the orchestrator rewrite reconciles them, so this slice
/// carries **zero behavior change** and **zero regression risk** for live
/// AI play.
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
///     follow-up slice (no current consumer needs it pre-S5 wiring,
///     and the SPEC text scopes it tightly to active NW objectives).
///     Same yield-score key as `planDevelopCivilian`
///     (`kBuildImprovementExtractableResourceScore` plus the NW + owned-NW
///     bonuses) so the orchestrator sees consistent priority rankings
///     across phases during the S5 transition.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'observer_goal_phase.dart' show primaryColonialGpBlocker;

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialPeace):
///
///   "Peace all at-war Great Powers, with ONE exception:
///    → Keep fighting a GP that owns a province blocking the primary
///      colonial NW target (primaryColonialGpBlocker).
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
///     the GP with the largest invadable-NW ownership share.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith] and
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (consumed
///     transitively by [primaryColonialGpBlocker]).
///
/// Output:
///   - Empty list when no Great Powers are at war with the active
///     player (the GP filter loop produces an empty `gpWars` and the
///     trailing sort is a no-op).
///   - All GPs sorted ascending when the blocker is `null` (no
///     invadable NW province is owned by a Great Power) or when the
///     blocker is not among the at-war GPs (the membership guard arm).
///     The legacy "no exception applies" path: peace **all** live GP
///     fronts.
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs (canonical COLONIAL-peace happy path:
///     keep fighting the colonial blocker, peace every other GP front).
///   - Empty list when the active player is at war with exactly one
///     GP **and** that GP is the colonial blocker (the lone war IS the
///     blocker war -- keep fighting it; nothing else to peace).
///   - The single GP (as a 1-element list) when the active player is
///     at war with exactly one GP and that GP is **not** the colonial
///     blocker. This is the explicit divergence from the legacy
///     [colonialPhaseGpPeaceTargets] helper, which short-circuits with
///     `return const []` when `gpWars.length <= 1`. The new spec wording
///     "Peace all at-war Great Powers" does not carry the legacy
///     `>= 2 GPs` guard: every non-blocker GP front must peace so the
///     orchestrator (#2509 S5) can drive NW acquisition / improvement
///     work without an idle GP-vs-GP distraction war.
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planColonialPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}

/// Method by which a COLONIAL acquisition target should be pursued
/// (issue #2509 § COLONIAL phase planner § planColonialAcquisition).
///
/// Three methods are defined by the spec — Join Empire is the cheapest
/// path and always preferred first when available; `purchase_land`
/// applies when an idle Merchant and a valid purchase tile are present;
/// `declareWar` applies when treasury / regiments support the conquest
/// path and the target is sea-reachable. All three methods are emitted
/// by [planColonialAcquisition]; the structural priority Method 1 → 2 →
/// 3 mirrors the spec's "always preferred first" Join Empire framing
/// and the "deprioritize war behind Join Empire and purchase_land"
/// turn-110 guidance.
enum AcquisitionMethod {
  /// `establishOverture` advancing the chain to `joinEmpire`. The
  /// fastest, cheapest acquisition path (issue #2509 § Acquisition
  /// method 1).
  joinEmpire,

  /// `purchase_land` work order for an idle Merchant unit (issue
  /// #2509 § Acquisition method 2).
  purchaseLand,

  /// `declareWar` + NW army move toward a sea-reachable tribe / minor
  /// (issue #2509 § Acquisition method 3). Emitted by
  /// [planColonialAcquisition] only when Join Empire and
  /// `purchase_land` both yielded no target this turn and the active
  /// player can afford the cheapest regiment build with at least one
  /// standing regiment already in service.
  declareWar,
}

/// Deterministic acquisition target picked by [planColonialAcquisition].
///
/// Pairs the faction id owning the chosen NW province with the
/// [AcquisitionMethod] the orchestrator should use this turn. The pair
/// is stable: identical inputs always yield identical targets (Refs
/// #2509 Must-have #7). The pair is materialized as a small value
/// class (not a record) to keep value-equality semantics explicit for
/// tests and to mirror the shape of other phase-planner return types
/// under construction in this file.
class ColonialAcquisitionTarget {
  const ColonialAcquisitionTarget({
    required this.targetFactionId,
    required this.method,
  });

  /// Faction id of the tribe or minor that currently owns the chosen
  /// NW province. Never a Great Power — Join Empire toward a GP is
  /// gated by Empire Building tech and the "nearly defeated" check in
  /// the join-empire validator (see
  /// `join_empire_validator.dart`), neither of which fits the COLONIAL
  /// phase's "acquire tribe / minor NW" objective. The planner skips
  /// GP-owned NW provinces structurally.
  final String targetFactionId;

  /// Resolution path the orchestrator should use. The planner can
  /// return any of [AcquisitionMethod.joinEmpire] (Acquisition method
  /// 1), [AcquisitionMethod.purchaseLand] (Acquisition method 2), or
  /// [AcquisitionMethod.declareWar] (Acquisition method 3) per the
  /// structural Method 1 → 2 → 3 priority documented on
  /// [planColonialAcquisition].
  final AcquisitionMethod method;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialAcquisitionTarget &&
          targetFactionId == other.targetFactionId &&
          method == other.method;

  @override
  int get hashCode => Object.hash(targetFactionId, method);

  @override
  String toString() =>
      'ColonialAcquisitionTarget('
      'targetFactionId: $targetFactionId, method: $method)';
}

/// Returns the deterministic acquisition target for the active
/// COLONIAL player this turn, or `null` when no method is achievable.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialAcquisition,
/// Acquisition methods 1, 2, and 3):
///
///   "1. Join Empire
///      → Conditions: embassy with owning tribe, treasury ≥ cost.
///      → Generate establishOverture(tribe) targeting Join Empire chain.
///      → This is the cheapest, fastest path — always preferred first.
///    2. purchase_land
///      → Conditions: idle Merchant unit, tile has resource (prospected
///        if mineral), treasury ≥ purchase cost.
///      → Generate purchase_land work order for Merchant.
///    3. declareWar + invade
///      → Conditions: treasury ≥ regiment build cost, regiments
///        available, tribe/minor is sea-reachable.
///      → Generate declareWar(tribe) + NW army move.
///      → From turn 110: deprioritize war behind Join Empire and
///        purchase_land (fewer turns to complete)."
///
/// **Method 1 — Join Empire.** The "embassy with owning tribe" phrasing
/// in the issue body is tightened here to align with the order-engine
/// validator in
/// `packages/colonizethis_logic/lib/src/orders/validators/diplomatic/`
/// `join_empire_validator.dart`: Join Empire requires the active
/// player's overture toward the tribe / minor target to already be at
/// [OvertureStage.nap], plus a Friendly+ relation score, plus treasury
/// covering [joinEmpireCostForMinorOrTribe]. Suggesting `joinEmpire`
/// from a lower overture stage would be rejected by the validator and
/// produce no order, so the planner gates on the same `nap` precondition
/// the validator enforces. Advancing the chain through earlier stages
/// (`consulate`, `embassy`) is the responsibility of sibling overture
/// planners (`planColonialLiteOvertures` and the legacy overture
/// helpers) — Join Empire kicks in only on the terminal
/// `nap → joinEmpire` step.
///
/// **Method 2 — `purchase_land`.** Mirrors the validator-side gates in
/// `precheckPurchaseLand` (`work_order_target_prechecks.dart`) so the
/// planner never suggests a target the engine would reject:
///
///   - active player must hold at least one idle Merchant
///     ([Unit.type] == [kUnitTypeMerchant], [Unit.status] ==
///     [UnitStatus.idle]) anywhere in the world; the orchestrator and
///     resolver handle the staging movement on follow-up turns;
///   - target province owner must be a tribe / minor (not a Great
///     Power; not the active player itself);
///   - active player must not be at war with that owner
///     ([DiplomacyRelation.atWar] == false);
///   - active player must have at least an embassy-stage overture with
///     that owner ([OvertureState.hasEmbassy] == true, i.e. stage in
///     `{embassy, nap, joinEmpire}`);
///   - the province must contain at least one tile that is itself a
///     valid `purchase_land` candidate: non-empty resource id, not
///     already purchased by any GP, treasury covering
///     [purchaseLandCost], and — for mineral resource ids in
///     [kMineralResourceIds] — already in the active player's
///     prospected-tile set ([WorldState.playerProspectedTiles]).
///
/// **Method 3 — `declareWar`.** Mirrors the validator-side gate in
/// `declareWarSubValidator` (`declare_war_validator.dart`) plus the
/// spec's outer "treasury ≥ regiment build cost, regiments available"
/// preconditions:
///
///   - outer: active player must hold at least one standing regiment
///     across Home + field armies ([regimentCountForPlayer] > 0) so
///     the spec's "Generate declareWar(tribe) + NW army move"
///     follow-up has at least one unit available; without any
///     regiments the order pair cannot be fulfilled and the planner
///     would emit a target the conquest army-move pass could not
///     follow up on;
///   - outer: treasury must cover the cheapest [RegimentEconomyCatalog]
///     build cost ([_cheapestRegimentBuildTreasuryCost]) so the
///     declare-war target can be reinforced this turn or next via the
///     economy build pass (matches the symmetric gate in
///     `planExpandDeclareWar` for the EXPAND below-quota declare-war
///     path);
///   - per-province: owner must be a tribe / minor (GPs structurally
///     excluded via `game.playerById(ownerId) != null`, same skip as
///     Methods 1 and 2; declareWar against a GP is COLONIAL's
///     `planColonialMilitary` declared-target arm, not an acquisition
///     decision);
///   - per-province: active player must not already be at war with
///     that owner — the order-engine validator rejects with "Already
///     at war with that faction" when [RelationState.atWar]. The
///     planner matches the validator's `atPeace` framing by
///     accepting a `null` relation row (no prior diplomatic record)
///     while skipping any row with [DiplomacyRelation.atWar] true.
///     Already-at-war tribes / minors are pursued by
///     [planColonialMilitary]'s declared-target / at-war fallback
///     arms instead.
///
/// Sea reachability is enforced **structurally** by the per-province
/// iteration: every candidate appears in
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted], which the
/// perception-snapshot builder restricts to provinces reachable from
/// owned anchors via [reachableNonOwnedProvinceIdsViaSeas]. A tribe /
/// minor that owns no sea-reachable NW invadable province therefore
/// never enters the iteration and cannot become a declareWar target;
/// no separate topology probe is required at the planner level.
///
/// The Method 1 pass scans every NW invadable province first; if no
/// Join Empire target is reachable, the Method 2 pass scans the same
/// list with the `purchase_land` gate set; if neither pass yields a
/// target, the Method 3 pass scans the same list with the declareWar
/// gate set. This implements the spec "Join Empire is always
/// preferred first" plus "deprioritize war behind Join Empire and
/// purchase_land" by structural priority — the cheaper paths always
/// run before the costlier conquest path. The turn-110 inversion the
/// spec mentions is therefore a no-op for today's planner: declareWar
/// is already last-resort across every turn.
///
/// Iteration ordering:
///   - Walks [ColonialSummary.invadableNewWorldProvinceIdsByDistance]
///     in BFS-distance order (nearest invadable NW province to the
///     active player's territory first, ascending province id as a
///     deterministic tiebreaker among equal-distance candidates).
///     This matches the spec wording "sorted by adjacency distance
///     to owned territory" (Refs #2509 § planColonialAcquisition).
///     Distance is measured as topology edges (province <-> province
///     borders count as 1; province <-> seaZone <-> province via the
///     canonical NW colonial route counts as 2). The
///     perception-snapshot builder derives this list from
///     [reachableNonOwnedProvinceDistancesViaSeas]; when the snapshot
///     was built without a [MapTopology] (e.g. synthetic unit-test
///     fixtures) the planner falls back to
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (lex
///     order) so legacy fixtures stay deterministic without
///     re-plumbing topology through every test setup.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard, looks up the province-owner map
///     ([getProvinceOwnerMap]) to find each NW province's current
///     owner, queries [getOverture] / [getRelation] for the gate
///     evaluation, and computes [joinEmpireCostForMinorOrTribe] /
///     [purchaseLandCost] for the treasury check. The Method 2 pass
///     also reads [WorldState.playerProspectedTiles],
///     [WorldState.purchasedTilesByTileKey], and
///     [WorldState.resourceByTileKey] to validate per-tile gates.
///     The Method 3 pass reads
///     [WorldState.armies] (via [regimentCountForPlayer]) for the
///     standing-regiment gate and scans [RegimentEconomyCatalog] for
///     the cheapest build cost.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the
///     candidate NW province pool) and [EconomySummary.treasury] (the
///     active player's spendable cash for the acquisition payment).
///
/// Output:
///   - [ColonialAcquisitionTarget] with [AcquisitionMethod.joinEmpire]
///     when the first NW province in
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] whose
///     owner satisfies the four Join-Empire gates (overture stage =
///     [OvertureStage.nap], relation score ≥ [relationScoreMinFriendly],
///     treasury ≥ [joinEmpireCostForMinorOrTribe], owner is a
///     tribe / minor and not a Great Power).
///   - [ColonialAcquisitionTarget] with
///     [AcquisitionMethod.purchaseLand] when no Join-Empire target is
///     reachable but the active player has at least one idle Merchant
///     and the first NW province in the sorted list whose owner
///     satisfies the embassy + non-war gates also contains at least
///     one tile satisfying the per-tile `purchase_land` gates.
///   - [ColonialAcquisitionTarget] with [AcquisitionMethod.declareWar]
///     when neither Join Empire nor `purchase_land` yields a target,
///     the active player holds at least one standing regiment and
///     treasury covering [_cheapestRegimentBuildTreasuryCost], and
///     the first NW province in the sorted list is owned by a
///     tribe / minor the active player is not yet at war with.
///   - `null` when no NW province satisfies any acquisition method,
///     or when the outer guards trip (missing active player record,
///     empty NW invadable list). Consumers should treat `null` as
///     "no acquisition order this turn" rather than "acquisition
///     path impossible".
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ColonialAcquisitionTarget]s (Refs #2509
/// Must-have #7).
ColonialAcquisitionTarget? planColonialAcquisition({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (game.playerById(snapshot.playerId) == null) {
    return null;
  }
  final invadable = _acquisitionIterationOrder(snapshot.colonial);
  if (invadable.isEmpty) {
    return null;
  }

  final provinceOwner = getProvinceOwnerMap(game);
  final treasury = snapshot.economy.treasury;

  for (final provinceId in invadable) {
    final ownerId = provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (game.playerById(ownerId) != null) continue;

    final overture = getOverture(game, snapshot.playerId, ownerId);
    if (overture == null) continue;
    if (overture.stage != OvertureStage.nap) continue;

    final relation = getRelation(game, snapshot.playerId, ownerId);
    if (relation == null || relation.score < relationScoreMinFriendly) {
      continue;
    }

    final cost = joinEmpireCostForMinorOrTribe(game, ownerId);
    if (treasury < cost) continue;

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.joinEmpire,
    );
  }

  if (_hasIdleMerchant(game.worldState, snapshot.playerId)) {
    final prospected =
        game.worldState.playerProspectedTiles[snapshot.playerId] ??
        const <String>{};
    final purchasedByTile = game.worldState.purchasedTilesByTileKey;

    for (final provinceId in invadable) {
      final ownerId = provinceOwner[provinceId];
      if (ownerId == null) continue;
      if (game.playerById(ownerId) != null) continue;

      final relation = getRelation(game, snapshot.playerId, ownerId);
      if (relation != null && relation.atWar) continue;

      final overture = getOverture(game, snapshot.playerId, ownerId);
      if (overture == null || !overture.hasEmbassy) continue;

      if (!_provinceHasValidPurchaseLandTile(
        world: game.worldState,
        provinceId: provinceId,
        treasury: treasury,
        prospected: prospected,
        purchasedByTile: purchasedByTile,
      )) {
        continue;
      }

      return ColonialAcquisitionTarget(
        targetFactionId: ownerId,
        method: AcquisitionMethod.purchaseLand,
      );
    }
  }

  if (regimentCountForPlayer(game, snapshot.playerId) <= 0) {
    return null;
  }
  if (treasury < _cheapestRegimentBuildTreasuryCost()) {
    return null;
  }

  for (final provinceId in invadable) {
    final ownerId = provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (game.playerById(ownerId) != null) continue;

    final relation = getRelation(game, snapshot.playerId, ownerId);
    if (relation != null && relation.atWar) continue;

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.declareWar,
    );
  }

  return null;
}

/// Iteration order over NW invadable provinces for
/// [planColonialAcquisition], honoring the spec's adjacency-distance
/// requirement (Refs #2509 § COLONIAL phase planner §
/// planColonialAcquisition -- "sorted by adjacency distance to owned
/// territory").
///
/// Returns [ColonialSummary.invadableNewWorldProvinceIdsByDistance]
/// when the snapshot was built with a [MapTopology] (the normal
/// production path; the perception-snapshot builder populates the
/// distance-sorted field via
/// [reachableNonOwnedProvinceDistancesViaSeas]). Falls back to the
/// lex-sorted [ColonialSummary.invadableNewWorldProvinceIdsSorted]
/// for synthetic fixtures that build snapshots without a topology
/// (today: the COLONIAL acquisition unit tests). The fallback
/// preserves backward-compatible behavior for the legacy pin set
/// (sort-by-province-id tiebreaks) while production play uses the
/// distance-sorted iteration the spec mandates.
///
/// The function never throws or returns null: if the snapshot has
/// neither field populated (e.g. an outer COLONIAL guard already
/// short-circuited to an empty invadable set upstream), it returns
/// the empty list and the caller's outer-guard short-circuits as
/// today.
List<String> _acquisitionIterationOrder(ColonialSummary colonial) {
  if (colonial.invadableNewWorldProvinceIdsByDistance.isNotEmpty) {
    return colonial.invadableNewWorldProvinceIdsByDistance;
  }
  return colonial.invadableNewWorldProvinceIdsSorted;
}

/// Minimum [RegimentEconomyCatalog] build treasury cost (deterministic
/// catalog scan).
///
/// Mirrors `_cheapestRegimentBuildTreasuryCost` in
/// `expand_phase_planner.dart` (Refs #2509 § EXPAND phase planner) so
/// the COLONIAL declare-war arm stays self-contained against the S1
/// deletion of `colonial_pressure.dart`. Linear in the catalog size,
/// matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
int _cheapestRegimentBuildTreasuryCost() {
  var min = 999999999;
  for (final econ in RegimentEconomyCatalog.byId.values) {
    if (econ.buildTreasuryCost < min) {
      min = econ.buildTreasuryCost;
    }
  }
  return min;
}

/// True when [playerId] owns at least one [kUnitTypeMerchant] unit
/// with [UnitStatus.idle] in either region. Region of the Merchant is
/// not constrained — the orchestrator and resolver handle staging
/// movement on follow-up turns (mirrors the Builder selection
/// convention in [planColonialCivilian]).
bool _hasIdleMerchant(WorldState world, String playerId) {
  for (final unit in allUnitsFromWorld(world)) {
    if (unit.ownerId == playerId &&
        unit.type == kUnitTypeMerchant &&
        unit.status == UnitStatus.idle) {
      return true;
    }
  }
  return false;
}

/// True when [provinceId] contains at least one tile satisfying every
/// per-tile gate from `precheckPurchaseLand`:
///
///   - non-empty resource id in [WorldState.resourceByTileKey];
///   - not present in [purchasedByTile] (no other GP has bought it,
///     and the active player has not already purchased it either);
///   - mineral resource ids ([kMineralResourceIds]) require the tile
///     to be in [prospected] (the active player's prospected-tile
///     set);
///   - [purchaseLandCost] for the resource must be within [treasury].
///
/// Iteration over [WorldState.resourceByTileKey] is bounded by the
/// total number of tiles with a resource entry (much smaller than the
/// global tile count); per-tile checks are O(1). The function returns
/// the existence answer only — picking a specific tile for the
/// `purchase_land` work order is the orchestrator's job (the planner
/// contract returns the *target faction* and the *method*, not the
/// exact tile, mirroring the [AcquisitionMethod.joinEmpire] return
/// shape).
bool _provinceHasValidPurchaseLandTile({
  required WorldState world,
  required String provinceId,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    if (Unit.provinceIdFromTileKey(tileKey) != provinceId) continue;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (purchasedByTile.containsKey(tileKey)) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(tileKey)) {
      continue;
    }
    if (treasury < purchaseLandCost(resourceId)) continue;
    return true;
  }
  return false;
}

/// COLONIAL-phase conquest destination filter returned by
/// [planColonialMilitary].
///
/// Two ascending-sorted lists describe the priority subset of NW
/// invadable provinces (and the owning faction(s)) that conquest army
/// moves should target this turn. The lists never contain Old World
/// provinces — structural suppression in [planColonialMilitary] (the
/// planner only reads [ColonialSummary.invadableNewWorldProvinceIdsSorted],
/// which is NW-only by construction in the perception-snapshot builder).
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// `runConquestArmyMovePlanner`:
///   - [defaultPlan] (`priorityDestinationProvinceIdsSorted` empty) =
///     "no constraint"; the orchestrator chooses freely from the full
///     NW invadable set (the legacy COLONIAL fall-back behaviour).
///   - A non-default plan = "restrict NW conquest destinations to this
///     subset". Empty plans never carry
///     [priorityTargetOwnerFactionIdsSorted] entries; non-empty plans
///     always carry at least one owner faction id.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests can
/// assert against literal constructions without relying on identity.
class ColonialMilitaryPlan {
  const ColonialMilitaryPlan({
    required this.priorityDestinationProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for non-COLONIAL callers, GPs
  /// below the observer conquest quota, the empty-NW-invadable guard,
  /// and the priority-arm fall-through (declared colonial target owns
  /// nothing in NW invadable and no at-war faction owns NW invadable
  /// either).
  static const ColonialMilitaryPlan defaultPlan = ColonialMilitaryPlan(
    priorityDestinationProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only) whose owners match the priority-arm filter for this
  /// turn. Sorted ascending so identical inputs yield identical lists
  /// (Refs #2509 Must-have #7). Empty for [defaultPlan].
  final List<String> priorityDestinationProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityDestinationProvinceIdsSorted]. Sorted ascending and
  /// deduplicated:
  ///   - Single-element list when the declared colonial-target arm
  ///     fires ([planColonialMilitary] § Priority 1). The target may
  ///     be a tribe, minor nation, or Great Power — the planner does
  ///     not partition by faction class because COLONIAL acquisition
  ///     via `declareWar` (issue #2509 § planColonialAcquisition step
  ///     3) can pick any of those.
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planColonialMilitary] § Priority 2).
  ///   - Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialMilitaryPlan &&
          _colonialListEquals(
            priorityDestinationProvinceIdsSorted,
            other.priorityDestinationProvinceIdsSorted,
          ) &&
          _colonialListEquals(
            priorityTargetOwnerFactionIdsSorted,
            other.priorityTargetOwnerFactionIdsSorted,
          );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorityDestinationProvinceIdsSorted),
    Object.hashAll(priorityTargetOwnerFactionIdsSorted),
  );

  @override
  String toString() =>
      'ColonialMilitaryPlan('
      'priorityDestinationProvinceIdsSorted: $priorityDestinationProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

bool _colonialListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns the deterministic COLONIAL-phase conquest destination filter
/// for the active player as a [ColonialMilitaryPlan].
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialMilitary):
///
///   "NW army moves toward the primary colonial target's provinces.
///      → Use runConquestArmyMovePlanner with NW destination filter
///        (targets in invadableNewWorldProvinceIdsSorted owned by the
///        declare-war target faction).
///      → OW defend/regiment rebuild allowed."
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] by owner
///     faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the NW-only
///     candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the COLONIAL outer
///     quota gate — see "below quota -> default" guard below), and
///     [ThreatSummary.atWarWith] (the Priority 2 fallback when no
///     colonial declare-war target is given).
///   - [colonialDeclaredWarTargetFactionId]: optional colonial
///     declare-war target chosen by [planColonialAcquisition] when the
///     acquisition method resolves to [AcquisitionMethod.declareWar]
///     (issue #2509 § planColonialAcquisition Acquisition method 3).
///     When non-null, the planner restricts conquest destinations to
///     NW provinces owned by that faction (Priority 1). The argument
///     is not constrained to a specific faction class — tribes, minor
///     nations, and Great Powers are all valid targets per the spec;
///     the acquisition planner only ever returns tribe / minor ids
///     because Method 3 structurally excludes GP-owned NW invadable,
///     but [planColonialMilitary] does not re-narrow that argument so
///     the orchestrator stays free to pass any at-war target.
///
/// Priority arms (first match wins; each arm produces a sorted-ascending,
/// deduplicated province list):
///   1. **Declared colonial target** — when
///      [colonialDeclaredWarTargetFactionId] is non-null and owns at
///      least one province in
///      [ColonialSummary.invadableNewWorldProvinceIdsSorted], the plan
///      restricts to those provinces and lists only the target as
///      `priorityTargetOwnerFactionIdsSorted`.
///   2. **At-war owners fallback** — when no colonial target is given
///      and at least one faction in [ThreatSummary.atWarWith] owns an
///      NW invadable province, the plan restricts to the union of
///      those provinces and lists the at-war owners sorted ascending.
///   3. **Default plan** — when the declared colonial target owns
///      nothing in NW invadable, or when no target is given and no
///      at-war faction owns NW invadable, or for the outer guards
///      (below quota, missing player, empty NW invadable). Empty plan
///      signals the orchestrator to fall back to its existing
///      free-choice colonial-conquest behaviour over the full NW
///      invadable set.
///
/// Structural OW suppression: this function reads only
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW-only by
/// builder contract). It never reads
/// [ConquestSummary.invadableProvinceIdsSorted], so an Old World
/// province cannot appear in the plan even when the snapshot exposes
/// one. The OW defend / regiment-rebuild work mentioned in the spec
/// (the "OW defend/regiment rebuild allowed" bullet) lives in the
/// EXPAND economy planner and the conquest army-move planner running
/// in defend mode — those siblings remain free to act in OW while
/// planColonialMilitary drives the NW conquest filter (Refs #2509 §
/// COLONIAL phase planner § planColonialMilitary).
///
/// Outer guard rationale: [isBelowObserverConquestQuota] returning
/// `true` means the active player has not reached
/// [kObserverConquestMinOwProvincesPerGp] (the EXPAND -> COLONIAL
/// transition threshold). The function returns [defaultPlan] in that
/// case so a mis-dispatched call from EXPAND territory cannot emit NW
/// destinations. The symmetric guard in `planExpandMilitary` short-circuits
/// when the same predicate returns `false` (at/above quota). Both
/// guards are documented as defensive — the structural caller still
/// drives phase dispatch via `observerGoalPhaseFor`.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ColonialMilitaryPlan]s (Refs #2509 Must-have #7).
ColonialMilitaryPlan planColonialMilitary({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? colonialDeclaredWarTargetFactionId,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ColonialMilitaryPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialMilitaryPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialMilitaryPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (colonialDeclaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == colonialDeclaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ColonialMilitaryPlan.defaultPlan;
    }
    destinations.sort();
    return ColonialMilitaryPlan(
      priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        colonialDeclaredWarTargetFactionId,
      ]),
    );
  }

  final atWarSet = snapshot.threats.atWarWith.toSet();
  final atWarOwners = <String>{};
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ColonialMilitaryPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ColonialMilitaryPlan(
    priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}

/// COLONIAL-phase invasion-transport destination filter returned by
/// [planColonialNaval].
///
/// Two ascending-sorted lists describe the priority subset of NW
/// invadable provinces (and the owning faction(s)) that
/// invasion-transport naval moves should land regiments at this turn.
/// The lists never contain Old World provinces -- structural
/// suppression in [planColonialNaval] (the planner only reads
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted], which is
/// NW-only by construction in the perception-snapshot builder).
///
/// Unlike [ColonialLiteNavalPlan], the COLONIAL invasion-transport
/// directive **does not** filter out GP-owned NW invadable provinces:
/// COLONIAL acquisition method 3 (issue #2509 § planColonialAcquisition
/// step 3) explicitly permits `declareWar` + invasion against any
/// faction class -- tribes, minor nations, **and** Great Powers
/// blocking the colonial frontier -- so a GP-owned NW invadable
/// province is a legitimate transport destination here. The
/// COLONIAL-lite sibling, by contrast, suppresses NW `declareWar` and
/// must therefore exclude GP-owned NW invadable from its naval focus.
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// the existing colonial naval pipeline:
///   - [defaultPlan]
///     (`priorityInvasionTransportProvinceIdsSorted` empty) =
///     "no invasion-transport directive this turn"; the orchestrator
///     keeps running the legacy free-choice colonial naval pipeline as
///     exploration + cargo only (the two non-invasion arms from the
///     spec stay live; they are satisfied by `colonial_naval_scoring.dart`
///     without any input from this plan).
///   - A non-default plan = "restrict invasion-transport landing
///     destinations to this NW invadable subset". Non-empty plans
///     always carry at least one owner faction id; empty plans never
///     carry [priorityTargetOwnerFactionIdsSorted] entries.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests
/// can assert against literal constructions without relying on
/// identity, mirroring the [ColonialMilitaryPlan] /
/// [ColonialLiteNavalPlan] shape.
class ColonialNavalPlan {
  const ColonialNavalPlan({
    required this.priorityInvasionTransportProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for the outer COLONIAL
  /// guards (below quota, missing player, empty NW invadable) and for
  /// the priority-arm fall-through (declared colonial target owns
  /// nothing in NW invadable and no at-war faction owns NW invadable
  /// either). The orchestrator (#2509 S5) treats `defaultPlan` as "no
  /// invasion-transport directive this turn" and runs the legacy
  /// free-choice colonial naval pipeline as exploration + cargo only.
  static const ColonialNavalPlan defaultPlan = ColonialNavalPlan(
    priorityInvasionTransportProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only by builder contract) where invasion-transport naval
  /// moves should land regiments this turn. Sorted ascending so
  /// identical inputs yield identical lists (Refs #2509
  /// Must-have #7). Empty for [defaultPlan].
  ///
  /// The orchestrator (#2509 S5) is expected to combine this list
  /// with `MapTopology` (via
  /// `newWorldSeaZonesAdjacentToInvadableProvinces` in
  /// `colonial_naval_scoring.dart`) to derive the actual sea-zone
  /// transport destinations and fleet pairings. Exploration of
  /// unrevealed NW tiles and cargo routing for overseas extraction
  /// are satisfied at the orchestrator layer by the existing
  /// colonial naval pathing the directive does not override -- the
  /// plan is intentionally scoped to the invasion-transport arm so a
  /// non-default plan does not suppress the parallel exploration /
  /// cargo activity.
  final List<String> priorityInvasionTransportProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityInvasionTransportProvinceIdsSorted]. Sorted ascending
  /// and deduplicated:
  ///   - Single-element list when the declared colonial-target arm
  ///     fires ([planColonialNaval] § Priority 1). The target may
  ///     be a tribe, minor nation, or Great Power -- the planner
  ///     does not partition by faction class because COLONIAL
  ///     acquisition via `declareWar` (issue #2509 §
  ///     planColonialAcquisition step 3) can pick any of those.
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planColonialNaval] § Priority 2).
  ///   - Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialNavalPlan &&
          _colonialListEquals(
            priorityInvasionTransportProvinceIdsSorted,
            other.priorityInvasionTransportProvinceIdsSorted,
          ) &&
          _colonialListEquals(
            priorityTargetOwnerFactionIdsSorted,
            other.priorityTargetOwnerFactionIdsSorted,
          );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorityInvasionTransportProvinceIdsSorted),
    Object.hashAll(priorityTargetOwnerFactionIdsSorted),
  );

  @override
  String toString() =>
      'ColonialNavalPlan('
      'priorityInvasionTransportProvinceIdsSorted: '
      '$priorityInvasionTransportProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

/// Returns the deterministic COLONIAL-phase invasion-transport
/// directive for the active player as a [ColonialNavalPlan].
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialNaval):
///
///   "Colonial naval missions:
///      → Transport regiments to NW invasion staging.
///      → Explore unrevealed NW tiles.
///      → Cargo routing for overseas extraction."
///
/// This planner covers the **invasion-transport** arm of that contract.
/// The remaining two arms ("Explore unrevealed NW tiles" and
/// "Cargo routing for overseas extraction") are satisfied at the
/// orchestrator layer (#2509 S5) by the existing colonial naval
/// pipeline -- specifically `colonial_naval_scoring.dart` which
/// already ranks naval moves toward NW sea zones adjacent to
/// invadable provinces (exploration) and toward NW ports (cargo
/// routing). Adding those arms to this plan would duplicate behaviour
/// the orchestrator already performs through the legacy free-choice
/// pipeline, so the directive is intentionally scoped to the
/// invasion-transport decision only: which NW invadable provinces
/// should this turn's transport ships stage regiments toward?
///
/// Priority arms (first match wins; each arm produces a
/// sorted-ascending, deduplicated province list):
///   1. **Declared colonial target** -- when
///      [colonialDeclaredWarTargetFactionId] is non-null and owns at
///      least one province in
///      [ColonialSummary.invadableNewWorldProvinceIdsSorted], the
///      plan restricts to those provinces and lists only the target
///      as `priorityTargetOwnerFactionIdsSorted`. Matches the
///      [planColonialMilitary] priority-1 shape so the orchestrator
///      can pair the army-move plan with the naval-transport plan
///      against the same colonial declare-war target.
///   2. **At-war owners fallback** -- when no colonial target is
///      given (the COLONIAL acquisition method resolved to Join
///      Empire or `purchase_land` rather than `declareWar`) and at
///      least one faction in [ThreatSummary.atWarWith] owns an NW
///      invadable province, the plan restricts to the union of those
///      provinces and lists the at-war owners sorted ascending. This
///      preserves invasion-transport pressure on existing wars even
///      when the current acquisition pick is a non-war method.
///   3. **Default plan** -- when the declared colonial target owns
///      nothing in NW invadable, or when no target is given and no
///      at-war faction owns NW invadable, or for the outer guards
///      (below quota, missing player, empty NW invadable). Empty
///      plan signals the orchestrator to skip the invasion-transport
///      directive this turn; the legacy exploration + cargo arms
///      continue uninterrupted.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] by owner
///     faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the
///     NW-only candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the COLONIAL outer
///     quota gate), and [ThreatSummary.atWarWith] (the Priority 2
///     fallback when no colonial declare-war target is given).
///   - [colonialDeclaredWarTargetFactionId]: optional colonial
///     declare-war target chosen by [planColonialAcquisition] when
///     the acquisition method resolves to
///     [AcquisitionMethod.declareWar] (issue #2509 §
///     planColonialAcquisition Acquisition method 3). When non-null,
///     the planner restricts transport destinations to NW provinces
///     owned by that faction (Priority 1). The argument is not
///     constrained to a specific faction class -- tribes, minor
///     nations, and Great Powers are all valid invasion-transport
///     targets per the spec because COLONIAL allows invasion against
///     any colonial blocker; the acquisition planner returns only
///     tribe / minor ids today, but [planColonialNaval] does not
///     re-narrow the argument so the orchestrator stays free to pass
///     any at-war target.
///
/// Structural OW suppression: this function reads only
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW-only by
/// builder contract). It never reads
/// [ConquestSummary.invadableProvinceIdsSorted], so an Old World
/// province cannot appear in the plan even when the snapshot exposes
/// one.
///
/// Difference vs [planColonialLiteNaval]: [planColonialLiteNaval]
/// filters out GP-owned NW invadable provinces because COLONIAL-lite
/// is the safeguard for tribe / minor NW penetration only and
/// suppresses NW `declareWar` entirely. [planColonialNaval] does
/// **not** apply that filter: invading a GP-owned NW invadable
/// province (the primary colonial GP blocker) is a legitimate
/// COLONIAL acquisition path. Both planners share the
/// "empty plan = orchestrator falls back to legacy free-choice
/// colonial naval pipeline" contract, just with different
/// owner-class admissibility for the priority arm.
///
/// Outer guard rationale: [isBelowObserverConquestQuota] returning
/// `true` means the active player has not reached
/// [kObserverConquestMinOwProvincesPerGp] (the EXPAND -> COLONIAL
/// transition threshold). The function returns [defaultPlan] in that
/// case so a mis-dispatched call from EXPAND territory cannot leak
/// NW invasion-transport destinations; matches the symmetric guard in
/// [planColonialMilitary] (the army-move plan also short-circuits
/// below quota so EXPAND callers never receive an NW directive).
///
/// The function is pure and deterministic -- identical inputs always
/// yield identical [ColonialNavalPlan]s (Refs #2509 Must-have #7).
ColonialNavalPlan planColonialNaval({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? colonialDeclaredWarTargetFactionId,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ColonialNavalPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialNavalPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialNavalPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (colonialDeclaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == colonialDeclaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ColonialNavalPlan.defaultPlan;
    }
    destinations.sort();
    return ColonialNavalPlan(
      priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        colonialDeclaredWarTargetFactionId,
      ]),
    );
  }

  final atWarSet = snapshot.threats.atWarWith.toSet();
  final atWarOwners = <String>{};
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ColonialNavalPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ColonialNavalPlan(
    priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}

/// Returns the deterministic list of NW tribe / minor faction ids the active
/// COLONIAL-lite player should `establishOverture` toward this turn.
///
/// Contract (issue #2509 § COLONIAL-lite § planColonialLiteOvertures):
///
///   "Inputs: Game, AIWorldSnapshot.
///    Returns: List<DiplomacyOrder> (establishOverture only).
///
///    For each visible NW tribe/minor owner in
///    adjacentNewWorldOwnerFactionIdsSorted ∪
///    preferredColonialTargetFactionIdsSorted:
///      → If no embassy yet, suggest establishOverture(tribe).
///      → Never emit declareWar, joinEmpire chain advance, or
///        purchase_land here.
///    Tiebreak: lowest factionId (deterministic)."
///
/// COLONIAL-lite is the parallel COLONIAL safeguard inside EXPAND scheduled
/// at turn ≥120 with OW ≥9 and below quota and global `newWorld|` carrying
/// non-GP ownership (issue #2509 § COLONIAL-lite). It is the **only**
/// exception to EXPAND's total NW suppression and prevents the deadlock
/// where no GP reaches OW = 10 and zero NW colonisation ever begins. The
/// orchestrator (#2509 S5) is expected to dispatch this planner only when
/// `observerGoalPhaseFor` resolves to [ObserverGoalPhase.colonialLite]; the
/// function itself does not re-check the phase, matching the other planner
/// contracts in this module.
///
/// Return type is `List<String>` of target faction ids (not the underlying
/// [DiplomaticOrder] objects) for parity with [planColonialPeace] and
/// `planExpandPeace`: the orchestrator translates the id list into the
/// concrete `establishOverture` order envelope, applying the deferred
/// suggestion-API validation step (#2509 S5). The list is sorted ascending
/// so identical inputs always yield identical outputs (Refs #2509 Must-have
/// #7) and the lowest-factionId tiebreak from the spec is preserved.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard, walks the GP filter on each candidate
///     ([Game.playerById] for tribes / minors returns `null`), and reads
///     [Game.overtureStates] to filter out targets that already advanced
///     past the `tradeConsulate` stage with the active player.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.adjacentNewWorldOwnerFactionIdsSorted] and
///     [ColonialSummary.preferredColonialTargetFactionIdsSorted]. Both
///     lists are unioned (sorted-deduplicated) before the GP / embassy
///     filters run.
///
/// Filter pipeline (each stage is structural, not configurable):
///   1. **Missing active player** -> empty list (the planner cannot
///      compute a per-player overture set without an owning [Player]).
///   2. **Empty candidate union** -> empty list (no visible NW tribe /
///      minor owner -- nothing to overture this turn).
///   3. **GP candidate filter** -> drop any candidate id where
///      [Game.playerById] returns a non-null [Player]. GPs do not
///      receive `establishOverture` per the spec ("Never emit
///      declareWar ... here" implies GP-vs-GP wars are out of scope for
///      this planner; GP-vs-GP peace is the [planColonialPeace] /
///      `planExpandPeace` contract).
///   4. **Embassy filter** -> drop any candidate where the active
///      player already holds an [OvertureState] with the target whose
///      [OvertureState.hasEmbassy] is `true` (stage in `{embassy, nap,
///      joinEmpire}`). The active-player constraint matters because
///      `game.overtureStates` lists per-GP entries -- a sibling GP's
///      embassy must not block the active player from initiating its
///      own overture.
///   5. **Sort ascending** -> deterministic list output (Refs #2509
///      Must-have #7).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists.
List<String> planColonialLiteOvertures({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final activePlayerId = snapshot.playerId;
  if (game.playerById(activePlayerId) == null) {
    return const [];
  }

  final candidates = <String>{};
  candidates.addAll(snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted);
  candidates.addAll(snapshot.colonial.preferredColonialTargetFactionIdsSorted);
  if (candidates.isEmpty) {
    return const [];
  }

  final result = <String>[];
  for (final factionId in candidates) {
    if (game.playerById(factionId) != null) continue;
    final alreadyEmbassied = game.overtureStates.any(
      (o) =>
          o.gpId == activePlayerId && o.targetId == factionId && o.hasEmbassy,
    );
    if (alreadyEmbassied) continue;
    result.add(factionId);
  }
  result.sort();
  return result;
}

/// Deterministic COLONIAL-lite naval directive returned by
/// [planColonialLiteNaval].
///
/// Carries the priority subset of
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW only) the
/// orchestrator (#2509 S5) should treat as the COLONIAL-lite naval
/// exploration / cargo focus this turn, restricted to provinces owned
/// by tribes or minor nations. Two paired list fields keep the value
/// class symmetric with [ColonialMilitaryPlan] so test fixtures and
/// orchestrator wiring can swap between them with the same shape:
/// `priorityNwProvinceIdsSorted` is the conquest-style destination
/// list (province ids) and `priorityTargetOwnerFactionIdsSorted` is
/// the corresponding owner-faction roster, both deduplicated and
/// sorted ascending so identical inputs always yield identical plans
/// (Refs #2509 Must-have #7).
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests
/// can assert against literal constructions without relying on
/// identity.
class ColonialLiteNavalPlan {
  const ColonialLiteNavalPlan({
    required this.priorityNwProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for the outer defensive
  /// guards (missing player, empty NW invadable) and for the
  /// priority-arm fall-through (no tribe / minor faction owns any NW
  /// invadable province). The orchestrator (#2509 S5) treats
  /// `defaultPlan` as "no COLONIAL-lite naval focus this turn" and
  /// leaves the existing naval suggestion pipeline to its legacy
  /// free-choice behaviour.
  static const ColonialLiteNavalPlan defaultPlan = ColonialLiteNavalPlan(
    priorityNwProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only by builder contract) whose owners are tribes or minor
  /// nations -- the COLONIAL-lite naval exploration / cargo focus
  /// this turn. Sorted ascending so identical inputs yield identical
  /// lists (Refs #2509 Must-have #7). Empty for [defaultPlan].
  ///
  /// The orchestrator (#2509 S5) is expected to combine this list
  /// with `MapTopology` (via
  /// `newWorldSeaZonesAdjacentToInvadableProvinces` in
  /// `colonial_naval_scoring.dart`) to derive the actual sea-zone
  /// naval-move destinations. Cargo routing (deliver riches to OW
  /// stockpile) is satisfied at the orchestrator layer by the
  /// existing colonial naval pathing the directive does not override.
  final List<String> priorityNwProvinceIdsSorted;

  /// Faction ids of the tribes / minor nations owning the provinces
  /// in [priorityNwProvinceIdsSorted]. Sorted ascending and
  /// deduplicated. Never includes any Great Power id -- GPs are
  /// structurally excluded by [planColonialLiteNaval] because
  /// COLONIAL-lite is the safeguard for **tribe / minor** NW
  /// penetration only (issue #2509 § COLONIAL-lite "establishOverture
  /// toward visible NW tribe / minor owners"). Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialLiteNavalPlan &&
          _colonialListEquals(
            priorityNwProvinceIdsSorted,
            other.priorityNwProvinceIdsSorted,
          ) &&
          _colonialListEquals(
            priorityTargetOwnerFactionIdsSorted,
            other.priorityTargetOwnerFactionIdsSorted,
          );

  @override
  int get hashCode => Object.hash(
    Object.hashAll(priorityNwProvinceIdsSorted),
    Object.hashAll(priorityTargetOwnerFactionIdsSorted),
  );

  @override
  String toString() =>
      'ColonialLiteNavalPlan('
      'priorityNwProvinceIdsSorted: $priorityNwProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

/// Returns the deterministic COLONIAL-lite naval directive for the
/// active player as a [ColonialLiteNavalPlan].
///
/// Contract (issue #2509 § COLONIAL-lite § planColonialLiteNaval):
///
///   "Inputs: Game, AIWorldSnapshot.
///    Returns: List<NavalOrder> (exploration + cargo only).
///
///      → Naval exploration of unrevealed NW sea zones adjacent to
///        visible NW provinces.
///      → Cargo routing (deliver riches to OW stockpile) using
///        existing colonial naval pathing.
///      → Never suggest invasion transport or NW army staging here."
///
/// COLONIAL-lite is the parallel COLONIAL safeguard inside EXPAND scheduled
/// at turn ≥`kObserverColonialLiteMinTurn` with OW ≥`kObserverColonialLiteNearQuotaOw`
/// and below quota, and global `newWorld|` carrying non-GP ownership
/// (issue #2509 § COLONIAL-lite; `SPEC/ai/ai-architecture.md` § COLONIAL-lite).
/// It is the **only** sanctioned exception to EXPAND's total NW
/// suppression and prevents the deadlock where no GP reaches OW = 10
/// and zero NW colonisation ever begins. The orchestrator (#2509 S5) is
/// expected to dispatch this planner only when `observerGoalPhaseFor`
/// resolves to [ObserverGoalPhase.colonialLite]; the function itself does
/// not re-check the phase, matching the convention established by
/// [planColonialLiteOvertures] and the other phase-planner contracts in
/// this module.
///
/// Return type is a directive ([ColonialLiteNavalPlan]) rather than a
/// `List<NavalMoveOrder>` / `List<NavalMissionOrder>` for parity with
/// [planColonialMilitary] / [planExpandMilitary]: the orchestrator owns
/// the actual order envelope (suggestion-API validation, fleet selection,
/// destination resolution via topology) while the planner owns the
/// deterministic decision of **which NW destinations to focus** the
/// existing colonial naval suggestions on this turn. Concretely the
/// orchestrator passes [priorityNwProvinceIdsSorted] to the existing
/// `newWorldSeaZonesAdjacentToInvadableProvinces` /
/// `sortNavalMovesForColonialPressure` helpers in
/// `colonial_naval_scoring.dart` so the ranked candidates already in
/// flight stay sorted by the same colonial-pressure score, just over
/// the COLONIAL-lite restricted province set. The cargo-routing arm in
/// the spec is satisfied at the orchestrator layer by the existing
/// colonial naval pathing the directive does not override (cargo moves
/// out of OW-owned ports toward OW stockpile are unaffected by this
/// NW-only directive).
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] by owner
///     faction (drop GP-owned, keep tribe / minor / unowned).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the NW-only
///     candidate pool that the perception-snapshot builder already
///     restricts to provinces visible to the active player).
///
/// Filter pipeline (each stage is structural, not configurable):
///   1. **Missing active player** -> [defaultPlan] (the planner cannot
///      compute a per-player naval directive without an owning
///      [Player]; matches the symmetric guard in [planColonialLiteOvertures]
///      and [planColonialMilitary]).
///   2. **Empty NW invadable** -> [defaultPlan] (structural short-circuit
///      so an empty constraint never leaks to the orchestrator and the
///      orchestrator's free-choice colonial naval pipeline keeps
///      running over its legacy candidate set).
///   3. **GP-owned filter** -> drop any candidate province whose owner
///      resolves to a [Player] via [Game.playerById]. GP-owned NW
///      invadable is structurally excluded because COLONIAL-lite is
///      the safeguard for tribe / minor NW penetration only (the spec
///      explicitly suppresses NW `declareWar` here, and NW
///      declare-war + invasion is the only context for which a GP
///      could legitimately appear as a COLONIAL-lite naval target).
///   4. **Orphan-owner filter** -> drop provinces whose owner does not
///      appear in [getProvinceOwnerMap] (defensive pin for the
///      `if (owner == null) continue` branch).
///   5. **Empty after filter** -> [defaultPlan] (priority-arm
///      fall-through: no tribe / minor faction owns NW invadable, so
///      the orchestrator falls back to its legacy free-choice
///      colonial naval behaviour over the full NW invadable set).
///   6. **Sort ascending** -> deterministic list output (Refs #2509
///      Must-have #7).
///
/// Output:
///   - [ColonialLiteNavalPlan] with the tribe / minor-owned NW invadable
///     provinces sorted ascending in [priorityNwProvinceIdsSorted] and
///     the corresponding owner faction ids sorted ascending and
///     deduplicated in [priorityTargetOwnerFactionIdsSorted] when at
///     least one tribe / minor owns an NW invadable province.
///   - [ColonialLiteNavalPlan.defaultPlan] for the outer guards
///     (missing player, empty NW invadable) and for the priority-arm
///     fall-through (no tribe / minor faction contributes any NW
///     invadable province).
///
/// Structural suppressions: this function reads only
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW-only by
/// builder contract). It never reads
/// [ConquestSummary.invadableProvinceIdsSorted], so an Old World
/// province cannot appear in the plan even when the snapshot exposes
/// one. The "Never suggest invasion transport or NW army staging here"
/// rule is enforced **structurally** by the absence of any army /
/// transport-staging slot on the plan: the orchestrator wiring is
/// limited to passing [priorityNwProvinceIdsSorted] to the colonial
/// naval helpers in `colonial_naval_scoring.dart`, which emit
/// exploration / cargo moves only. Adding a transport-staging slot
/// would be a breaking SPEC change; this slice deliberately keeps the
/// plan shape minimal so no caller can backslide into invasion-style
/// orders under the COLONIAL-lite label.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ColonialLiteNavalPlan]s (Refs #2509 Must-have #7).
ColonialLiteNavalPlan planColonialLiteNaval({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialLiteNavalPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialLiteNavalPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);
  final priorityProvinces = <String>[];
  final priorityOwners = <String>{};
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (game.playerById(owner) != null) continue;
    priorityProvinces.add(pid);
    priorityOwners.add(owner);
  }
  if (priorityProvinces.isEmpty) {
    return ColonialLiteNavalPlan.defaultPlan;
  }
  priorityProvinces.sort();
  final owners = priorityOwners.toList()..sort();
  return ColonialLiteNavalPlan(
    priorityNwProvinceIdsSorted: List<String>.unmodifiable(priorityProvinces),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}

/// Returns deterministic `build_improvement` work orders for the active
/// player's idle Builder units, ranked by extractable-tile priority and
/// restricted to **New World** owned land for COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialCivilian,
/// also Suppressions § "No OW build_improvement except tiles needed for
/// port/supply to active NW objectives"):
///
///   "Returns: List<WorkOrder> (NW purchase_land, NW improvements)."
///
/// This slice covers the **NW improvements** half of that contract.
/// `purchase_land` toward unowned NW tiles is the responsibility of
/// [planColonialAcquisition]. The narrow OW
/// port/supply allowance noted in the spec ("except tiles needed for
/// port/supply to active NW objectives") is also deferred — no caller
/// consumes the planner pre-S5 wiring, and tightening that exception
/// requires the orchestrator's active-NW-objective set which lives in
/// `planColonialAcquisition` / `planColonialMilitary` (neither in
/// place today). Suppressing OW improvements unconditionally here is
/// the structural COLONIAL-phase default the spec mandates; the
/// follow-up slice will broaden the gate when active-NW-objective
/// state becomes available.
///
/// Filtering (structural gates from issue #2509 COLONIAL planner spec):
///   1. Province must be in the **New World** region
///      ([Province.regionId] == [kNewWorldRegionId]).
///   2. Province must be owned by the active player
///      ([AIWorldSnapshot.playerId]).
///   3. Tile must carry a non-empty resource id in
///      [WorldState.resourceByTileKey] (extractable resource tile).
///   4. Tile must not be the province's town tile
///      ([Province.townTileKey]); town and capital tiles do not carry
///      resources per `SPEC/game/extraction-and-improvements.md`
///      § Town and capital tile occupancy, but the explicit exclusion
///      pins the contract against future model changes (mirrors the
///      pin in `planDevelopCivilian`).
///   5. Tile's existing improvement level
///      ([TileMapState.improvementLevel]) must be `< 1`.
///
/// Ranking (deterministic; ties broken lexicographically by tile key):
///   - Base score per extractable tile:
///     `kBuildImprovementExtractableResourceScore`.
///   - `+kBuildImprovementNewWorldResourceBonus` (always present here
///     because every eligible tile is in the NW region by gate #1).
///   - `+kBuildImprovementOwnedNewWorldResourceBonus` (always present
///     here because every eligible tile is on owned NW land by gate
///     #2). The orchestrator-facing score is therefore uniform across
///     eligible tiles; the planner falls back to lex tile-key tie-break
///     for deterministic ordering. The score constants are kept in the
///     ranking key (rather than collapsing to a single constant) so the
///     COLONIAL planner remains consistent with `planDevelopCivilian`
///     should later tuning introduce additional NW-only bonuses.
///
/// Builder selection: every active-player [Unit] with
/// `type == kUnitTypeBuilder` and `status == UnitStatus.idle` is included
/// regardless of current region — a Builder in the Old World can still
/// be assigned to a NW improvement directive; the orchestrator and
/// resolver handle the movement / staging on subsequent turns. Builders
/// are sorted ascending by `unit.id` and paired one-to-one with the
/// top-priority eligible tiles
/// (`pairCount = min(idleBuilders, eligibleTiles)`). Distance-aware
/// pairing is deferred to follow-up tuning under #2509 S5 (orchestrator
/// wiring) / S7 (observer integration), matching the convention
/// established by `planDevelopCivilian`.
///
/// Output: a new `List<WorkOrder>` of at most
/// `min(idleBuilders, eligibleNwTiles)` entries, each with
/// `target == kWorkTargetBuildImprovement`. Empty when no idle Builders,
/// no owned NW provinces, or no eligible NW resource tiles exist. The
/// function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<WorkOrder> planColonialCivilian({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final playerId = snapshot.playerId;
  final world = game.worldState;

  final ownedNwProvinceIds = <String>{};
  final townTileKeys = <String>{};
  for (final province in world.newWorld.provinces) {
    if (province.ownerId != playerId) continue;
    ownedNwProvinceIds.add(province.id);
    final townTileKey = province.townTileKey;
    if (townTileKey != null && townTileKey.isNotEmpty) {
      townTileKeys.add(townTileKey);
    }
  }
  if (ownedNwProvinceIds.isEmpty) {
    return const [];
  }

  final builders = <Unit>[
    for (final unit in allUnitsFromWorld(world))
      if (unit.ownerId == playerId &&
          unit.type == kUnitTypeBuilder &&
          unit.status == UnitStatus.idle)
        unit,
  ]..sort((a, b) => a.id.compareTo(b.id));
  if (builders.isEmpty) {
    return const [];
  }

  final tileState = world.tileState;
  final eligibleTileKeys = <String>[];
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (Unit.regionIdFromTileKey(tileKey) != kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId == null || !ownedNwProvinceIds.contains(provinceId)) {
      continue;
    }
    if (townTileKeys.contains(tileKey)) continue;
    if (tileState.improvementLevel(tileKey) >= 1) continue;
    eligibleTileKeys.add(tileKey);
  }
  if (eligibleTileKeys.isEmpty) {
    return const [];
  }

  eligibleTileKeys.sort((a, b) {
    final scoreCmp = _colonialCivilianTileScore(
      b,
    ).compareTo(_colonialCivilianTileScore(a));
    if (scoreCmp != 0) return scoreCmp;
    return a.compareTo(b);
  });

  final pairCount = eligibleTileKeys.length < builders.length
      ? eligibleTileKeys.length
      : builders.length;
  return <WorkOrder>[
    for (var i = 0; i < pairCount; i++)
      WorkOrder(
        unitId: builders[i].id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: eligibleTileKeys[i],
      ),
  ];
}

/// Deterministic priority score for an eligible NW tile in
/// [planColonialCivilian].
///
/// Every tile that survives the structural gates in [planColonialCivilian]
/// is NW + owned-NW by construction, so this score collapses to a single
/// constant in the current implementation. Keeping the additive form
/// (rather than inlining a literal) preserves consistency with the
/// per-tile component of `_developCivilianTileScore` and stays robust
/// against future ranking tweaks that introduce per-tile NW differentiators.
int _colonialCivilianTileScore(String tileKey) {
  // Tile is structurally NW + owned-NW once we reach this comparator
  // (see eligibility gates 1 and 2 in [planColonialCivilian]); the
  // bonus additions are explicit so the score formula stays parallel
  // to `_developCivilianTileScore` in `develop_phase_planner.dart`.
  return kBuildImprovementExtractableResourceScore +
      kBuildImprovementNewWorldResourceBonus +
      kBuildImprovementOwnedNewWorldResourceBonus;
}
