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
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart' as regiment_catalog
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;

part 'expand_phase_planner_peer_peace.dart';
part 'expand_phase_planner_gp_blocker_peace.dart';
part 'expand_phase_planner_feedstock_acquisition.dart';

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
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
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
  return expandIsGeographicPeerWarLock(
    snapshot: snapshot,
    peerGpId: peerGpId,
  );
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
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.length != 1) {
    return null;
  }
  return gpWars.single;
}

/// Whether peacing a below-quota sole-GP war leaves the EXPAND-phase
/// player a pivot path back to active OW expansion (a remaining
/// uninvaded minor or a minor-owned invadable frontier province).
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `canPivotFromSoleGpWarAfterPeace` predicate previously hosted in
/// `colonial_pressure.dart`. Used by [unwinnableSoleGpFrontierPeaceTarget]
/// in `colonial_pressure.dart` to gate the "peace the lone GP foe when
/// clearly outgunned" decision — peacing is only worthwhile if the
/// active GP can immediately resume EXPAND against a minor rather than
/// idle while the lone GP rebuilds.
///
/// Returns `true` exactly when **any** of these hold:
///   1. The active player is at or above
///      [kObserverConquestMinOwProvincesPerGp] OW provinces (no longer
///      in EXPAND territory; the EXPAND-trap pivot guard is irrelevant
///      so we always allow peace).
///   2. A minor nation still owns at least one Old World province
///      anywhere on the map (the GP can attempt to formalize a new
///      minor war after peacing).
///   3. The active player's [ConquestSummary.invadableProvinceIdsSorted]
///      contains a province whose current owner is a minor nation (the
///      planner can immediately declare on that minor after peacing
///      the lone GP, since the invadable frontier already has a minor
///      pivot).
///
/// All three arms are short-circuited (`||` semantics): the function
/// returns on the first true arm without walking the remaining checks.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_can_pivot_from_sole_gp_war_branches_test.dart`
/// fixture and the existing `unwinnableSoleGpFrontierPeaceTarget` caller
/// within `colonial_pressure.dart` itself) so the now-completed S1 deletion of
/// that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the smaller of
/// [WorldState.oldWorld] provinces (minors-on-map scan) and
/// [ConquestSummary.invadableProvinceIdsSorted] (minor-owned invadable
/// scan); short-circuited at the quota arm when above quota.
bool canPivotFromSoleGpWarAfterPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (snapshot.conquest.oldWorldProvincesOwned >=
      kObserverConquestMinOwProvincesPerGp) {
    return true;
  }
  final minorsOnMap = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  if (minorsOnMap) {
    return true;
  }
  return snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
    final owner = getProvinceOwnerMap(game)[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
}

/// Returns the lone Great Power foe's `factionId` when an EXPAND-phase
/// player should peace it as unwinnable, or `null` when the forced
/// sole-GP-frontier peace path does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `unwinnableSoleGpFrontierPeaceTarget` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the below-quota EXPAND
/// shortcut that surrenders an unwinnable sole-GP war so the planner
/// can pivot back to a minor frontier; it composes the already-canonical
/// helpers [soleAtWarGreatPowerId] and [canPivotFromSoleGpWarAfterPeace]
/// with the deficit-band table from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting — "Forced offerPeace toward the sole at-war
/// Great Power...".
///
/// Returns `null` for any of the following short-circuits (in order):
///   1. [soleAtWarGreatPowerId] returns `null` — no sole GP foe (zero
///      GP wars after the [Game.playerById] filter, or two or more GP
///      wars). Multi-front peace selection (`nearQuotaHoldPeaceTargets`,
///      `belowQuotaPeerGpPeaceTargets`) owns the decision in that
///      shape, not this shortcut.
///   2. [isBelowObserverConquestQuota] is `false` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — at or
///      above the observer OW quota the consolidate-gains decider
///      ([consolidateGainsSoleGpPeaceTarget]) and the quota-met
///      futile-peace collectors take over.
///   3. [canPivotFromSoleGpWarAfterPeace] is `false` — peacing the
///      lone GP would leave no SPEC-legal minor pivot, so the planner
///      must keep the war open and defer to the critical-weak survival
///      peace path instead.
///   4. The OW lead deficit `enemyOw - ownOw` is strictly less than the
///      band's `minDeficit`:
///        * `kUnwinnableSoleGpMinProvinceDeficit` (today: 2) on the
///          8–9 OW GP-only invadable frontier band — preserves
///          near-quota GP-only wars when the partner only narrowly
///          leads (lead 1) so the planner does not surrender the
///          near-peer blocker;
///        * `1` everywhere else (default-start band `own ≤
///          kObserverDefaultStartOldWorldProvincesPerGp`; 8–9 OW
///          non-GP-only band) — minimum +1 OW lead suffices.
///
/// When all four gates pass, returns the [soleAtWarGreatPowerId] result
/// (the sole GP foe).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `diplomacy_planner_peace_targets.dart` consumer chain
/// and the
/// `colonial_pressure_unwinnable_sole_gp_branches_test.dart` fixture)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ConquestSummary.invadableProvinceIdsSorted] via the GP-only-frontier
/// composite; constant-time on all other arms (short-circuited by the
/// sole-GP and quota guards above the band table).
String? unwinnableSoleGpFrontierPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (!canPivotFromSoleGpWarAfterPeace(game: game, snapshot: snapshot)) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final enemyOw = provinceCountOwnedBy(game, enemy);
  final minDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? 1
      : own >= kObserverConquestMinOwProvincesPerGp - 2 &&
            !isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? 1
      : kUnwinnableSoleGpMinProvinceDeficit;
  if (enemyOw < own + minDeficit) {
    return null;
  }
  return enemy;
}

/// Returns the lone Great Power foe's `factionId` when a quota-met
/// EXPAND/COLONIAL player should peace it to lock in observer gains,
/// or `null` when the consolidate-gains shortcut does not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `consolidateGainsSoleGpPeaceTarget` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the quota-met companion
/// of [unwinnableSoleGpFrontierPeaceTarget]: once the active player has
/// secured a comfortable OW buffer above the observer quota and leads
/// the lone GP enemy by at least
/// [kConsolidateGainsSoleGpProvinceLead] OW provinces, peacing locks
/// the conquest gains in before a counter-offensive can erase them
/// (`SPEC/ai/ai-architecture.md` § Diplomacy targeting —
/// "when this GP holds at least
/// `kObserverConquestConsolidateMinOwProvinces` and leads the sole
/// enemy by `kConsolidateGainsSoleGpProvinceLead` or more (lock
/// observer gains before a counter-offensive)").
///
/// Returns `null` for any of the following short-circuits (in order):
///   1. [soleAtWarGreatPowerId] returns `null` — no sole GP foe (zero
///      or two-plus GP wars). The consolidate shortcut is sole-GP-only
///      so a multi-front context defers to the standard collectors.
///   2. [ConquestSummary.oldWorldProvincesOwned] is strictly below
///      [kObserverConquestConsolidateMinOwProvinces] — the active
///      player has not yet built the OW buffer SPEC requires before
///      locking in via peace (otherwise a marginal lead could be
///      reversed before the consolidate decision pays off).
///   3. The OW lead `own - enemyOw` is strictly below
///      [kConsolidateGainsSoleGpProvinceLead] — the consolidate
///      shortcut requires a clear lead, not just any positive gap.
///
/// When all three gates pass, returns the [soleAtWarGreatPowerId]
/// result (the sole GP foe).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_consolidate_gains_sole_gp_peace_branches_test.dart`
/// fixture and the
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chain) so
/// the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the total province
/// count via [provinceCountOwnedBy] for the enemy lookup; otherwise
/// constant-time.
String? consolidateGainsSoleGpPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final enemy = soleAtWarGreatPowerId(game: game, snapshot: snapshot);
  if (enemy == null) {
    return null;
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  if (own < kObserverConquestConsolidateMinOwProvinces) {
    return null;
  }
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (own < enemyOw + kConsolidateGainsSoleGpProvinceLead) {
    return null;
  }
  return enemy;
}

