/// Own-OW projections, tech-steal posture, and mutual-exhausted GP gates (Refs #3941).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        isBelowObserverConquestQuota,
        isCivilianBuildSpyTechStealPosture,
        isStalledOldWorldExpansion,
        kMutualExhaustedGpRegimentMax,
        kMutualExhaustedGpStalemateMinOw,
        kMutualExhaustedGpTreasuryMax;
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;

/// Number of techs [player] has unlocked — the count of `true` flags in
/// [Player.techUnlocked]. A `null` or empty map yields `0`.
///
/// Pure and deterministic for fixed inputs.
int unlockedTechCount(Player player) {
  final techs = player.techUnlocked;
  if (techs == null) return 0;
  var count = 0;
  for (final unlocked in techs.values) {
    if (unlocked) count++;
  }
  return count;
}

/// Whether the Great Power [activePlayerId] is **pursuing a tech-steal posture**
/// (decision #10, SPEC/ai/civilian-build-planner.md § Live economy wiring): it
/// has unlocked fewer techs than the most-advanced rival Great Power by at
/// least [kCivilianBuildSpyTechStealDeficit], so the civilian Spy build receives
/// the demand boost even at peace (passive RP posture; Refs #3834).
///
/// Iterates [Game.players] (Great Powers only — minor nations and tribes are not
/// [Player] entries; the list is small and bounded) to find the maximum rival
/// unlocked-tech count, then delegates the threshold comparison to the pure
/// data helper [isCivilianBuildSpyTechStealPosture]. Returns `false` when
/// [activePlayerId] is unknown or there are no rival Great Powers.
///
/// Pure and deterministic: identical [game] state and [activePlayerId] always
/// yield the same result (no randomness, no ordering dependence).
bool isPursuingTechStealPosture(Game game, String activePlayerId) {
  final active = game.playerById(activePlayerId);
  if (active == null) return false;
  var maxRivalCount = 0;
  var hasRival = false;
  for (final player in game.players) {
    if (player.id == activePlayerId) continue;
    hasRival = true;
    final count = unlockedTechCount(player);
    if (count > maxRivalCount) maxRivalCount = count;
  }
  if (!hasRival) return false;
  return isCivilianBuildSpyTechStealPosture(
    ownUnlockedTechCount: unlockedTechCount(active),
    maxRivalUnlockedTechCount: maxRivalCount,
  );
}

/// Whether the active player's own Old World expansion is stalled.
///
/// Single source of truth for the repeated
/// `isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)`
/// projection that was duplicated inline across the diplomatic-scoring and
/// expand-peace planner families. The active player's own OW holdings always
/// come from [ConquestSummary.oldWorldProvincesOwned]; deciders that test a
/// *different* faction's OW count (via a local `ownOw` / `partnerOw` /
/// `enemyOw` / `provinceCountOwnedBy(...)` value) must keep calling
/// [isStalledOldWorldExpansion] directly with that value.
///
/// Pure delegation — byte-identical to the inline projection it replaces, and
/// deterministic for fixed inputs (Refs #3717 diplomatic-scoring/expand-peace
/// dedup).
bool isOwnOldWorldExpansionStalled(AIWorldSnapshot snapshot) =>
    isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned);

/// Whether the active player's own Old World holdings are below the observer
/// conquest quota.
///
/// Single source of truth for the repeated
/// `isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)`
/// projection that was duplicated inline across the diplomatic-scoring and
/// expand-peace planner families. As with [isOwnOldWorldExpansionStalled],
/// deciders that test a *different* faction's OW count (via a local
/// `ownOw` / `partnerOw` / `enemyOw` / `provinceCountOwnedBy(...)` value)
/// must keep calling [isBelowObserverConquestQuota] directly with that value.
///
/// Pure delegation — byte-identical to the inline projection it replaces, and
/// deterministic for fixed inputs (Refs #3717 diplomatic-scoring/expand-peace
/// dedup).
bool isOwnOldWorldBelowConquestQuota(AIWorldSnapshot snapshot) =>
    isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned);

