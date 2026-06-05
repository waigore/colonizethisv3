/// EXPAND-phase planner (Refs #2509 S2 / S10).
///
/// Phase planner module from the single-goal architecture in
/// [GitHub issue #2509](https://github.com/waigore/colonizethisv3/issues/2509)
/// and `SPEC/ai/ai-architecture.md` § Observer goal phases. The planner is a
/// pure-function module that makes one primary decision per domain with no
/// cross-phase score aggregation.
///
/// EXPAND phase goal: reach `kObserverConquestMinOwProvincesPerGp` Old World
/// provinces. All NW code is structurally bypassed — the EXPAND planner never
/// imports `colonial_phase_planner.dart`, never queries [ColonialSummary],
/// never generates NW `declareWar` / `establishOverture` /
/// `purchase_land` / `build_improvement`, and never queues NW conquest army
/// moves. Suppression is an architectural property of the module, not a
/// runtime predicate check (Refs #2509 § EXPAND phase planner Suppressions).
/// The structural NW-suppression AC for the planner **set as a whole**
/// (issue #2509 § Phase planner unit tests § "EXPAND NW suppression";
/// `SPEC/ai/phase-planner-architecture.md` § Acceptance criteria) is
/// pinned in `test/planning/expand_phase_planner_nw_suppression_test.dart`,
/// which exercises all four EXPAND planners (`planExpandDeclareWar`,
/// `planExpandPeace`, `planExpandEconomy`, `planExpandMilitary`) against a
/// NW-rich fixture and asserts the merged output set carries no NW orders.
///
/// Callers are expected to dispatch to this module **only** when
/// `observerGoalPhaseFor` resolves to `ObserverGoalPhase.expand`; the planner
/// functions themselves do not re-check the phase, matching the convention
/// established by `develop_phase_planner.dart` (Refs #2509 S4).
///
/// Orchestrator wiring (#2509 S5) is now in place: `phase_planner_dispatch.dart`
/// calls `planExpandPeace`, `planExpandDeclareWar`, `planExpandEconomy`, and
/// `planExpandMilitary` for every EXPAND-phase player and threads the result
/// through `PhasePlanOutcome`; `domain_planner_orchestrator.dart` consumes the
/// outcome via `gpPeaceTargetsFromPhasePlan` /
/// `gpExpandDeclareWarTargetFromPhasePlan` so EXPAND domain decisions reach
/// the resolver without re-checking the phase. The legacy
/// `expandPhaseGpPeaceTargets` helper still lives in
/// `observer_goal_phase.dart` because the no-`phasePlan` fallback path through
/// `collectStalledGreatPowerPeaceTargets` keeps it on the production hot path
/// alongside the EXPAND ratchet aggregator; `colonial_pressure.dart` and
/// `diplomacy_planner_peace_targets.dart` were removed in #2509 S1, with their
/// helpers canonical here (and in `observer_goal_phase.dart` for the
/// cross-phase composite peace aggregators). Both `expandPhaseGpPeaceTargets`
/// and `planExpandPeace` are pinned at the function-unit level.
///
/// In-module contracts shipped to date (see issue #2509 § EXPAND phase
/// planner for the full set):
///
///   `planExpandPeace(game, snapshot) → List<String>`
///     Returns the deterministic list of at-war Great Powers the active
///     player should `offerPeace` toward in EXPAND. Defaults to peacing
///     **all** at-war GPs except the GP owning the primary invadable Old
///     World frontier (`primaryInvadableOldWorldGpBlocker`). The lone GP
///     blocker is also peaced when the war is a mutual-plateau sole-GP
///     stalemate on a GP-only invadable frontier with no uninvaded OW
///     minors remaining (Refs #2509 § EXPAND phase planner § planExpandPeace
///     "peace to exit stalemate").
///
///   `planExpandDeclareWar(game, snapshot) → String?`
///     Returns the deterministic factionId of the next declare-war target
///     for the active EXPAND player, scanning [ConquestSummary]
///     `invadableProvinceIdsSorted` in priority order: (1) adjacent
///     minor not yet at war, (2) already-at-war minor (formalize war so
///     conquest army-move pass fires), (3) sole GP frontier blocker on a
///     GP-only mutual-plateau frontier when our regiment count and
///     treasury cover engagement. Returns `null` when no priority arm
///     applies (Refs #2509 § EXPAND phase planner § planExpandDeclareWar).
///     The "suggestDeclareWarOrders rejects" runtime gate noted in the
///     spec is enforced at the orchestrator layer (#2509 S5) so this
///     module remains a pure-function planner.
///
///   `planExpandEconomy(game, snapshot) → ExpandEconomyPlan`
///     Returns the EXPAND-phase economy directive for the active player:
///     `forceCheapestRegimentBuild` (set the orchestrator build threshold
///     to zero and pick the cheapest regiment in
///     [RegimentEconomyCatalog]) and / or `boostTreasuryRecoveryCargo`
///     (raise economy weight for overseas cargo so riches deliver to
///     stockpile before the next build pass). Implements the
///     three-arm decision tree from issue #2509 § EXPAND phase planner
///     § planExpandEconomy (zero-regiment rebuild, insufficient-regiment
///     rebuild with affordable treasury, treasury-recovery cargo boost).
///     Effective treasury is `Player.treasury` plus
///     [pendingRichesTreasuryDelta] so the planner aligns with build
///     validation that already credits same-turn `richesToTreasury`
///     phase income (Refs #2509 § Observer goal phases § EXPAND
///     "Pending riches treasury").
///
///   `planExpandMilitary(game, snapshot, declaredWarTargetFactionId)
///                                                  → ExpandMilitaryPlan`
///     Returns the deterministic OW-only conquest destination filter for
///     the active EXPAND player. The plan carries the priority subset of
///     [ConquestSummary.invadableProvinceIdsSorted] (always OW by
///     construction — see `_invadableOldWorldProvinceIds` in the
///     perception snapshot builder) that conquest army moves should
///     target this turn: provinces owned by the declare-war target when
///     one was chosen, otherwise provinces owned by any at-war faction.
///     Returns [ExpandMilitaryPlan.defaultPlan] (no constraint) for the
///     outer EXPAND guards (at quota, missing player, empty invadable
///     frontier) and for the priority arms that resolve to an empty
///     province set; the orchestrator (#2509 S5) treats `defaultPlan`
///     as "free choice within OW invadable" and a non-default plan as
///     "restrict conquest army moves to this subset" (Refs #2509 §
///     EXPAND phase planner § planExpandMilitary "Use existing
///     runConquestArmyMovePlanner with EXPAND-only destination filter").
///     Structural NW suppression: the planner never reads
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] so a New
///     World invadable province cannot appear in the plan even if the
///     snapshot exposes one.
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    as regiment_catalog
    show cheapestRegimentBuildTreasuryCost;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'planning_helpers.dart' show gpFactionIdsAtWarWith;