/// Returns the deterministic list of at-war Great Powers the active
/// player should `offerPeace` toward this turn when below the observer
/// OW quota and a GP enemy leads by at least the band-selected minimum
/// province deficit.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledBelowQuotaGpLeadPeaceTargets` peace decider previously hosted
/// in `colonial_pressure.dart`. Implements the EXPAND-phase "peace the
/// leaders, hold the blocker" arm from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — peace at-war
/// Great Powers that lead by [kUnwinnableSoleGpMinProvinceDeficit] (the
/// default-start band) or **1** (post-default band) OW provinces or
/// more while strictly below [kObserverConquestMinOwProvincesPerGp].
///
/// Contract:
///
///   1. **Quota guard.** When
///      [ConquestSummary.oldWorldProvincesOwned] is at or above
///      [kObserverConquestMinOwProvincesPerGp] return `const []` —
///      the caller falls through to quota-met deciders
///      ([quotaMetBelowQuotaAtWarPeaceTargets] / [consolidateGainsSoleGpPeaceTarget])
///      instead of the below-quota lead-peace family.
///   2. **Min-lead-deficit band.** With `own <=
///      kObserverDefaultStartOldWorldProvincesPerGp` the lead threshold
///      is [kUnwinnableSoleGpMinProvinceDeficit] (default-start row);
///      above default start (8–9 OW) the threshold relaxes to **1**
///      (post-default row).
///   3. **GP-only invadable blocker carve-out.** When
///      [isOldWorldGpOnlyInvadableFrontier] is true the
///      [primaryInvadableOldWorldGpBlocker] is excluded from the peace
///      list so the active player keeps fighting the canonical OW
///      frontier blocker even if it leads by the band-selected
///      deficit. Non-blocker GP enemies that still satisfy the
///      deficit remain in the list.
///   4. **At-war filter.** Tribes and minors in [ThreatSummary.atWarWith]
///      are skipped (`game.playerById(...) != null`); only GP factions
///      survive the filter.
///   5. **Lead filter.** Only GP factions whose
///      [provinceCountOwnedBy] is at least `own + minLeadDeficit`
///      survive the deficit gate.
///   6. **Sort determinism.** The returned list is sorted ascending
///      on `factionId` so the downstream offer-peace pass observes a
///      stable order regardless of `atWarWith` iteration order.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `colonial_pressure_stalled_below_quota_gp_lead_branches_test.dart`
/// fixture and the
/// `diplomatic_candidate_scoring_offer_peace.dart` / `diplomacy_planner.dart`
/// / `diplomacy_planner_peace_targets.dart` consumer chains) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] (each at-war faction is inspected once)
/// and in [ConquestSummary.invadableProvinceIdsSorted] via the
/// GP-only-frontier composite that gates the blocker carve-out.
List<String> stalledBelowQuotaGpLeadPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final own = snapshot.conquest.oldWorldProvincesOwned;
  final minLeadDeficit = own <= kObserverDefaultStartOldWorldProvincesPerGp
      ? kUnwinnableSoleGpMinProvinceDeficit
      : 1;
  final invadableBlocker =
      isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          factionId != invadableBlocker &&
          provinceCountOwnedBy(game, factionId) >= own + minLeadDeficit)
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic list of below-quota at-war Great Power
/// factionIds the active quota-met player should `offerPeace` toward this
/// turn — the "stop bullying below-quota peers" arm of the EXPAND-phase
/// peace family.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `quotaMetBelowQuotaAtWarPeaceTargets` peace decider previously hosted
/// in `colonial_pressure.dart`. The decider is the broadest quota-met
/// futile-war exit: once the active player has crossed the observer OW
/// quota ([kObserverConquestMinOwProvincesPerGp] today), every below-
/// quota Great Power still at war is offered peace so the planner stops
/// dragging on mop-up wars after the frontier is cleared
/// (`SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when this GP
/// already meets the observer quota and a below-quota Great Power at
/// war ... exit futile bullying wars; observer seed-42 gp4/gp3").
///
/// The companion [quotaMetFutileBelowQuotaGpPeaceTargets] narrows the
/// same family by also requiring the active player to still hold an
/// invadable OW frontier — used by the offer-peace scoring layer
/// (`diplomatic_candidate_scoring_offer_peace.dart`) so only the
/// narrower set carries the futile-bullying score bonus. The broader
/// helper here covers the post-cleanup state where no invadable OW
/// frontier remains and the planner just wants to release the residual
/// below-quota wars.
///
/// Returns `const []` for either of the outer guards:
///   1. [isBelowObserverConquestQuota] is `true` for the active player's
///      [ConquestSummary.oldWorldProvincesOwned] — quota-met peace
///      targets only fire after this GP has already crossed the
///      observer quota; below-quota GPs are still pressing war and
///      must defer to the EXPAND-phase peace deciders
///      ([defaultStartFutileMinorPeaceTargets],
///      [unwinnableSoleGpFrontierPeaceTarget], the in-file
///      `colonial_pressure` peace collectors that have not yet been
///      relocated).
///   2. [ThreatSummary.atWarWith] contains no Great Power below the
///      observer quota — the active player has only quota-met peers
///      (or no GP foes at all), so the consolidate-gains decider
///      ([consolidateGainsSoleGpPeaceTarget]) and the broader
///      multi-front peace collectors own the decision.
///
/// Per-enemy filters (each `continue`s without short-circuiting):
///   * Skip [ThreatSummary.atWarWith] entries that are not Great
///     Powers ([Game.playerById] returns `null`); minors and tribes
///     belong to the [defaultStartFutileMinorPeaceTargets] family.
///   * Skip Great Power enemies whose own
///     [provinceCountOwnedBy] is at or above the observer quota;
///     consolidate-gains owns those wars.
///
/// The returned list is sorted ascending by `factionId` so the
/// downstream offer-peace consumer (`diplomacy_planner_peace_targets.dart`,
/// `diplomatic_candidate_scoring_offer_peace.dart`) sees a stable
/// order regardless of the iteration order of
/// [ThreatSummary.atWarWith] (Refs #2509 Must-have #7).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_quota_met_below_quota_at_war_peace_branches_test.dart`
/// fixture and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] × [provinceCountOwnedBy] (one full
/// province scan per at-war faction).
List<String> quotaMetBelowQuotaAtWarPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null &&
          isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId)))
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic list of at-war Great Powers the active
/// player should `offerPeace` toward this turn when OW holdings are
/// critically low (at or below [kFewOldWorldProvincesDefendThreshold])
/// and the player is still below the observer OW quota — the
/// EXPAND-phase critical-hold peace arm that peaces every GP war
/// regardless of frontier shape so the GP can rebuild without losing
/// the few OW provinces it still holds.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `criticalOwHoldPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. Implements
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when OW
/// holdings are at or below `kFewOldWorldProvincesDefendThreshold` and
/// any OW minor remains (peace all GP wars)".
///
/// Contract:
///
///   1. **At-war filter.** [ThreatSummary.atWarWith] is filtered to
///      Great Power factions via [Game.playerById]; tribes and minors
///      are skipped. The returned list is sorted ascending on
///      `factionId` before any short-circuit so the empty-after-filter
///      branch and the firing branch share the same sort order.
///   2. **Empty-after-filter short-circuit.** When no GP factions
///      remain in the filtered list the function returns `const []`
///      immediately even if the OW critical band would otherwise fire.
///   3. **Own-OW critical band.** The peace list is emitted only when
///      [isBelowObserverConquestQuota] holds and
///      [ConquestSummary.oldWorldProvincesOwned] is at or below
///      [kFewOldWorldProvincesDefendThreshold]. Outside this band — at
///      or above the observer quota, or below the quota but strictly
///      above the defend threshold — the function returns `const []`.
///   4. **Below-quota AND-gate.** Both gates must hold: at-quota holdings
///      below the defend threshold still return `const []` because
///      `isBelowObserverConquestQuota` is `false` (defensive against a
///      future quota change that drops the quota below the defend
///      threshold).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `colonial_pressure_critical_ow_hold_branches_test.dart`
/// and `colonial_pressure_test.dart` fixtures and the
/// `diplomacy_planner.dart` / `diplomacy_planner_peace_targets.dart`
/// consumer chains) so the now-completed S1 deletion of that file leaves no
/// orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in [ThreatSummary.atWarWith]
/// (each at-war faction is inspected once); constant-time on every
/// other arm.
List<String> criticalOwHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
  if (targets.isEmpty) {
    return const [];
  }
  if (isBelowObserverConquestQuota(ownOw) &&
      ownOw <= kFewOldWorldProvincesDefendThreshold) {
    return targets;
  }
  return const [];
}