/// The signed Old World province lead [factionId] holds over the active player.
///
/// Single source of truth for the repeated
/// `provinceCountOwnedBy(game, <factionId>) -
/// snapshot.conquest.oldWorldProvincesOwned` projection — another faction's Old
/// World province count minus the active player's own — duplicated across the
/// conquest army-move stalled-GP-blocker bonus (`conquest_planner.dart`), the
/// orchestrator stalled min-regiment floor (`domain_planner_orchestrator.dart`),
/// and the EXPAND stronger-blocker / weak-holdings blocker peace deciders
/// (`expand_phase_planner_gp_blocker_peace.dart`). The active player's own OW
/// holdings always come from [ConquestSummary.oldWorldProvincesOwned]; a
/// positive result is the other faction's lead, which call sites treat as a
/// `lead` (peace deciders) or `deficit` (own-side regiment/bonus scaling).
///
/// Pure delegation to [provinceCountOwnedBy] — byte-identical to the inline
/// subtraction it replaces (a single O(1) memoised owner-count lookup; no extra
/// province scan, per `colonizethis-turn-resolution-budget.mdc`) and
/// deterministic for fixed inputs (Refs #3717 diplomatic-scoring/expand-peace
/// dedup).
int oldWorldProvinceLeadOver({
  required Game game,
  required AIWorldSnapshot snapshot,
  required String factionId,
}) =>
    provinceCountOwnedBy(game, factionId) -
    snapshot.conquest.oldWorldProvincesOwned;

/// Whether [factionId] (holding [ow] Old World provinces) qualifies as one side
/// of a "mutual-exhausted below-quota Great Power stalemate".
///
/// Single source of truth for the per-side qualification that was duplicated
/// for both the active player and the enemy Great Power across
/// [mutualExhaustedBelowQuotaGpStalematePeaceTargets]
/// (`expand_phase_planner_peer_peace.dart`) and the offer-peace bonus gate
/// `_mutualExhaustedBelowQuotaSoleGpStalemate`
/// (`diplomatic_candidate_scoring_offer_peace.dart`). A side qualifies when it:
///   * holds at least [kMutualExhaustedGpStalemateMinOw] Old World provinces,
///   * is below the observer conquest quota ([isBelowObserverConquestQuota] of
///     [ow]),
///   * has stalled Old World expansion ([isStalledOldWorldExpansion] of [ow]),
///   * resolves to a known [Player] ([Game.playerById]), and
///   * is materially exhausted: treasury `<=` [kMutualExhaustedGpTreasuryMax]
///     and standing regiments `<=` [kMutualExhaustedGpRegimentMax].
///
/// Callers pass the side's already-resolved Old World count
/// ([ConquestSummary.oldWorldProvincesOwned] for the active player,
/// [provinceCountOwnedBy] for the enemy) so no extra province scan is added; the
/// inter-side `(enemyOw - ownOw).abs()` proximity gate stays at the call site.
///
/// Pure projection over [game] — byte-identical to the inline per-side guards it
/// replaces (every operand is a side-effect-free read, so the guard evaluation
/// order is immaterial to the result) and deterministic for fixed inputs
/// (Refs #3717 offer-peace / expand-peace scoring-skeleton dedup).
bool mutualExhaustedGpStalemateSideQualifies({
  required Game game,
  required String factionId,
  required int ow,
}) {
  if (ow < kMutualExhaustedGpStalemateMinOw) {
    return false;
  }
  if (!isBelowObserverConquestQuota(ow)) {
    return false;
  }
  if (!isStalledOldWorldExpansion(ow)) {
    return false;
  }
  final player = game.playerById(factionId);
  if (player == null) {
    return false;
  }
  if (player.treasury > kMutualExhaustedGpTreasuryMax) {
    return false;
  }
  if (regimentCountForPlayer(game, factionId) > kMutualExhaustedGpRegimentMax) {
    return false;
  }
  return true;
}