part 'expand_phase_planner_peer_peace.dart';
part 'expand_phase_planner_gp_blocker_peace.dart';
part 'expand_phase_planner_feedstock_acquisition.dart';
part 'expand_phase_planner_economy.dart';
part 'expand_phase_planner_military.dart';
part 'expand_phase_planner_peace_targets.dart';
part 'expand_phase_planner_peace_default_start.dart';

/// Returns the deterministic list of at-war Great Powers the active player
/// should `offerPeace` toward this turn while in EXPAND phase.
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandPeace, extended
/// by issue #2847 § H4 § H4-a):
///
///   "Peace ALL at-war Great Powers, with ONE exception:
///    → Keep fighting the GP that owns the primary invadable OW frontier
///      blocker (primaryInvadableOldWorldGpBlocker), UNLESS:
///      - It's a mutual-plateau sole GP war on a GP-only cleared frontier
///        with no uninvaded minors (peace to exit stalemate), OR
///      - The sole at-war GP is the only owner of OW provinces adjacent to
///        the active player's territory (geographic peer-war lock) and both
///        sides are in the mutual-plateau below-quota band — the uninvaded
///        OW minor pivot is unreachable from the active player's anchors,
///        so the minor-pivot guard is irrelevant (Refs #2847 § H4-a)."
///
/// Inputs:
///   - [game]: used to (a) filter [ThreatSummary.atWarWith] down to Great
///     Power factions via [Game.playerById]; (b) compute the primary OW
///     frontier blocker by mapping invadable OW provinces to current
///     owners; (c) detect uninvaded OW minors still in play; (d) check
///     whether the invadable OW frontier is held only by GPs (no minor
///     border).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith], [ConquestSummary.invadableProvinceIdsSorted],
///     [ConquestSummary.adjacentOwnerFactionIdsSorted], and
///     [ConquestSummary.oldWorldProvincesOwned] for the mutual-plateau
///     comparison.
///
/// Output:
///   - Empty list when no Great Powers are at war with the active player.
///   - Empty list when the sole at-war GP **is** the primary OW invadable
///     blocker and neither carve-out applies (keep fighting the blocker;
///     default EXPAND posture).
///   - All GPs sorted ascending when the primary blocker is `null` or not
///     among the at-war GPs (peace ALL: the legacy "no exception applies"
///     case).
///   - All GPs except the blocker sorted ascending when the blocker is
///     among the at-war GPs and no carve-out fires (peace ALL
///     except the blocker).
///   - The single GP (still sorted as a 1-element list) when the
///     mutual-plateau sole-GP carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the stalled below-quota plateau band
///     ([isMutualBelowQuotaPlateauPeer]), the invadable frontier is
///     GP-only ([expandIsOldWorldGpOnlyInvadableFrontier]), and no uninvaded
///     OW minors remain ([hasUninvadedOldWorldMinor] is false).
///   - The single GP (still sorted as a 1-element list) when the
///     geographic peer-war lock carve-out fires: exactly one GP at war,
///     that GP owns the primary OW invadable blocker, both sides are in
///     the mutual-plateau below-quota band, and
///     [ConquestSummary.adjacentOwnerFactionIdsSorted] is exactly
///     `[blocker]` — the at-war peer GP is the only faction owning OW
///     provinces adjacent to the active player's anchors, so any
///     uninvaded OW minor is geographically unreachable (Refs #2847
///     § H4-a).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<String> planExpandPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.isEmpty) {
    return const [];
  }

  final blocker = expandPrimaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return gpWars..sort();
  }

  if (gpWars.length == 1 &&
      isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(game, blocker),
      )) {
    if (expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: blocker)) {
      return List<String>.unmodifiable(gpWars);
    }
    if (expandIsOldWorldGpOnlyInvadableFrontier(
          game: game,
          snapshot: snapshot,
        ) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return List<String>.unmodifiable(gpWars);
    }
  }

  return <String>[
    for (final factionId in gpWars)
      if (factionId != blocker) factionId,
  ]..sort();
}