/// Returns the deterministic list of below-quota at-war Great Power
/// factionIds the active quota-met player should `offerPeace` toward
/// this turn — the "stop bullying below-quota peers that are not
/// blocking my remaining OW frontier" arm of the EXPAND-phase peace
/// family.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `quotaMetFutileBelowQuotaGpPeaceTargets` peace decider previously
/// hosted in `colonial_pressure.dart`. The decider narrows the broader
/// [quotaMetBelowQuotaAtWarPeaceTargets] family by additionally requiring
/// the active player to still hold an invadable OW frontier and by
/// excluding any below-quota enemy GP that owns one of those invadable
/// OW provinces (peace there would forfeit the residual OW acquisition
/// path) plus the primary invadable OW blocker
/// ([primaryInvadableOldWorldGpBlocker]; defensive backstop). The
/// consumer (`diplomatic_candidate_scoring_offer_peace.dart`) applies a
/// stronger offer-peace score bonus to this narrower set so the
/// futile-bullying signal is concentrated on the truly off-frontier
/// below-quota peers (`SPEC/ai/ai-architecture.md` § Diplomacy
/// targeting — "when this GP already meets the observer quota and a
/// below-quota Great Power at war is not on the remaining invadable OW
/// frontier ... exit futile bullying wars").
///
/// Returns `const []` for any of the three outer guards:
///   1. [isBelowObserverConquestQuota] is `true` for the active
///      player's [ConquestSummary.oldWorldProvincesOwned] — quota-met
///      peace targets only fire after this GP has already crossed the
///      observer quota.
///   2. [ConquestSummary.invadableProvinceIdsSorted] is empty — without
///      a remaining invadable OW frontier the frontier-ownership
///      filter is meaningless and the broader
///      [quotaMetBelowQuotaAtWarPeaceTargets] / consolidate-gains
///      deciders take over.
///
/// Per-enemy filters (each `continue`s without short-circuiting):
///   * Skip [ThreatSummary.atWarWith] entries that are not Great
///     Powers ([Game.playerById] returns `null`); minors and tribes
///     belong to the [defaultStartFutileMinorPeaceTargets] family.
///   * Skip Great Power enemies whose own
///     [provinceCountOwnedBy] is at or above the observer quota;
///     consolidate-gains owns those wars.
///   * Skip Great Power enemies that own at least one province in
///     [ConquestSummary.invadableProvinceIdsSorted] (peace would
///     forfeit the residual OW acquisition path).
///   * Skip the primary invadable OW blocker
///     ([primaryInvadableOldWorldGpBlocker]) defensively — by
///     construction the blocker also satisfies the invadable-owning
///     filter above, so the equality skip is a backstop against a
///     future blocker-resolution refactor that could decouple blocker
///     identity from invadable ownership.
///
/// The returned list is sorted ascending by `factionId` so the
/// downstream offer-peace consumer
/// (`diplomatic_candidate_scoring_offer_peace.dart`) sees a stable
/// order regardless of the iteration order of
/// [ThreatSummary.atWarWith] (Refs #2509 Must-have #7).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the
/// `colonial_pressure_quota_met_futile_below_quota_gp_peace_branches_test.dart`
/// fixture, the `diplomacy_planner_stalled_peace_test.dart` sole
/// positive-case fixture, and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` /
/// `diplomatic_candidate_scoring_offer_peace.dart` consumer chains)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] × ([provinceCountOwnedBy] +
/// [ConquestSummary.invadableProvinceIdsSorted]) for the per-enemy
/// frontier-ownership scan.
List<String> quotaMetFutileBelowQuotaGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  final targets = <String>[];
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (!isBelowObserverConquestQuota(provinceCountOwnedBy(game, factionId))) {
      continue;
    }
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (ownsInvadable || factionId == blocker) continue;
    targets.add(factionId);
  }
  targets.sort();
  return targets;
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

/// EXPAND-phase economy directive returned by [planExpandEconomy].
///
/// Two independent booleans describe the orchestrator overrides for the
/// active player this turn. The planner stays a pure function: the
/// orchestrator (Refs #2509 S5) translates these flags into the actual
/// build-threshold reset and economy-weight cargo boost when wiring the
/// EXPAND dispatch.
///
/// The flags compose — a GP can both be told to force a regiment build
/// and to raise cargo preference in the same turn (canonical "rebuild
/// fast while overseas riches keep arriving" arm when reg = 0 and
/// effective treasury is still under the cheapest regiment cost).
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path.
class ExpandEconomyPlan {
  const ExpandEconomyPlan({
    required this.forceCheapestRegimentBuild,
    required this.boostTreasuryRecoveryCargo,
  });

  /// Reusable "no override" plan returned for non-EXPAND callers, GPs
  /// at quota, defensive guards, and the priority-arm fall-through.
  static const ExpandEconomyPlan defaultPlan = ExpandEconomyPlan(
    forceCheapestRegimentBuild: false,
    boostTreasuryRecoveryCargo: false,
  );

  /// True when the orchestrator should drop the build-pass economy
  /// threshold to zero and pick the cheapest entry in
  /// [RegimentEconomyCatalog] (military rebuild crisis).
  ///
  /// Set under either of the two regiment-rebuild arms in issue #2509
  /// § EXPAND phase planner § planExpandEconomy:
  /// (a) `regimentCount == 0` with a non-empty
  ///     [ConquestSummary.invadableProvinceIdsSorted] (the
  ///     `brokeBelowQuotaAtPeace` / `needRegimentsToExpand` legacy
  ///     condition collapsed into the phase planner); or
  /// (b) the trap condition
  ///     `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
  ///     with non-empty invadable OW frontier and effective treasury
  ///     (cash + [pendingRichesTreasuryDelta]) at or above
  ///     [cheapestRegimentBuildTreasuryCost].
  final bool forceCheapestRegimentBuild;

  /// True when the orchestrator should add
  /// [kBelowQuotaPeaceTreasuryRecoveryCargoBoost] to economy weight so
  /// overseas cargo preference rises (deliver NW riches to stockpile)
  /// even in EXPAND.
  ///
  /// Set when below quota AND effective treasury (cash +
  /// [pendingRichesTreasuryDelta]) is strictly below
  /// [cheapestRegimentBuildTreasuryCost] (issue #2509 § EXPAND phase
  /// planner § planExpandEconomy "treasury < cheapest" arm). The
  /// boost composes with [forceCheapestRegimentBuild] so a GP that is
  /// told to force a build AND cannot currently afford one still gets
  /// the cargo signal to chase incoming riches.
  final bool boostTreasuryRecoveryCargo;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandEconomyPlan &&
          other.forceCheapestRegimentBuild == forceCheapestRegimentBuild &&
          other.boostTreasuryRecoveryCargo == boostTreasuryRecoveryCargo;

  @override
  int get hashCode =>
      Object.hash(forceCheapestRegimentBuild, boostTreasuryRecoveryCargo);

  @override
  String toString() =>
      'ExpandEconomyPlan('
      'forceCheapestRegimentBuild: $forceCheapestRegimentBuild, '
      'boostTreasuryRecoveryCargo: $boostTreasuryRecoveryCargo)';
}

