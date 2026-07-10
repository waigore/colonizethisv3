/// Diplomatic-history cooldown scans and at-war order-target gates (Refs #3941).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Whether the most-recent [Game.diplomaticHistoryEvents] entry satisfying
/// [matches] falls within [cooldownTurns] turns of [currentTurn].
///
/// Single source of truth for the "scan the diplomatic history newest first,
/// let the first matching event decide, and report whether it is inside the
/// cooldown window" skeleton shared by the declare-war / improve-relations
/// scoring cooldowns in `diplomatic_candidate_scoring.dart` and the EXPAND
/// peer-war peace cooldown ([expandRecentlyPeacedWithGreatPower]) in
/// `expand_phase_planner.dart` (Refs #3717 diplomatic-scoring/peace dedup).
/// Each caller supplies only its own [matches] predicate — directional
/// `fromFactionId`/`toFactionId` plus event-type membership for the scoring
/// cooldowns; symmetric `participants` plus the `peace` type for the EXPAND
/// cooldown — while the reversed scan, first-match-wins short-circuit, and the
/// `(currentTurn - event.turn) < cooldownTurns` window comparison live here.
///
/// Behaviour-preserving against the replaced inline loops: history is ordered
/// ascending by turn / intra-turn index, so `.reversed` visits the newest
/// event first and that newest matching event decides. The strict `<` keeps an
/// event exactly [cooldownTurns] turns old *outside* the window, and a missing
/// match returns `false`. This helper applies no non-positive-[cooldownTurns]
/// guard; callers that disable the cooldown that way (the EXPAND caller's
/// `cooldownTurns <= 0` early-out) must guard before calling. For positive
/// [cooldownTurns] the result is identical to the prior per-call-site loops.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7). Linear in the diplomatic-history length in the
/// worst case, matching `colonizethis-turn-resolution-budget.mdc`.
bool hasRecentDiplomaticEventWithinCooldown({
  required Game game,
  required int currentTurn,
  required int cooldownTurns,
  required bool Function(DiplomaticEvent event) matches,
}) {
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (!matches(event)) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}

/// Single source of truth for the "candidate is an at-war Great Power peace
/// target -> add a flat scoring bonus" skeleton repeated across the offer-peace
/// scoring family (`_offerPeacePeaceTargetListAdjustments` in
/// `diplomatic_candidate_scoring_offer_peace.dart`, Refs #3717
/// diplomatic-scoring/peace dedup). Returns [bonus] only when
/// [atWarGreatPowerTarget] holds *and* the lazily-evaluated [isPeaceTarget]
/// predicate matches; otherwise 0.
///
/// Behaviour-preserving against the replaced inline blocks, which each guarded
/// `targetGp != null && snapshot.threats.atWarWith.contains(target) && <peace
/// target match>` before adding a constant. [isPeaceTarget] is a callback so
/// the (potentially non-trivial, pure) peace-target collectors are only
/// consulted for eligible at-war GP candidates — preserving the original `&&`
/// short-circuit so no extra collector work runs for ineligible candidates.
///
/// Pure and deterministic for a given eligibility flag and predicate result
/// (Refs #2509 Must-have #7); the constant-time wrapper adds no scan cost
/// beyond the caller's own predicate, consistent with
/// `colonizethis-turn-resolution-budget.mdc`.
int atWarPeaceTargetBonus({
  required bool atWarGreatPowerTarget,
  required bool Function() isPeaceTarget,
  required int bonus,
}) => atWarGreatPowerTarget && isPeaceTarget() ? bonus : 0;

/// Single source of truth for the offer-peace family's repeated "the order's
/// target is a Great Power we are currently at war with" eligibility
/// projection (Refs #3717 offer-peace scoring-skeleton dedup). Returns `true`
/// only when [targetGp] is non-null (the target faction resolves to a [Player]
/// Great Power, as opposed to a tribe / minor nation) *and*
/// [AIWorldSnapshot.threats]'s `atWarWith` set contains [targetFactionId].
///
/// Behaviour-preserving against the replaced inline guards in
/// `diplomatic_candidate_scoring_offer_peace.dart`, which each spelled out
/// `targetGp != null && snapshot.threats.atWarWith.contains(order
/// .targetFactionId)` before applying an offer-peace adjustment. Callers pass
/// the already-resolved [targetGp] (`game.playerById(order.targetFactionId)`)
/// so no extra player lookup is introduced. Pairs with [atWarPeaceTargetBonus],
/// which consumes this flag as its `atWarGreatPowerTarget` input.
///
/// The original `&&` short-circuited the `atWarWith.contains` membership test
/// when `targetGp == null`; this helper always evaluates that pure, side-effect
/// free set membership, yielding an identical boolean result. Pure and
/// deterministic — identical inputs always yield identical results (Refs #2509
/// Must-have #7).
bool atWarGreatPowerOrderTarget({
  required Player? targetGp,
  required AIWorldSnapshot snapshot,
  required String targetFactionId,
}) => targetGp != null && snapshot.threats.atWarWith.contains(targetFactionId);

/// Single source of truth for the offer-peace family's repeated "the order's
/// target is the at-war primary invadable Old World GP blocker" eligibility
/// projection (Refs #3717 offer-peace scoring-skeleton dedup). Returns `true`
/// only when [targetGp] resolves to a [Player] Great Power, the
/// [primaryInvadableOldWorldGpBlocker] result passed as [invadableBlocker] is
/// non-null, [targetFactionId] equals that blocker, *and*
/// [AIWorldSnapshot.threats]'s `atWarWith` set contains the blocker.
///
/// Behaviour-preserving against the replaced inline guards in
/// `diplomatic_candidate_scoring_offer_peace.dart`, which each spelled out
/// `targetGp != null && blocker != null && order.targetFactionId == blocker &&
/// snapshot.threats.atWarWith.contains(blocker)` before applying a blocker-
/// specific offer-peace adjustment. Callers pass the already-resolved
/// [targetGp] (`game.playerById(order.targetFactionId)`) and the single
/// [primaryInvadableOldWorldGpBlocker] result so no extra player lookup or
/// blocker recomputation is introduced — consistent with
/// `colonizethis-turn-resolution-budget.mdc`.
///
/// The original `&&` short-circuited the later conjuncts when `targetGp` or the
/// blocker was null; this helper always evaluates the pure, side-effect-free
/// equality and set-membership tests, yielding an identical boolean result.
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool orderTargetIsAtWarInvadableBlocker({
  required Player? targetGp,
  required AIWorldSnapshot snapshot,
  required String targetFactionId,
  required String? invadableBlocker,
}) =>
    targetGp != null &&
    invadableBlocker != null &&
    targetFactionId == invadableBlocker &&
    snapshot.threats.atWarWith.contains(invadableBlocker);