/// Whether the active player is in a geographic peer-war lock against
/// [peerGpId] — exactly one Great Power foe owns every Old World province
/// adjacent to the active player's territory (Refs #2847 § H4-a).
///
/// When this predicate fires, the uninvaded OW minor pivot guarded by
/// [hasUninvadedOldWorldMinor] is irrelevant for the EXPAND peace
/// decision: uninvaded minors exist on the wider map but none of them
/// are reachable from the active player's anchors (their provinces are
/// not in [ConquestSummary.adjacentOwnerFactionIdsSorted]). The
/// canonical [planExpandPeace] arm pairs this geographic check with
/// [isMutualBelowQuotaPlateauPeer] so the mutual-plateau stalemate is
/// peaced even when minors are still alive somewhere on the map but
/// outside the active player's reach (seed-42 gp3↔gp4 and gp5↔gp6
/// mid-game lock; the failing GPs spent 45–53 turns at war with their
/// peer with no minor-frontier route through their own territory).
///
/// Returns `false` when [ConquestSummary.adjacentOwnerFactionIdsSorted]
/// is empty (no OW adjacency at all — no lock to break), when it
/// contains more than one entry (the active player has another OW
/// neighbor that may still be reachable), or when its single entry is
/// not [peerGpId] (some other faction owns the OW frontier).
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Constant-time on the adjacency
/// list length (single equality check); no global province / tile
/// scans introduced, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
bool expandIsGeographicPeerWarLock({
  required AIWorldSnapshot snapshot,
  required String peerGpId,
}) {
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return false;
  }
  return adjacentOwners.single == peerGpId;
}