/// Returns the deterministic EXPAND-phase economy directive for the
/// active player as an [ExpandEconomyPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandEconomy):
///
///   "Force-regiment-rebuild when:
///      ow < 10 AND (
///        regimentCount == 0 AND hasInvadableProvinces
///          → set buildThreshold = 0, force cheapest regiment
///        OR
///        0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar
///          AND treasury >= cheapestRegimentBuildTreasuryCost
///          → set buildThreshold = 0, force cheapest regiment
///        OR
///        treasury < cheapestRegimentBuildTreasuryCost
///          → add cargo preference boost (deliver riches to stockpile)
///      )"
///
/// Effective treasury used by the regiment-affordability and cargo
/// arms is `player.treasury + pendingRichesTreasuryDelta(...)` so the
/// planner agrees with the build pipeline that already credits the
/// same-turn `richesToTreasury` phase income before `buildWork`
/// (Refs #2509 § Observer goal phases § EXPAND "Pending riches
/// treasury"). The OW improvements / NW suppressions arms of the spec
/// are out of scope for this planner contract — those orders are
/// produced by `planDevelopCivilian` (DEVELOP) and the conquest
/// army-move planner (EXPAND military) respectively; the EXPAND
/// economy planner only emits the build/cargo override directive.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) to read
///     [Player.treasury] and [Player.stockpile] (for the pending-riches
///     credit) and walks [WorldState.armies] via [regimentCountForPlayer]
///     for the standing regiment count.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.oldWorldProvincesOwned] (quota guard) and
///     [ConquestSummary.invadableProvinceIdsSorted] (the "has invadable
///     frontier" arms of the spec).
///
/// Output:
///   - [ExpandEconomyPlan.defaultPlan] when the active player is at or
///     above [kObserverConquestMinOwProvincesPerGp] OW provinces (not
///     in EXPAND territory for this planner) or when
///     [Game.playerById] returns `null` (defensive guard for snapshots
///     pointing at non-existent players; matches the
///     [planExpandDeclareWar] guard).
///   - `forceCheapestRegimentBuild: true` when arm A
///     (`regimentCount == 0` and non-empty invadable OW frontier) holds.
///     Treasury is intentionally **not** part of arm A's gate per the
///     issue spec — the orchestrator's existing build pipeline still
///     handles the case where no regiment is affordable yet, but the
///     phase planner signals intent unconditionally so the rebuild
///     trap cannot stick.
///   - `forceCheapestRegimentBuild: true` when arm B
///     (`0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///     and non-empty invadable OW frontier and effective treasury
///     ≥ cheapest regiment cost) holds.
///   - `boostTreasuryRecoveryCargo: true` when arm C
///     (effective treasury < cheapest regiment cost) holds, including
///     under the geographic peer-war lock. The cargo signal is the
///     planner-output the resource-need NW=0.60 weight floor in
///     `phase_priority_weights.dart` consumes (Refs #2847 §
///     Resource-need overrides); suppressing it under the lock would
///     also disable the override the soft-phase design depends on
///     (the H5 lock-suppression that earlier landed on this arm has
///     been reverted in favour of restoring the override coupling).
///     Composes with arm A whenever both predicates hold.
///   - `forceCheapestRegimentBuild: true` when arm D holds (Refs #2847
///     § H3): geographic peer-war lock with zero NW ownership,
///     `0 < regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`,
///     and non-empty invadable OW frontier — without the arm-B treasury
///     gate (build pipeline affordability unchanged).
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandEconomyPlan]s (Refs #2509 Must-have #7).
ExpandEconomyPlan planExpandEconomy({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ExpandEconomyPlan.defaultPlan;
  }
  final player = game.playerById(snapshot.playerId);
  if (player == null) {
    return ExpandEconomyPlan.defaultPlan;
  }

  final hasInvadable = snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  final effectiveTreasury =
      player.treasury + pendingRichesTreasuryDelta(stockpile: player.stockpile);
  final cheapest = cheapestRegimentBuildTreasuryCost();

  // Arm A: regimentCount == 0 AND hasInvadable -> force rebuild
  // (no treasury gate per spec; the build pipeline still applies its
  // own affordability check, but the directive remains so the phase
  // planner cannot be silently overridden by a treasury hiccup).
  final armA = regimentCount == 0 && hasInvadable;

  // Arm B: 0 < regimentCount < min AND hasInvadable AND effective
  // treasury affords the cheapest regiment.
  final armB =
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable &&
      effectiveTreasury >= cheapest;

  final futilityLock = expandIsGeographicPeerWarLockNoNwTreasuryRecovery(
    game: game,
    snapshot: snapshot,
  );

  // Arm D (Refs #2847 § H3): trap-band force rebuild without treasury
  // gate when overseas cargo recovery is futile.
  final armD = futilityLock &&
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable;

  // Arm C: effective treasury below cheapest regiment cost (independent
  // of regimentCount per the spec literal wording — boosts cargo so a
  // GP in EXPAND with low cash always benefits from delivering riches,
  // matching the SPEC/ai/ai-architecture.md "Treasury recovery cargo"
  // intent). Fires under the geographic peer-war lock too: the cargo
  // signal is what the resource-need NW=0.60 weight floor consumes in
  // `phase_priority_weights.dart`, so suppressing the boost under the
  // lock also disables the override the issue's soft-phase design
  // depends on (Refs #2847 § Resource-need overrides). Cargo delivery
  // may be futile until the GP acquires its first NW colony, but the
  // signal correctly marks the GP as needing overseas income so
  // downstream NW scoring biases activate.
  final armC = effectiveTreasury < cheapest;

  return ExpandEconomyPlan(
    forceCheapestRegimentBuild: armA || armB || armD,
    boostTreasuryRecoveryCargo: armC,
  );
}

/// Minimum [RegimentEconomyCatalog] build treasury cost (deterministic
/// catalog scan).
///
/// Canonical home (Refs #2509 S1) for the EXPAND-trap treasury affordability
/// gate used by [planExpandDeclareWar] (treasury floor before declaring),
/// [planExpandEconomy] (arms B/C threshold for force-build and treasury
/// recovery cargo), and the [planColonialAcquisition] declare-war arm in
/// `colonial_phase_planner.dart`. `colonial_pressure.dart` retains a
/// thin delegating stub for legacy import sites so the planned S1
/// deletion of that file leaves no orphan callers.
///
/// Linear in the catalog size, matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc`.
int cheapestRegimentBuildTreasuryCost() =>
    regiment_catalog.cheapestRegimentBuildTreasuryCost();

/// Below-quota EXPAND GP with zero standing regiments and a non-empty
/// invadable Old World frontier.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `isBelowQuotaPeaceZeroRegimentsRebuild` predicate previously hosted in
/// `colonial_pressure.dart` (Arm A of the legacy below-quota treasury-recovery
/// composite). The function captures the EXPAND-trap "zero regiments with
/// frontier to expand into" arm shared by:
///
///   - [planExpandEconomy] Arm A (`regimentCount == 0 && hasInvadable` →
///     `forceCheapestRegimentBuild: true`), which signals the orchestrator
///     to force a regiment build attempt regardless of treasury (cargo
///     boost in Arm C handles the funding side).
///   - The `isBelowQuotaPeaceTreasuryRecovery` composite (composed with the
///     `isBelowQuotaPeaceInsufficientRegiments` arm) so the cargo-delivery
///     trigger and the planner directive cannot drift apart now that the
///     S5 orchestrator wire-up is in place. The composite was canonical in
///     the now-deleted `colonial_pressure.dart` (#2509 S1) and is hosted
///     here alongside this predicate.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_below_quota_peace_*` tests and
/// `phase_planner_economy_filter.dart`) so the now-completed S1 deletion of
/// that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Constant-time (no catalog or
/// game-state scan).
bool isBelowQuotaPeaceZeroRegimentsRebuild({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool hasInvadableProvinces,
}) =>
    isBelowObserverConquestQuota(oldWorldProvincesOwned) &&
    regimentCount == 0 &&
    hasInvadableProvinces;

/// Below-quota EXPAND GP at peace with all other Great Powers, with an
/// invadable Old World frontier and a positive but small standing regiment
/// count.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `isBelowQuotaPeaceInsufficientRegiments` predicate previously hosted in
/// `colonial_pressure.dart`. Captures the seed-42 turn-100 trap where a GP
/// that exited an early war with few standing regiments and zero treasury is
/// no longer "broke" (`regimentCount > 0`) and so neither
/// `needRegimentsToExpand` nor `brokeBelowQuotaAtPeace` triggers force
/// regiment rebuild — yet the GP also has too few regiments to mount a
/// credible EXPAND declare-war on the remaining GP-only frontier (Refs
/// #2509 § Observer goal phases (Full AI) "EXPAND regiment-rebuild trap").
///
/// Returns `true` only while OW holdings are below
/// [kObserverConquestMinOwProvincesPerGp], no Great Power is in the at-war
/// set, `invadableProvinceIdsSorted` is non-empty, and the standing
/// regiment count is in the half-open range
/// `[1, kBelowQuotaPeaceMinRegimentsBeforeDeclareWar)`. Arm B of the
/// EXPAND-trap below-quota treasury-recovery composite, paired with
/// [isBelowQuotaPeaceZeroRegimentsRebuild] (Arm A) inside
/// [isBelowQuotaPeaceTreasuryRecovery].
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_below_quota_peace_insufficient_regiments`
/// tests, `economy_planner.dart`, and `phase_planner_economy_filter.dart`)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Constant-time (no catalog or
/// game-state scan).
bool isBelowQuotaPeaceInsufficientRegiments({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
}) {
  if (!isBelowObserverConquestQuota(oldWorldProvincesOwned)) {
    return false;
  }
  if (atWarWithAnyGreatPower) {
    return false;
  }
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return false;
  }
  return hasInvadableProvinces;
}

/// Below-quota EXPAND GP at peace with insufficient regiments and effective
/// treasury (cash plus same-turn pending riches) below cheapest regiment
/// build.
///
/// Triggers the overseas cargo-recovery preference so auto-transport can
/// deliver riches to the stockpile before the next build pass (Refs #2509).
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `isBelowQuotaPeaceTreasuryRecovery` composite previously hosted in
/// `colonial_pressure.dart`. The composite short-circuits to `true` when the
/// Arm A zero-regiments rebuild trigger ([isBelowQuotaPeaceZeroRegimentsRebuild])
/// fires; otherwise it requires the Arm B insufficient-regiments gate
/// ([isBelowQuotaPeaceInsufficientRegiments]) AND an effective treasury
/// (`treasury + pendingRichesTreasuryDelta(stockpile)`) strictly below
/// [cheapestRegimentBuildTreasuryCost]. Mirrors the legacy three-arm
/// EXPAND-trap decision tree without the cargo-boost wiring at the same
/// function boundary the orchestrator and `economy_planner.dart` consume.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// import sites (the `colonial_pressure_below_quota_peace_treasury_recovery_branches`
/// tests, `economy_planner.dart`, and `phase_planner_economy_filter.dart`)
/// so the now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// results (Refs #2509 Must-have #7). Linear in the [RegimentEconomyCatalog]
/// only via [cheapestRegimentBuildTreasuryCost]; otherwise constant-time.
bool isBelowQuotaPeaceTreasuryRecovery({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
  required int treasury,
  required Stockpile stockpile,
}) {
  if (isBelowQuotaPeaceZeroRegimentsRebuild(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    regimentCount: regimentCount,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return true;
  }
  if (!isBelowQuotaPeaceInsufficientRegiments(
    oldWorldProvincesOwned: oldWorldProvincesOwned,
    regimentCount: regimentCount,
    atWarWithAnyGreatPower: atWarWithAnyGreatPower,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return false;
  }
  final effectiveTreasury =
      treasury + pendingRichesTreasuryDelta(stockpile: stockpile);
  return effectiveTreasury < cheapestRegimentBuildTreasuryCost();
}

/// EXPAND-phase conquest destination filter returned by [planExpandMilitary].
///
/// Two ascending-sorted lists describe the priority subset of OW
/// invadable provinces (and the owning faction(s)) that conquest army
/// moves should target this turn. The lists never contain New World
/// provinces — structural suppression in [planExpandMilitary] (the
/// planner only reads [ConquestSummary.invadableProvinceIdsSorted],
/// which is OW-only by construction in the perception-snapshot builder).
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// `runConquestArmyMovePlanner`:
///   - [defaultPlan] (`priorityDestinationProvinceIdsSorted` empty) =
///     "no constraint"; the orchestrator chooses freely from the full
///     OW invadable set (legacy behavior).
///   - A non-default plan = "restrict OW conquest destinations to this
///     subset". Empty plans never carry [priorityTargetOwnerFactionIdsSorted]
///     entries; non-empty plans always carry at least one owner.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path.
class ExpandMilitaryPlan {
  const ExpandMilitaryPlan({
    required this.priorityDestinationProvinceIdsSorted,
    required this.priorityTargetOwnerFactionIdsSorted,
  });

  /// Reusable "no override" plan returned for non-EXPAND callers, GPs
  /// at quota, the empty-invadable guard, and the priority-arm
  /// fall-through (declared-war target owns nothing in OW invadable
  /// and no at-war faction owns OW invadable either).
  static const ExpandMilitaryPlan defaultPlan = ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ConquestSummary.invadableProvinceIdsSorted] (OW only)
  /// whose owners match the priority-arm filter for this turn. Sorted
  /// ascending so identical inputs yield identical lists (Refs #2509
  /// Must-have #7). Empty for [defaultPlan].
  final List<String> priorityDestinationProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityDestinationProvinceIdsSorted]. Sorted ascending and
  /// deduplicated:
  ///   - Single-element list when the declared-war target arm fires
  ///     ([planExpandMilitary] § Priority 1).
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planExpandMilitary] § Priority 2).
  ///   - Empty for [defaultPlan].
  final List<String> priorityTargetOwnerFactionIdsSorted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandMilitaryPlan &&
          _listEquals(
            priorityDestinationProvinceIdsSorted,
            other.priorityDestinationProvinceIdsSorted,
          ) &&
          _listEquals(
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
      'ExpandMilitaryPlan('
      'priorityDestinationProvinceIdsSorted: $priorityDestinationProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns the deterministic EXPAND-phase conquest destination filter
/// for the active player as an [ExpandMilitaryPlan].
///
/// Contract (issue #2509 § EXPAND phase planner § planExpandMilitary):
///
///   "Conquest army moves toward OW invadable provinces only.
///      → Source: invadableProvinceIdsSorted, filtered to provinces
///        owned by the declare-war target (or any at-war owner if no
///        target).
///      → Use existing runConquestArmyMovePlanner with EXPAND-only
///        destination filter.
///      → No NW army moves (structural — planner never queries
///        colonial summary)."
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ConquestSummary.invadableProvinceIdsSorted] by owner faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ConquestSummary.invadableProvinceIdsSorted] (the OW-only
///     candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the EXPAND outer
///     quota gate), and [ThreatSummary.atWarWith] (the Priority 2
///     fallback when no declare-war target is given).
///   - [declaredWarTargetFactionId]: optional declare-war target from
///     [planExpandDeclareWar] for the same turn; when non-null, the
///     planner restricts conquest destinations to provinces owned by
///     that faction (Priority 1).
///
/// Priority arms (first match wins; each arm produces a sorted-ascending,
/// deduplicated province list):
///   1. **Declared-war target** — when [declaredWarTargetFactionId] is
///      non-null and owns at least one province in
///      [ConquestSummary.invadableProvinceIdsSorted], the plan
///      restricts to those provinces and lists only the target as
///      `priorityTargetOwnerFactionIdsSorted`.
///   2. **At-war owners fallback** — when no declare-war target is given
///      and at least one faction in [ThreatSummary.atWarWith] owns an
///      OW invadable province, the plan restricts to the union of those
///      provinces and lists the at-war owners sorted ascending.
///   3. **Default plan** — when the declare-war target owns nothing in
///      OW invadable, or when no declare-war target is given and no
///      at-war faction owns OW invadable, or for the outer guards (at
///      quota, missing player, empty OW invadable). Empty plan signals
///      the orchestrator to fall back to its existing free-choice
///      conquest behaviour over the full invadable set.
///
/// Structural NW suppression: this function reads only
/// [ConquestSummary.invadableProvinceIdsSorted] (OW-only by builder
/// contract). It never reads [ColonialSummary.invadableNewWorldProvinceIdsSorted],
/// so a New World province cannot appear in the plan even when the
/// snapshot exposes one (Refs #2509 § EXPAND phase planner
/// "Suppressions" / Phase planner unit tests § "EXPAND NW
/// suppression"). The actual order emission and the conquest army-move
/// pass live in `runConquestArmyMovePlanner`; the orchestrator (#2509
/// S5) wires this plan in as a filter on that pass.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ExpandMilitaryPlan]s (Refs #2509 Must-have #7).
ExpandMilitaryPlan planExpandMilitary({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  final invadable = snapshot.conquest.invadableProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (declaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == declaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ExpandMilitaryPlan.defaultPlan;
    }
    destinations.sort();
    return ExpandMilitaryPlan(
      priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        declaredWarTargetFactionId,
      ]),
    );
  }

  final atWarOwners = <String>{};
  final atWarSet = snapshot.threats.atWarWith.toSet();
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ExpandMilitaryPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ExpandMilitaryPlan(
    priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}

/// Returns the existing GP-vs-GP war partner targeting [targetGpId] in the
/// supplied [DiplomacyRelation], or `null` when the relation does not encode
/// such a war.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for [greatPowerWarCountOnTarget]: a same-turn declare-war scoring
/// helper consumed by `diplomatic_candidate_scoring_declare_war.dart` to
/// suppress dogpiles on GPs that are already at war with at least one other
/// GP, including same-turn declarations from earlier Full-AI players. The
/// private helper survives the planned deletion of `colonial_pressure.dart`
/// alongside its public callers (Refs #2509 § S1).
///
/// Returns:
///   - `null` when [rel] is not in `RelationState.atWar`.
///   - `null` when neither faction in the relation is [targetGpId].
///   - `null` when the non-target faction is not a Great Power
///     ([Game.playerById] returns `null`).
///   - The non-target faction's id when the relation pairs [targetGpId]
///     against a different Great Power in the at-war state.
String? _expandGpWarPartnerAgainstTarget(
  DiplomacyRelation rel,
  String targetGpId,
  Game game,
) {
  if (rel.state != RelationState.atWar) {
    return null;
  }
  if (rel.factionId1 == targetGpId && game.playerById(rel.factionId2) != null) {
    return rel.factionId2;
  }
  if (rel.factionId2 == targetGpId && game.playerById(rel.factionId1) != null) {
    return rel.factionId1;
  }
  return null;
}

/// True when [orders] contains a same-turn `declareWar` diplomatic order
/// pointing at [targetGpId].
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for the same-turn declare-war fan-out walked by
/// [_expandAddSameTurnDeclareWarGpTargets]. Survives the planned deletion of
/// `colonial_pressure.dart` alongside its public callers.
bool _expandHasDeclareWarOnTarget(
  Iterable<DiplomaticOrder> orders,
  String targetGpId,
) {
  for (final order in orders) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetGpId) {
      return true;
    }
  }
  return false;
}

/// Adds every Great Power declarer in [orders] that has a same-turn
/// `declareWar` order pointing at [targetGpId] into [atWarGpIds].
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) as a private
/// helper for [greatPowerWarCountOnTarget]. Walks
/// [Orders.diplomaticOrdersByPlayerId] in deterministic iteration order
/// over a per-player map; the helper only mutates [atWarGpIds] (a set,
/// so duplicates from resolved relations are folded in without altering
/// the public count).
///
/// Minor nations and tribes are skipped via [Game.playerById]; only
/// Great Power declarers contribute to the same-turn dogpile signal that
/// `diplomatic_candidate_scoring_declare_war.dart` uses to score
/// candidate declarations.
void _expandAddSameTurnDeclareWarGpTargets({
  required Game game,
  required String targetGpId,
  required Orders orders,
  required Set<String> atWarGpIds,
}) {
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final declarerId = entry.key;
    if (game.playerById(declarerId) == null) {
      continue;
    }
    if (!_expandHasDeclareWarOnTarget(entry.value, targetGpId)) {
      continue;
    }
    atWarGpIds.add(declarerId);
  }
}

/// Returns the count of Great Powers currently warring against [targetGpId],
/// including same-turn declare-war orders from earlier Full-AI players in
/// [sameTurnPriorDiplomaticOrders] when supplied.
///
/// Same-turn declarers and resolved-relation partners are folded into a
/// shared [Set] so a GP that both declared this turn and already had an
/// at-war relation against [targetGpId] is counted only once. The set is
/// then collapsed to its length.
///
/// Consumers (`diplomatic_candidate_scoring_declare_war.dart` § war
/// concentration scoring) use the count to suppress dogpile-style
/// declarations when [targetGpId] is already engaged in multiple GP-vs-GP
/// wars (deterministic anti-dogpile gate; Refs #2509 § EXPAND phase
/// planner § declare-war suppression).
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the
/// declare-war coordination helper survives the planned deletion of
/// `colonial_pressure.dart`. Linear in
/// `(diplomacyRelations.length + sameTurnPriorDiplomaticOrders entries)`,
/// matching `colonizethis-turn-resolution-budget.mdc` § hot-loop
/// guidance (no global province / tile scans introduced by the move).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical counts (Refs #2509 Must-have #7).
int greatPowerWarCountOnTarget({
  required Game game,
  required String targetGpId,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarGpIds = <String>{};
  for (final rel in game.diplomacyRelations) {
    final partner = _expandGpWarPartnerAgainstTarget(rel, targetGpId, game);
    if (partner != null) {
      atWarGpIds.add(partner);
    }
  }
  if (sameTurnPriorDiplomaticOrders != null) {
    _expandAddSameTurnDeclareWarGpTargets(
      game: game,
      targetGpId: targetGpId,
      orders: sameTurnPriorDiplomaticOrders,
      atWarGpIds: atWarGpIds,
    );
  }
  return atWarGpIds.length;
}

/// True when [declarerFactionId] has a same-turn `declareWar` diplomatic
/// order pointing at [targetFactionId] in [sameTurnPriorDiplomaticOrders].
///
/// Returns `false` when [sameTurnPriorDiplomaticOrders] is `null` (no
/// earlier Full-AI player has committed orders yet this turn) so callers
/// can skip the same-turn check without a separate guard.
///
/// Relocated from `colonial_pressure.dart` (Refs #2509 S1) so the
/// declare-war ordering helper survives the planned deletion of
/// `colonial_pressure.dart`. The single live consumer is
/// `diplomatic_candidate_scoring_declare_war.dart` § same-turn
/// declare-war suppression, which uses the predicate to drop a
/// candidate when the prospective target has already declared back
/// against the active player earlier in the same turn (mutual
/// declarations are not re-issued).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical results (Refs #2509 Must-have #7).
bool pendingDeclareWarFrom({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String declarerFactionId,
  required String targetFactionId,
}) {
  if (sameTurnPriorDiplomaticOrders == null) {
    return false;
  }
  for (final order
      in sameTurnPriorDiplomaticOrders
              .diplomaticOrdersByPlayerId[declarerFactionId] ??
          const []) {
    if (order.type == DiplomaticOrderType.declareWar &&
        order.targetFactionId == targetFactionId) {
      return true;
    }
  }
  return false;
}

/// Returns the deterministic ascending-sorted list of at-war minor
/// `factionId`s that the active player should `offerPeace` toward when
/// stuck in a futile minor war at default observer start size, or an
/// empty list when the EXPAND default-start futile-minor pivot does
/// not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `defaultStartFutileMinorPeaceTargets` peace decider previously
/// hosted in `colonial_pressure.dart`. The decider implements the
/// EXPAND-phase "exit a futile minor front before opening a GP-blocker
/// war" pivot for seed-42 gp4 (default-start GP with one zero-province
/// minor still in `threats.atWarWith`). It composes
/// [isOldWorldGpOnlyInvadableFrontier] (band selector) with the
/// observer default-start band table from
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
///
/// Returns the empty list (`const []`) for any of the outer guards (in
/// order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at or above the
///      observer OW quota the quota-met futile-peace collectors
///      ([quotaMetFutileBelowQuotaGpPeaceTargets] et al, still in
///      `colonial_pressure.dart` at this slice) take over.
///   2. `ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1` —
///      strictly above the default-start +1 band; the near-quota /
///      stalled-band collectors own the decision in that shape.
///   3. [ConquestSummary.invadableProvinceIdsSorted] is empty — no
///      invadable OW exists for the current planner snapshot, so no
///      futile minor war can be diagnosed.
///
/// When the guards pass, the band table selects between two arms:
///   * **GP-only invadable frontier arm** — when
///     [isOldWorldGpOnlyInvadableFrontier] is `true`, every at-war
///     minor in [ThreatSummary.atWarWith] is peaced (no minor pivot
///     remains so all open minor wars are futile by construction).
///     Returned in ascending lex order over the minor `factionId`s.
///   * **Mixed minor frontier arm** — otherwise, only the at-war
///     minors that own **no** invadable OW province are peaced
///     (futile front: the minor is in `atWarWith` but not on the
///     invadable list). Resolved with [getProvinceOwnerMap] and an
///     `any` scan over [ConquestSummary.invadableProvinceIdsSorted].
///     Returned in ascending lex order over the minor `factionId`s.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for legacy
/// callers (the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain and the
/// existing `colonial_pressure_test.dart` § `defaultStartFutileMinorPeaceTargets`
/// fixture) so the now-completed S1 deletion of that file leaves no orphan
/// callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both arms, plus a single
/// [getProvinceOwnerMap] pass on the mixed-frontier arm, matching the
/// budget-rule note in `colonizethis-turn-resolution-budget.mdc`
/// (no global province / tile scans introduced by the move).
List<String> defaultStartFutileMinorPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      ownOw > kObserverDefaultStartOldWorldProvincesPerGp + 1 ||
      snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    final targets = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.minorNations.any((m) => m.id == factionId)) factionId,
    ]..sort();
    return targets;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.minorNations.any((m) => m.id == factionId) &&
          !snapshot.conquest.invadableProvinceIdsSorted.any(
            (pid) => provinceOwner[pid] == factionId,
          ))
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic ascending-sorted list of at-war Great
/// Power `factionId`s the active player should `offerPeace` toward
/// at default observer start size in EXPAND, or `const []` when the
/// default-start GP-peace pivot does not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `defaultStartGpPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. The decider implements the EXPAND-phase
/// "at default observer start size, peace every Great Power war so
/// the GP can open a minor frontier" pivot for seed-42 gp4
/// (zero-gain stall, default-start band). It composes
/// [hasUninvadedOldWorldMinor], [isOldWorldGpOnlyInvadableFrontier],
/// and [primaryInvadableOldWorldGpBlocker] with the observer
/// default-start band table from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at or above the
///      observer OW quota the quota-met futile-peace collectors
///      ([quotaMetFutileBelowQuotaGpPeaceTargets] et al, still in
///      `colonial_pressure.dart` at this slice) take over.
///   2. `ownOw > maxOwForGpPeace` where `maxOwForGpPeace` is
///      [kStalledOldWorldProvinceThreshold] when at least one
///      uninvaded OW minor remains (the planner can stretch the
///      default-start GP-peace pivot up into the stalled band) and
///      `kObserverDefaultStartOldWorldProvincesPerGp + 1` otherwise
///      (no minor pivot remains, so the pivot is restricted to the
///      default-start +1 band).
///
/// When the guards pass, the function peaces every at-war Great
/// Power faction (filtered via [Game.playerById]) **except** the
/// invadable OW frontier blocker on the GP-only invadable arm: when
/// [isOldWorldGpOnlyInvadableFrontier] is `true` the
/// [primaryInvadableOldWorldGpBlocker] is excluded so the planner
/// keeps fighting the lone GP that owns the GP-only frontier; on
/// every other shape the blocker filter is `null` and all at-war GPs
/// are peaced. The output is sorted ascending by `factionId` for
/// deterministic ordering.
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for
/// legacy callers (the existing
/// `colonial_pressure_default_start_gp_peace_branches_test.dart`
/// fixture and the `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both arms, plus the canonical
/// composite calls into [hasUninvadedOldWorldMinor],
/// [isOldWorldGpOnlyInvadableFrontier], and
/// [primaryInvadableOldWorldGpBlocker] (each linear in the OW
/// invadable / minor sets), matching the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province /
/// tile scans introduced by the move).
List<String> defaultStartGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw)) {
    return const [];
  }
  final maxOwForGpPeace =
      hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)
      ? kStalledOldWorldProvinceThreshold
      : kObserverDefaultStartOldWorldProvincesPerGp + 1;
  if (ownOw > maxOwForGpPeace) {
    return const [];
  }
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  final invadableBlocker = gpOnlyFrontier
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null && factionId != invadableBlocker)
        factionId,
  ]..sort();
  return targets;
}

