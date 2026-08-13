/// EXPAND declare-war planning (Refs #4079 Slice C; #4365 Slice A).
library;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_peace_frontier_helpers.dart';
import 'expand_phase_planner_economy.dart';
import 'expand_phase_planner_feedstock_acquisition.dart';
import 'expand_phase_planner_declare_war_cooldown.dart';

export 'expand_phase_planner_declare_war_cooldown.dart';

/// Priority-ordered OW declare-war target (issue #2509 § planExpandDeclareWar).
/// Feedstock-tile acquisition bias: Refs #2847 / `SPEC/ai/economy-planner.md`.
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