/// Number of turns the EXPAND declare-war planner suppresses a re-declaration
/// against a Great Power immediately after a peace event involving the
/// active player and that peer (Refs #2847 § H2).
///
/// Mirrors the per-pair `warCooldownTurns = 4` value used by
/// `diplomatic_candidate_scoring.dart` for declare-war scoring cooldowns.
/// Kept as a file-private constant here (not in
/// `colonizethis_data/ai_victory_config.dart`) so the issue's scope
/// constraint "no new config constants" stays satisfied while the
/// planner-side cooldown remains independently testable.
///
/// The constant is matched by the public helper
/// [expandRecentlyPeacedWithGreatPower]'s default and the
/// [planExpandDeclareWar] arm-3 cooldown gate; tests pass the same value
/// explicitly so accidental drift in either direction surfaces as a
/// failing pin.
const int kExpandPeerWarPeaceCooldownTurns = 4;

/// Whether the active player and [peerGpId] completed a peace event within
/// the last [cooldownTurns] turns (Refs #2847 § H2).
///
/// The EXPAND declare-war planner uses this predicate to suppress the
/// priority-3 sole-GP-blocker re-declaration after the planExpandPeace
/// H4-a carve-out exits a mutual-plateau peer-war: without the cooldown,
/// the next turn's `planExpandDeclareWar` arm 3 would re-declare against
/// the same peer (treasury and regiment gates pass; the only `at-war`
/// guard is now false because peace just landed). The cooldown keeps
/// both peers locked in peace long enough for one side to drop out of
/// the geographic peer-war lock band (build regiments via the H3 arm,
/// pivot via a freshly-reachable minor, or exit the mutual-plateau
/// gate by gaining provinces elsewhere) before the war reopens.
///
/// Looks at [Game.diplomaticHistoryEvents] (already ordered ascending by
/// turn / intra-turn index) for the most-recent peace event whose
/// `participants` set contains both the active player and [peerGpId].
/// The check is symmetric: the helper does not require the active
/// player to have been the second-leg-of-mutual-peace offerer. Either
/// side's offerPeace order can produce the canonical
/// [DiplomaticEventType.peace] event.
///
/// Returns `false` when no peace event between the pair exists, when
/// the most-recent peace event is at least [cooldownTurns] turns old,
/// or when [cooldownTurns] is non-positive (caller can disable the
/// cooldown without restructuring the arm).
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the diplomatic history
/// length in the worst case, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
bool expandRecentlyPeacedWithGreatPower({
  required Game game,
  required String activePlayerId,
  required String peerGpId,
  required int currentTurn,
  int cooldownTurns = kExpandPeerWarPeaceCooldownTurns,
}) {
  if (cooldownTurns <= 0) return false;
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (event.type != DiplomaticEventType.peace) continue;
    if (!event.participants.contains(activePlayerId)) continue;
    if (!event.participants.contains(peerGpId)) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}

/// Whether [planExpandEconomy] should widen the insufficient-regiment
/// force-build arm (Arm D) under the EXPAND-trap (Refs #2847 § H3).
///
/// Fires when the active player owns zero New World provinces and the
/// geographic peer-war lock predicate holds for the sole OW adjacent
/// Great Power. The cargo-recovery boost in Arm C is left to fire
/// independently (the cargo signal is the planner-output the resource-
/// need NW=0.60 weight floor in `phase_priority_weights.dart` consumes
/// per § Resource-need overrides; suppressing it under the lock would
/// also disable the override the soft-phase design depends on).
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7).
bool expandIsGeographicPeerWarLockNoNwTreasuryRecovery({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.colonial.newWorldProvincesOwned > 0) {
    return false;
  }
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return false;
  }
  final peerGpId = adjacentOwners.single;
  if (game.playerById(peerGpId) == null) {
    return false;
  }
  return expandIsGeographicPeerWarLock(snapshot: snapshot, peerGpId: peerGpId);
}