/// Returns the deterministic ascending-sorted list of at-war Great
/// Power `factionId`s the active player should `offerPeace` toward
/// at near-quota (8–9 OW) while still below the observer quota in
/// EXPAND, or `const []` when the near-quota hold-gains pivot does
/// not apply this turn.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `nearQuotaHoldPeaceTargets` peace decider previously hosted in
/// `colonial_pressure.dart`. The decider implements the EXPAND-phase
/// "at 8–9 OW, peace distracting GP wars so the planner can hold
/// gains and finish the OW push" pivot for seed-42 gp3 (near-quota
/// stalled-band GP). It composes the canonical helpers
/// [primaryInvadableOldWorldGpBlocker] (frontier blocker selector),
/// [isOldWorldGpOnlyInvadableFrontier] (band selector),
/// [isMutualBelowQuotaPlateauPeer] (sole-GP plateau detector), and
/// [hasUninvadedOldWorldMinor] (minor-pivot detector) with the
/// near-quota band rules from `SPEC/ai/ai-architecture.md`
/// § Diplomacy targeting.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at or above the
///      observer OW quota the quota-met futile-peace collectors
///      take over.
///   2. [isStalledOldWorldExpansion] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — strictly below
///      the stalled-band threshold the default-start GP-peace
///      collector ([defaultStartGpPeaceTargets]) owns the decision.
///   3. The active player has zero at-war Great Powers in
///      [ThreatSummary.atWarWith] (filtered via [Game.playerById])
///      — no GP wars to peace at all.
///
/// When the guards pass, the function dispatches on the GP-war set:
///   * **Sole GP war arm** — exactly one at-war Great Power. Peaces
///     the lone GP only when the war is a mutual-plateau sole-GP
///     stalemate ([isMutualBelowQuotaPlateauPeer]) on a GP-only
///     invadable frontier ([isOldWorldGpOnlyInvadableFrontier])
///     with no uninvaded OW minors remaining
///     ([hasUninvadedOldWorldMinor] is `false`); otherwise, when
///     the lone GP is the [primaryInvadableOldWorldGpBlocker] and a
///     minor pivot remains the war is held open (`const []`) so the
///     planner keeps fighting the blocker. Every other sole-GP
///     shape falls through to the multi-GP arm below.
///   * **Multi-GP war arm (≥2 at-war GPs, or sole-GP fall-through)**
///     — peace every at-war GP except the
///     [primaryInvadableOldWorldGpBlocker]. Returned in ascending
///     lex order over the GP `factionId`s.
///   * **Sole-GP fall-through** — when the sole-GP arm short-circuit
///     above does not fire and does not return the held-open
///     `const []`, the function falls back to returning the
///     unsorted single-GP list for compatibility with the legacy
///     `colonial_pressure.dart` shape (one element so sort order is
///     trivial).
///
/// `colonial_pressure.dart` previously retained a thin delegating stub for
/// legacy callers (the existing `colonial_pressure_test.dart`
/// fixtures that exercise the near-quota arms and the
/// `diplomacy_planner.dart` /
/// `diplomacy_planner_peace_targets.dart` consumer chain) so the
/// now-completed S1 deletion of that file leaves no orphan callers.
///
/// Pure and deterministic — identical inputs always yield identical
/// lists (Refs #2509 Must-have #7). Linear in
/// [ThreatSummary.atWarWith] across both arms, plus the canonical
/// composite calls into [primaryInvadableOldWorldGpBlocker],
/// [isOldWorldGpOnlyInvadableFrontier],
/// [isMutualBelowQuotaPlateauPeer], and [hasUninvadedOldWorldMinor]
/// (each linear in the OW invadable / minor sets), matching the
/// budget-rule note in `colonizethis-turn-resolution-budget.mdc`
/// (no global province / tile scans introduced by the move).
List<String> nearQuotaHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      !isStalledOldWorldExpansion(ownOw)) {
    return const [];
  }
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  if (gpWars.isEmpty) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
  if (gpWars.length == 1) {
    final soleGp = gpWars.single;
    final partnerOw = provinceCountOwnedBy(game, soleGp);
    if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw) &&
        gpOnlyFrontier &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return gpWars;
    }
    if (blocker != null &&
        gpWars.single == blocker &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return const [];
    }
  }
  if (gpWars.length >= 2) {
    final targets = <String>[
      for (final factionId in gpWars)
        if (factionId != blocker) factionId,
    ]..sort();
    return targets;
  }
  return gpWars;
}

