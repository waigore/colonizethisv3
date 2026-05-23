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
/// planner for the full set, including the deferred
/// `planColonialMilitary`, `planColonialNaval`, `planColonialLiteOvertures`,
/// and `planColonialLiteNaval`):
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
///     ([planColonialAcquisition] Join-Empire path; `purchase_land` and
///     [planColonialMilitary] NW conquest army moves deferred to follow-up
///     S3 slices) rather than reasoned about here.
///
///   `planColonialAcquisition(game, snapshot) → ColonialAcquisitionTarget?`
///     Returns the deterministic Join-Empire acquisition target for the
///     active COLONIAL player when one is achievable this turn, or
///     `null` when no Join-Empire target is reachable. Iterates over
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] in sorted
///     order (adjacency-distance reordering deferred to a follow-up
///     slice — see § planColonialAcquisition for the spec ordering)
///     and returns the first NW province whose tribe/minor owner has
///     an `OvertureState.nap` with the active player, Friendly+
///     relations, and treasury covering [joinEmpireCostForMinorOrTribe].
///     The `purchase_land` and `declareWar` acquisition methods from
///     issue #2509 § planColonialAcquisition § Acquisition method 2/3
///     are deferred to follow-up S3 slices (idle-Merchant scan and
///     sea-reachability + regiment-build gates respectively); this
///     slice carries **only** the Join-Empire path so the orchestrator
///     (#2509 S5) can begin consuming the Join-Empire signal without
///     waiting for the full acquisition pipeline. Returning `null` when
///     Join Empire is unavailable preserves the legacy fall-through
///     behaviour (no acquisition order emitted) until follow-up slices
///     wire the remaining methods.
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
/// functions (`planColonialAcquisition`, `planColonialMilitary` —
/// deferred to follow-up S3 slices) rather than reasoned about here.
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
/// path and the target is sea-reachable. Only [joinEmpire] is emitted
/// by [planColonialAcquisition] in this slice — [purchaseLand] and
/// [declareWar] remain enum entries so the contract is stable across
/// follow-up S3 slices but are not yet returned.
enum AcquisitionMethod {
  /// `establishOverture` advancing the chain to `joinEmpire`. The
  /// fastest, cheapest acquisition path (issue #2509 § Acquisition
  /// method 1).
  joinEmpire,

  /// `purchase_land` work order for an idle Merchant unit (issue
  /// #2509 § Acquisition method 2). Reserved for a follow-up slice.
  purchaseLand,

  /// `declareWar` + NW army move toward a sea-reachable tribe / minor
  /// (issue #2509 § Acquisition method 3). Reserved for a follow-up
  /// slice.
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

  /// Resolution path the orchestrator should use. Always
  /// [AcquisitionMethod.joinEmpire] in this slice;
  /// [AcquisitionMethod.purchaseLand] and [AcquisitionMethod.declareWar]
  /// are reserved for follow-up slices and never appear in returns
  /// produced by [planColonialAcquisition] today.
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

/// Returns the deterministic Join-Empire acquisition target for the
/// active COLONIAL player this turn, or `null` when no Join-Empire
/// target is achievable.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialAcquisition,
/// Acquisition method 1):
///
///   "Join Empire
///      → Conditions: embassy with owning tribe, treasury ≥ cost.
///      → Generate establishOverture(tribe) targeting Join Empire chain.
///      → This is the cheapest, fastest path — always preferred first."
///
/// The "embassy with owning tribe" phrasing in the issue body is
/// tightened here to align with the order-engine validator in
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
/// Iteration ordering:
///   - Walks [ColonialSummary.invadableNewWorldProvinceIdsSorted] in
///     the sorted order provided by the perception snapshot. The
///     issue body asks for adjacency-distance ordering ("sorted by
///     adjacency distance to owned territory"); that re-ranking is
///     deferred to a follow-up slice — switching the iteration to an
///     adjacency-distance key changes which Join-Empire target wins on
///     ties but does not change the gate set this slice pins.
///     `invadableNewWorldProvinceIdsSorted` is itself sorted ascending
///     by the snapshot builder, so the iteration is deterministic
///     today (Refs #2509 Must-have #7).
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard, looks up the province-owner map
///     ([getProvinceOwnerMap]) to find each NW province's current
///     owner, queries [getOverture] / [getRelation] for the gate
///     evaluation, and computes [joinEmpireCostForMinorOrTribe] for
///     the treasury check.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the
///     candidate NW province pool) and [EconomySummary.treasury] (the
///     active player's spendable cash for the Join-Empire payment).
///
/// Output:
///   - [ColonialAcquisitionTarget] with [AcquisitionMethod.joinEmpire]
///     when the first NW province in
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] whose
///     owner satisfies the four Join-Empire gates (overture stage =
///     [OvertureStage.nap], relation score ≥ [relationScoreMinFriendly],
///     treasury ≥ [joinEmpireCostForMinorOrTribe], owner is a
///     tribe / minor and not a Great Power).
///   - `null` when no NW province satisfies all four gates, or when
///     the outer guards trip (missing active player record, empty NW
///     invadable list). The follow-up `purchase_land` /
///     `declareWar` slices will replace this null fall-through with
///     their own acquisition methods; consumers must treat `null` as
///     "no acquisition order this turn" rather than "acquisition path
///     impossible".
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
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
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

  return null;
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
/// `planColonialAcquisition` (deferred S3 slice). The narrow OW
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