/// GP owning the most invadable Old World provinces (frontier blocker).
///
/// Public entry for the phase dispatcher and orchestrator wiring (Refs
/// #2509 S5). Mirrors the existing `primaryInvadableOldWorldGpBlocker`
/// algorithm in `colonial_pressure.dart` so the new planner stays
/// self-contained against the S1 deletion of that file (Refs #2509 §
/// EXPAND phase planner). Behavior is byte-identical to the legacy helper:
///
///   1. Tally GP ownership across [ConquestSummary.invadableProvinceIdsSorted]
///      using [getProvinceOwnerMap], skipping unowned and non-GP entries.
///   2. Resolve the plurality winner with a second linear pass that
///      preserves the first-iterated-province tiebreak (deterministic
///      against the snapshot's already-sorted invadable list).
///
/// Returns `null` when the invadable list is empty or none of the
/// invadable provinces are owned by a Great Power. Linear in the
/// invadable-OW set, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
String? expandPrimaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final counts = <String, int>{};
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) continue;
    counts[owner] = (counts[owner] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null) continue;
    final count = counts[owner];
    if (count == null) continue;
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// Canonical name for [expandPrimaryInvadableOldWorldGpBlocker] (Refs #2509 S1).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expandPrimaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot);

/// Whether the invadable Old World frontier is held only by Great Powers
/// (no minor nation owns any invadable OW province).
///
/// Mirrors `isOldWorldGpOnlyInvadableFrontier` from `colonial_pressure.dart`.
/// Public entry for the phase dispatcher and orchestrator wiring (Refs
/// #2509 S5). The mutual-plateau sole-GP carve-out in [planExpandPeace]
/// requires this gate so we only peace the lone GP blocker when no minor
/// pivot remains.
bool expandIsOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return false;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any((
    pid,
  ) {
    final owner = provinceOwner[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
  if (minorsOwnInvadable) {
    return false;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any(
    (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
  );
}

/// Canonical name for [expandIsOldWorldGpOnlyInvadableFrontier] (Refs #2509 S1).
bool isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expandIsOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// Whether any Old World minor nation still holds provinces and is not
/// already at war with the active player (uninvaded minor pivot remaining).
///
/// The mutual-plateau sole-GP carve-out in [planExpandPeace] holds the GP war
/// while uninvaded minors remain (we should expand against minors first).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the predicate
/// survives the planned deletion of that file.
bool hasUninvadedOldWorldMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  for (final minor in game.minorNations) {
    if (snapshot.threats.atWarWith.contains(minor.id)) {
      continue;
    }
    if (game.worldState.oldWorld.provinces.any((p) => p.ownerId == minor.id)) {
      return true;
    }
  }
  return false;
}

/// Returns the `factionId` of the sole Great Power the active player is at
/// war with, or `null` when the at-war set is empty, contains only minor /
/// tribe ids, or contains more than one Great Power.
///
/// Canonical home (Refs #2509 S1) for the legacy `soleAtWarGreatPowerId`
/// predicate previously hosted in `colonial_pressure.dart`. Captures the
/// "exactly one GP foe remaining" precondition shared by the EXPAND-phase
/// sole-GP peace deciders ([unwinnableSoleGpFrontierPeaceTarget],
/// [consolidateGainsSoleGpPeaceTarget]) and the peer-stalled peace
/// helper `belowQuotaPeerGpPeaceTargets` — all of which short-circuit to
/// the default no-peace path when no sole-GP foe is identified.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_sole_at_war_gp_branches_test.dart`
/// fixture, the existing `belowQuotaPeerGpPeaceTargets` /
/// `unwinnableSoleGpFrontierPeaceTarget` / `consolidateGainsSoleGpPeaceTarget`
/// callers within `colonial_pressure.dart` itself) so the planned S1
/// deletion of that file leaves no orphan callers.
///
/// Behavioral invariants pinned at the canonical-home test boundary
/// (`test/planning/expand_phase_planner_sole_gp_war_helpers_test.dart`):
///   1. Empty [ThreatSummary.atWarWith] returns `null` (no foe at all).
///   2. At-war entries that are not current Great Powers
///      ([Game.playerById] returns `null`) are filtered out before the
///      length-one check — pure minor / tribe wars therefore yield
///      `null`.
///   3. The length guard refuses to elect a sole-GP foe when more than
///      one Great Power is at war; a mixed two-GP-plus-minor at-war
///      list still resolves to `null` after the minor filter collapses
///      the list to two GPs.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith].
String? soleAtWarGreatPowerId({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1) {
    return null;
  }
  return gpWars.single;
}

/// Whether [ownOw] and [partnerOw] are both in the stalled below-quota
/// plateau band with similar holdings (within one province of each other).
///
/// Stall threshold ([kStalledOldWorldProvinceThreshold]) and quota
/// ([kObserverConquestMinOwProvincesPerGp]) are authoritative here.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1).
bool isMutualBelowQuotaPlateauPeer({
  required int ownOw,
  required int partnerOw,
}) =>
    isStalledOldWorldExpansion(ownOw) &&
    isStalledOldWorldExpansion(partnerOw) &&
    isBelowObserverConquestQuota(ownOw) &&
    isBelowObserverConquestQuota(partnerOw) &&
    (partnerOw - ownOw).abs() <= 1;

/// Below-quota OW expansion with a GP-only invadable frontier (seed-42 gp5/gp6).
///
/// Composite gate combining [isBelowObserverConquestQuota] on the active
/// player's [ConquestSummary.oldWorldProvincesOwned] with
/// [isOldWorldGpOnlyInvadableFrontier]: returns `true` only when the GP is
/// strictly below [kObserverConquestMinOwProvincesPerGp] **and** every
/// invadable OW province is owned by a Great Power (no minor pivot
/// remaining on the frontier).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the predicate
/// survives the planned deletion of that file. Fans out across the
/// EXPAND/COLONIAL goal-scoring and diplomacy-planner call sites
/// (`phase_planner_economy_filter.dart`, `phase_planner_goal_filter.dart`,
/// `diplomacy_planner.dart`, `diplomacy_planner_peace_targets.dart`,
/// `diplomatic_candidate_scoring_*.dart`) that gate the colonial-pressure
/// routing and sole-GP-war scoring on the GP-only-frontier shape.
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
    isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot);

/// Returns the deterministic factionId of the next declare-war target for
/// the active EXPAND player, or `null` when no priority arm applies.
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandDeclareWar):
///
///   "Priority-ordered scan of `invadableProvinceIdsSorted` (OW only).
///    Pick the first valid candidate:
///      1. Adjacent minor with uninvaded OW province
///      2. Already-at-war minor with uninvaded OW province
///      3. Sole GP frontier blocker (GP-only frontiers only, mutual
///         plateau, our regiments ≥ partner's, treasury ≥ regiment cost)
///      4. null — skip declaring."
///
/// The function is pure and deterministic — identical inputs always yield
/// identical results (Refs #2509 Must-have #7). Tiebreaks are
/// lexicographic ascending across factionIds within each priority arm.
///
/// Inputs:
///   - [game]: used to (a) resolve the active player via
///     [Game.playerById] for treasury and regiment-count gating; (b) walk
///     the province-owner map for minor-vs-GP partitioning of
///     [ConquestSummary.invadableProvinceIdsSorted]; (c) compute the lone
///     GP blocker's holdings for mutual-plateau and regiment comparisons.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ThreatSummary.atWarWith], [ConquestSummary.invadableProvinceIdsSorted],
///     [ConquestSummary.adjacentOwnerFactionIdsSorted], and
///     [ConquestSummary.oldWorldProvincesOwned].
///
/// Returns:
///   - `null` when [ConquestSummary.invadableProvinceIdsSorted] is empty
///     (no OW frontier to expand into).
///   - The lowest-id minor faction owning an invadable OW province and
///     present in [ConquestSummary.adjacentOwnerFactionIdsSorted] but not
///     in [ThreatSummary.atWarWith] (priority 1: adjacent minor scan),
///     **only** when `player.treasury >= cheapestRegimentBuildTreasuryCost`
///     so the conquest pass can fund the follow-up regiment. When the
///     treasury check fails arm 1 is skipped and priority 2 is consulted.
///   - The lowest-id minor faction owning an invadable OW province and
///     already in [ThreatSummary.atWarWith] (priority 2: formalize the
///     existing war so the conquest army-move pass fires). **No treasury
///     gate** applies here because the war is already open and existing
///     regiments commit on it — the global treasury hoist that suppressed
///     arm 2 in the seed-42 turn-100 trap is removed (Refs #2509 § EXPAND
///     § planExpandDeclareWar 10-turn trace).
///   - The single GP whose ownership covers the entire invadable OW
///     frontier (priority 3) when: the frontier is GP-only (no minor
///     holds an invadable OW tile), exactly one GP owns invadable
///     provinces, the active player's treasury is at or above
///     [cheapestRegimentBuildTreasuryCost], the active player has not
///     completed a peace event with that GP within the last
///     [kExpandPeerWarPeaceCooldownTurns] turns
///     ([expandRecentlyPeacedWithGreatPower] is `false`; Refs #2847
///     § H2 — prevents the H4-a peace carve-out from being undone on
///     the very next turn), both sides are mutual-plateau peers
///     ([isMutualBelowQuotaPlateauPeer]), and the active player's
///     regiment count is ≥ that GP's regiment count.
///   - `null` when none of the priority arms qualify.
///
/// The runtime "suggestDeclareWarOrders rejects" gate noted in the issue
/// spec is enforced at the orchestrator layer (#2509 S5) so this pure
/// function remains free of the order-suggestion API dispatch.
///
/// Feedstock-tile acquisition bias (Refs #2847 § EXPAND feedstock-tile
/// acquisition declare-war target bias; `SPEC/ai/economy-planner.md`): for a
/// flagged below-quota zero-NW lock-recovery seller, the within-arm
/// lexicographic tiebreak is redirected toward the faction owning the primary
/// conquest-reachable feedstock province returned by
/// [expandSellerFeedstockTileAcquisitionTarget] — but only when that owner is
/// already a candidate in the arm that fires this turn. Arm precedence and
/// every gate are unchanged, and the bias never fires for an unflagged GP, so
/// the +6 Old World conquest baseline GPs gp1/gp2 are never redirected.
String? planExpandDeclareWar({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) return null;
  final player = game.playerById(snapshot.playerId);
  if (player == null) return null;

  final atWarWith = snapshot.threats.atWarWith.toSet();
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted
      .toSet();
  final minorIds = <String>{for (final m in game.minorNations) m.id};
  final provinceOwner = getProvinceOwnerMap(game);

  // Priority 1: adjacent minor not yet at war.
  final adjacentNewWarMinors = <String>{};
  // Priority 2: already-at-war minor with invadable OW province.
  final atWarMinors = <String>{};
  // Priority 3 prep: tally GP ownership across invadable provinces.
  final gpInvadableCounts = <String, int>{};
  var anyMinorOnInvadable = false;
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!minorIds.contains(owner)) {
      if (game.playerById(owner) != null) {
        gpInvadableCounts[owner] = (gpInvadableCounts[owner] ?? 0) + 1;
      }
      continue;
    }
    anyMinorOnInvadable = true;
    if (atWarWith.contains(owner)) {
      atWarMinors.add(owner);
      continue;
    }
    if (adjacentOwners.contains(owner)) {
      adjacentNewWarMinors.add(owner);
    }
  }

  // The treasury floor is a per-arm skip clause in the issue spec
  // (§ EXPAND § planExpandDeclareWar): arm 1 (NEW declaration on an
  // adjacent minor) and arm 3 (NEW declaration on a sole GP blocker)
  // both require treasury for the follow-up regiment build; arm 2
  // (formalize an already-at-war minor) does NOT — the war is already
  // open and existing regiments can commit on it. Hoisting the gate to
  // the top of this function was the seed-42 turn-100 trap: when
  // treasury collapsed below `cheapestRegimentBuildTreasuryCost`,
  // arm 2 was suppressed even though the GP still had at-war minors
  // sitting on invadable OW provinces (Refs #2509 § 10-turn trace).
  final canAffordNewWar =
      player.treasury >= cheapestRegimentBuildTreasuryCost();

  // Refs #2847 § EXPAND feedstock-tile acquisition declare-war target bias
  // (`SPEC/ai/economy-planner.md`). A flagged below-quota zero-NW
  // lock-recovery seller redirects its within-arm declare-war tiebreak toward
  // the faction owning the primary conquest-reachable Old World feedstock
  // province it must acquire to source `lumber` / `castIron` domestically.
  // The bias only swaps the lexicographic pick *inside* the arm that already
  // fires when the feedstock owner is one of that arm's candidates — it never
  // reorders arm precedence, relaxes a gate, or fires for an unflagged GP
  // (`expandSellerFeedstockTileAcquisitionTarget` returns `null` for every
  // player whose acquisition residual is inactive, so the +6 Old World
  // conquest baseline GPs gp1/gp2 are never redirected). The detection scan is
  // computed lazily — only for an arm with two or more candidates, where a
  // tiebreak exists to redirect.
  String biasedArmPick(Set<String> armCandidates) {
    final sorted = armCandidates.toList()..sort();
    if (armCandidates.length < 2) return sorted.first;
    final feedstockProvinceId = expandSellerFeedstockTileAcquisitionTarget(
      game: game,
      snapshot: snapshot,
    );
    if (feedstockProvinceId == null) return sorted.first;
    final feedstockOwner = provinceOwner[feedstockProvinceId];
    if (feedstockOwner != null && armCandidates.contains(feedstockOwner)) {
      return feedstockOwner;
    }
    return sorted.first;
  }

  if (adjacentNewWarMinors.isNotEmpty && canAffordNewWar) {
    return biasedArmPick(adjacentNewWarMinors);
  }
  if (atWarMinors.isNotEmpty) {
    return biasedArmPick(atWarMinors);
  }

  // Priority 3: sole GP frontier blocker on GP-only mutual-plateau front.
  if (anyMinorOnInvadable) return null;
  if (gpInvadableCounts.length != 1) return null;
  final blockerId = gpInvadableCounts.keys.single;
  if (atWarWith.contains(blockerId)) {
    // Already at war — formalize is a no-op for GPs at this layer; the
    // declare-war target is `null` so we do not re-issue declareWar.
    return null;
  }
  if (!canAffordNewWar) return null;
  // Refs #2847 § H2: declare-war cooldown after a recent peace with the
  // same peer. Without this gate, the planExpandPeace H4-a carve-out
  // peace would be undone the very next turn — arm 3's other gates
  // (treasury, mutual-plateau, regiment parity) all still pass once
  // peace ends the `at-war` short-circuit above. The cooldown lets H3
  // raise regiments and gives the H4-a carve-out room to actually
  // break the geographic peer-war lock.
  if (expandRecentlyPeacedWithGreatPower(
    game: game,
    activePlayerId: snapshot.playerId,
    peerGpId: blockerId,
    currentTurn: game.worldState.turnState.turnNumber,
  )) {
    return null;
  }
  final blockerOw = provinceCountOwnedBy(game, blockerId);
  if (!isMutualBelowQuotaPlateauPeer(
    ownOw: snapshot.conquest.oldWorldProvincesOwned,
    partnerOw: blockerOw,
  )) {
    return null;
  }
  final ownRegiments = regimentCountForPlayer(game, snapshot.playerId);
  final partnerRegiments = regimentCountForPlayer(game, blockerId);
  if (ownRegiments < partnerRegiments) return null;
  return blockerId;
}

// `survivalGreatPowerPeaceTargets` was relocated to
// `observer_goal_phase.dart` (Refs #2509 S1) alongside the sibling
// stalled-peace composers `expandRatchetGreatPowerPeaceTargets`,
// `collectStalledGreatPowerPeaceTargets`, and
// `supplementMutualStalledGreatPowerPeaceOrders` so all composite
// peace aggregators that feed `runDiplomacyPlanner` live in the same
// module as the phase-dispatcher and the per-phase GP-peace-target
// helpers (`expandPhaseGpPeaceTargets`, `colonialPhaseGpPeaceTargets`,
// `developPhaseGpPeaceTargets`). The EXPAND-phase sub-deciders the
// aggregator fans across (`criticalWeakGpSurvivalPeaceTargets`,
// `stalledZeroRegimentAllFactionPeaceTargets`,
// `mutualZeroRegimentGpStalematePeaceTargets`,
// `stalledZeroRegimentGpPeaceTargets`,
// `mutualExhaustedBelowQuotaGpStalematePeaceTargets`) remain canonical
// in this file.