/// At-war minor with the most invadable Old World provinces (single-front
/// focus minor), or `null` when no at-war minor owns any invadable OW
/// province.
///
/// Canonical home (Refs #2509 S1) for the legacy `stalledFocusMinorTarget`
/// helper previously hosted in `diplomacy_planner_peace_targets.dart`. The
/// helper survives the now-completed S1 deletion of that file alongside its
/// EXPAND-phase consumers ([belowQuotaActiveMinorWarTarget],
/// `stalledExpansionDistractionPeaceTargets`,
/// `belowQuotaMultiMinorDistractionPeaceTargets`) which all use the
/// "focused minor" identity to keep one OW minor war open while peacing
/// every other distraction front.
///
/// Inputs:
///   - [game]: used to resolve `(playerId, minor.id)` relations via
///     [getRelation] and to score each at-war minor against
///     [ConquestSummary.invadableProvinceIdsSorted] via [getProvinceOwnerMap].
///   - [snapshot]: per-player [AIWorldSnapshot] supplying the active player
///     id and the deterministic invadable OW frontier list.
///
/// Output:
///   - The `factionId` of the at-war minor that owns the most provinces in
///     [ConquestSummary.invadableProvinceIdsSorted]. The first minor that
///     reaches a strictly greater invadable count wins, so ties resolve to
///     the iteration order of `Game.minorNations` (deterministic for a
///     fixed game-state input).
///   - `null` when no at-war minor owns any invadable OW province (every
///     candidate stays at `bestInvadableCount == 0`).
///
/// Pure and deterministic — identical inputs always yield identical output
/// (Refs #2509 Must-have #7). Linear in `Game.minorNations` with one
/// [ConquestSummary.invadableProvinceIdsSorted] scan per at-war minor;
/// matches the budget-rule note in
/// `colonizethis-turn-resolution-budget.mdc` (no global province / tile
/// scans introduced by the move).
String? stalledFocusMinorTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  String? bestMinorId;
  var bestInvadableCount = 0;
  for (final minor in game.minorNations) {
    final rel = getRelation(game, snapshot.playerId, minor.id);
    if (rel?.state != RelationState.atWar) continue;
    final invadableCount = snapshot.conquest.invadableProvinceIdsSorted
        .where((pid) => provinceOwner[pid] == minor.id)
        .length;
    if (invadableCount > bestInvadableCount) {
      bestInvadableCount = invadableCount;
      bestMinorId = minor.id;
    }
  }
  return bestMinorId;
}

