/// EXPAND declare-war planning and peer-war peace cooldown (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart'
    show hasRecentDiplomaticEventWithinCooldown;

import 'expand_phase_planner_economy.dart';
import 'expand_phase_planner_feedstock_acquisition.dart';


/// Whether the active player and [peerGpId] completed a peace event within
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
  return hasRecentDiplomaticEventWithinCooldown(
    game: game,
    currentTurn: currentTurn,
    cooldownTurns: cooldownTurns,
    matches: (event) =>
        event.type == DiplomaticEventType.peace &&
        event.participants.contains(activePlayerId) &&
        event.participants.contains(peerGpId),
  );
}

/// Number of turns the EXPAND declare-war planner suppresses a re-declaration
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
// `mutualExhaustedBelowQuotaGpStalematePeaceTargets`) are canonical
// in `expand_phase_planner_peer_peace.dart` (Refs #3941).