/// At-war minor "active OW front" target while the active player is below
/// the observer OW conquest quota, or `null` when above-quota or no at-war
/// minor owns invadable OW provinces.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `belowQuotaActiveMinorWarTarget` helper previously hosted in
/// `diplomacy_planner_peace_targets.dart`. The helper is a thin
/// below-quota gate over [stalledFocusMinorTarget] used by EXPAND-phase
/// candidate scoring (`diplomatic_candidate_scoring_offer_peace.dart` and
/// the seed-42 gp4 minor-front-hold path) so the planner does not peace a
/// minor that still owns a real OW frontier while we are below quota.
///
/// Outer guard: returns `null` when
/// [isBelowObserverConquestQuota] is `false` for
/// [ConquestSummary.oldWorldProvincesOwned] — the at-quota and above-quota
/// bands route minor-front decisions through the quota-met /
/// near-quota / consolidate deciders instead.
///
/// When the outer guard passes, the helper delegates to
/// [stalledFocusMinorTarget] and returns its result unchanged: either the
/// minor that owns the most invadable OW provinces, or `null` when the
/// scan finds no at-war minor with an invadable OW province.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Cost is dominated by the
/// [stalledFocusMinorTarget] scan once the outer guard passes; the
/// quota-band check is O(1).
String? belowQuotaActiveMinorWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  return stalledFocusMinorTarget(game: game, snapshot: snapshot);
}

/// Returns the deterministic ascending-sorted list of at-war minor
/// `factionId`s the active player should `offerPeace` toward in EXPAND
/// while below the observer OW quota with a regiment count too small to
/// split across multiple minor wars, dropping every distraction minor
/// front except the focused-minor target, or `const []` when the
/// distraction-peace pivot does not apply.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `belowQuotaMultiMinorDistractionPeaceTargets` peace decider previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The decider
/// implements the EXPAND-phase "while below quota and regiment-thin,
/// peace every distracting at-war minor so the few regiments we have
/// concentrate on the focused single-front minor" pivot used by the
/// seed-42 gp4 zero-gain stall: gp4 fights minor1 and minor2 with only
/// one or two regiments and the planner needs to drop one war so the
/// remaining regiments can finish the focused frontier.
///
/// Returns `const []` for any of the outer guards (in order):
///   1. [isBelowObserverConquestQuota] is `false` for
///      [ConquestSummary.oldWorldProvincesOwned] — at and above quota
///      the quota-met / consolidate / near-quota deciders own the
///      multi-minor decision instead.
///   2. `regimentCount <= 0` — zero-regiment survival deciders
///      ([stalledZeroRegimentAllFactionPeaceTargets],
///      [stalledZeroRegimentGpPeaceTargets]) own the peace decision
///      below the affordability gate; this decider does not also
///      compete for that zero band.
///   3. `regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar`
///      — once the active player can afford to declare and project
///      across multiple fronts the multi-minor distraction pivot is
///      not warranted; the planner can sustain the additional minor
///      wars while it walks the EXPAND ratchet.
///   4. [ConquestSummary.invadableProvinceIdsSorted] is empty — no
///      OW frontier means no minor war to concentrate on.
///   5. [stalledFocusMinorTarget] returns `null` — without an at-war
///      minor owning an invadable OW province the distraction-peace
///      pivot has no target to preserve.
///
/// When the guards pass:
///   * Walks [ThreatSummary.atWarWith] in iteration order and keeps
///     every entry that is a member of [Game.minorNations] (tribes
///     and Great Powers are dropped because the GP-blocker, peer-GP,
///     and GP-distraction-tribe deciders own those decisions) and is
///     not the focused-minor target preserved by
///     [stalledFocusMinorTarget].
///   * Sorts the result ascending so emission order is deterministic
///     for fixed inputs (Refs #2509 Must-have #7).
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
/// fixture and the in-file `collectStalledGreatPowerPeaceTargets`
/// `minorTribePeace` consumer chain until the now-completed S1 deletion of
/// that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Cost is dominated by the
/// [stalledFocusMinorTarget] scan once the outer guards pass plus a
/// single pass over [ThreatSummary.atWarWith]; matches the budget-rule
/// note in `colonizethis-turn-resolution-budget.mdc` (no global
/// province / tile scans introduced by the move).
List<String> belowQuotaMultiMinorDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final focus = stalledFocusMinorTarget(game: game, snapshot: snapshot);
  if (focus == null) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.minorNations.any((m) => m.id == factionId) && factionId != focus)
        factionId,
  ]..sort();
  return targets;
}

/// Returns `true` when at least one EXPAND-phase stalled-expansion
/// peace decider would emit a non-empty target list under the given
/// [game] / [snapshot] pair — the composite predicate used by the
/// diplomacy planner's `offerPeace` passes and the
/// `collectStalledGreatPowerPeaceTargets` public entry.
///
/// Canonical home (Refs #2509 S1) for the legacy
/// `stalledOwExpansionNeedsPeacePass` composite predicate previously
/// hosted in `diplomacy_planner_peace_targets.dart`. The composite
/// OR-checks all 22 EXPAND-phase peace deciders in a fixed deterministic
/// order identical to the order the current orchestrator evaluates
/// them; any one decider returning a non-empty result is sufficient
/// to signal that a stalled-expansion `offerPeace` pass is warranted.
///
/// `diplomacy_planner_peace_targets.dart` previously retained a thin delegating
/// stub for the legacy `diplomacy_planner_stalled_peace_test.dart`
/// fixture and the in-file `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` / `collectStalledGreatPowerPeaceTargets`
/// / `supplementMutualStalledGreatPowerPeaceOrders` consumer chains
/// until the now-completed S1 deletion of that file.
///
/// Pure and deterministic — identical inputs always yield identical
/// output (Refs #2509 Must-have #7). Cost is bounded by the union
/// of the individual decider costs.
bool stalledOwExpansionNeedsPeacePass({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    stalledFutileGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledGpBlockerFocusPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledExpansionDistractionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    atWarGpDistractionTribePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    multiFrontNonBlockerGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalMultiFrontGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalWeakGpSurvivalPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    weakHoldingsInvadableBlockerPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    mutualZeroRegimentGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledZeroRegimentAllFactionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledZeroRegimentGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    mutualExhaustedBelowQuotaGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalOwHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledBelowQuotaGpLeadPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    defaultStartGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    defaultStartFutileMinorPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    quotaMetBelowQuotaAtWarPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    quotaMetFutileBelowQuotaGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot) != null;

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
