/// Shared planning-layer helpers (Refs #3278 dedup).
///
/// Canonical home for small pure functions that were previously copy-pasted
/// inline across the phase-planner / filter modules:
///
///   - [gpFactionIdsAtWarWith] — the GP-only at-war filter that replaces the
///     `[for (final f in snapshot.threats.atWarWith) if (game.playerById(f)
///     != null) f]` comprehension repeated across the planners.
///   - [isAtWarWithAnyGreatPower] — the boolean "are we at war with any Great
///     Power?" presence check that replaces the inline
///     `snapshot.threats.atWarWith.any((id) => game.playerById(id) != null)`
///     short-circuit predicate repeated across the planners / scoring families.
///   - [scaleWeightedBonus] — the `<= 0.0 → 0`, clamp-to-`1.0`, `round()`
///     weight-scaling idiom shared by the soft-phase bonus/floor resolvers.
///   - [resolvePhaseColonialPressureActive] /
///     [resolvePhaseExpandOrColonialLiteActive] — the structural phase
///     predicates shared by the conquest / economy / diplomacy / goal filters.
///   - [resolvePhaseNewWorldAcquisitionWeight] /
///     [resolvePhaseOldWorldConquestWeight] /
///     [resolvePhaseOldWorldCivilianWeight] /
///     [resolvePhaseNewWorldCivilianWeight] — the soft-phase
///     `PhasePlanOutcome` → `priorityWeights.<slot>` projections shared by the
///     conquest / naval / diplomacy / economy phase filters.
///   - [hasRecentDiplomaticEventWithinCooldown] — the "scan
///     `Game.diplomaticHistoryEvents` newest-first, let the first matching
///     event decide whether it falls inside a cooldown window" skeleton shared
///     by the declare-war / improve-relations scoring cooldowns and the EXPAND
///     peer-war peace cooldown.
///   - [atWarPeaceTargetBonus] / [atWarGreatPowerOrderTarget] — the offer-peace
///     "at-war Great Power peace candidate" eligibility gate and flat-bonus
///     emitter shared across the offer-peace scoring adjustments.
///
/// Keeping these in one place removes the duplication flagged by the
/// `repo.ai_dedup_gp_wars_filter` and `repo.ai_dedup_weight_scale_clamp`
/// repo-lint rules and preserves the existing deterministic behaviour exactly.
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns every Great Power the active player is currently at war with as a
/// new ascending-sorted `List<String>` of `factionId`s.
///
/// Filters [ThreatSummary.atWarWith] down to factions for which
/// [Game.playerById] returns a non-null [Player] — tribes and minor nations
/// are not [Player] entries and are therefore excluded. The result is sorted
/// ascending so callers see a stable order regardless of the iteration order
/// of [ThreatSummary.atWarWith] (the inline comprehensions this helper
/// replaces either sorted their output or used it only for
/// length / membership checks, so the sort is behaviour-preserving).
///
/// Pure and deterministic — identical inputs always yield identical lists
/// (Refs #2509 Must-have #7).
List<String> gpFactionIdsAtWarWith(Game game, AIWorldSnapshot snapshot) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}

/// Whether the active player is currently at war with **any** Great Power.
///
/// Single source of truth for the boolean
/// `snapshot.threats.atWarWith.any((id) => game.playerById(id) != null)`
/// presence check that was duplicated inline across the planner / scoring
/// families (conquest, economy, diplomacy, expand-peace, declare-war scoring,
/// orchestrator economy build). Returns `true` as soon as the first
/// [ThreatSummary.atWarWith] entry resolves to a [Player] Great Power via
/// [Game.playerById]; tribes and minor nations are not [Player] entries and so
/// never satisfy the check.
///
/// Behaviour-preserving against the replaced inline predicates: this helper
/// retains the original [Iterable.any] short-circuit (no list is materialised
/// and no sort is performed), so it is strictly cheaper than
/// `gpFactionIdsAtWarWith(game, snapshot).isNotEmpty` for the pure presence
/// case — consistent with `colonizethis-turn-resolution-budget.mdc`. Use
/// [gpFactionIdsAtWarWith] when the caller needs the GP id list or its length.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool isAtWarWithAnyGreatPower(Game game, AIWorldSnapshot snapshot) =>
    snapshot.threats.atWarWith.any((id) => game.playerById(id) != null);

/// Scales [baseConstant] by [weight] clamped to `[0.0, 1.0]`, returning the
/// rounded integer result.
///
/// Shared body of the soft-phase weight-scaling resolvers (Refs #2847 Phase 3
/// consumer wiring). Matches the prior inline idiom exactly:
///
///   - `weight <= 0.0` returns `0` (no bonus / floor applied).
///   - `weight >= 1.0` is clamped to `1.0`, returning `baseConstant` exactly.
///   - Intermediate weights return `round(baseConstant × weight)`.
///
/// The `<= 0.0` guard and `> 1.0` clamp boundaries are preserved verbatim from
/// the call sites so rounding semantics are identical.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
int scaleWeightedBonus(double weight, int baseConstant) {
  if (weight <= 0.0) {
    return 0;
  }
  final clamped = weight > 1.0 ? 1.0 : weight;
  return (baseConstant * clamped).round();
}

/// Structural predicate: `true` only under [ObserverGoalPhase.colonial].
///
/// Single source of truth for the colonial-pressure "active" gate shared by
/// the conquest, economy, diplomacy, and goal phase filters. Each filter's
/// public resolver delegates here so the `phase == ObserverGoalPhase.colonial`
/// comparison lives once.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
bool resolvePhaseColonialPressureActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.colonial;

/// Structural predicate: `true` under [ObserverGoalPhase.expand] and
/// [ObserverGoalPhase.colonialLite] (the below-quota OW-expansion phases).
///
/// Single source of truth for the `phase == expand || phase == colonialLite`
/// gate shared by the conquest extra-passes resolver and the goal-filter
/// colonial-pressure suppression resolver. Both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at entry.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
bool resolvePhaseExpandOrColonialLiteActive(ObserverGoalPhase phase) =>
    phase == ObserverGoalPhase.expand ||
    phase == ObserverGoalPhase.colonialLite;

/// Projects the soft-phase New-World-acquisition priority weight from
/// [phasePlan].
///
/// Single source of truth for the
/// `phasePlan.priorityWeights.newWorldAcquisition` projection shared by the
/// conquest, naval, diplomacy, and economy phase filters (Refs #3717
/// phase-filter weight-projection dedup). Each family's public weight resolver
/// delegates here so the `PhasePlanOutcome` → `priorityWeights` slot mapping
/// lives once, mirroring the existing [resolvePhaseColonialPressureActive] /
/// [scaleWeightedBonus] dedup. Reads only `phasePlan.priorityWeights` and never
/// inspects sibling slots.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
double resolvePhaseNewWorldAcquisitionWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.newWorldAcquisition;

/// Projects the soft-phase Old-World-conquest priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.oldWorldConquest` projection shared by the
/// conquest and diplomacy declare-war filters (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseOldWorldConquestWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.oldWorldConquest;

/// Projects the soft-phase Old-World-civilian priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.oldWorldCivilian` projection used by the
/// economy filter (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseOldWorldCivilianWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.oldWorldCivilian;

/// Projects the soft-phase New-World-civilian priority weight from [phasePlan].
///
/// Companion of [resolvePhaseNewWorldAcquisitionWeight]; single source of truth
/// for the `phasePlan.priorityWeights.newWorldCivilian` projection used by the
/// economy filter (Refs #3717).
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double resolvePhaseNewWorldCivilianWeight(PhasePlanOutcome phasePlan) =>
    phasePlan.priorityWeights.newWorldCivilian;

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
}) =>
    atWarGreatPowerTarget && isPeaceTarget() ? bonus : 0;

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
}) =>
    targetGp != null && snapshot.threats.atWarWith.contains(targetFactionId);

/// Whether any invadable Old-World frontier province is currently owned by a
/// minor nation.
///
/// Single source of truth for the `minorsOwnInvadable` scan —
/// `snapshot.conquest.invadableProvinceIdsSorted.any((pid) { final owner =
/// provinceOwner[pid]; return owner != null && game.minorNations.any((m) =>
/// m.id == owner); })` — duplicated across the EXPAND-peace deciders
/// ([stalledStrongerGpBlockerPeaceTarget], [stalledGpBlockerFocusPeaceTargets],
/// [stalledExpansionDistractionPeaceTargets],
/// [expandIsOldWorldGpOnlyInvadableFrontier], the peer-peace ratchet collector)
/// and the declare-war family (the `diplomacy_planner` declare-war tribe-drop
/// filter and the declare-war candidate-scoring near-parity suppression) (Refs
/// #3717 expand-peace scoring-skeleton dedup).
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc`.
/// Walks [ConquestSummary.invadableProvinceIdsSorted] with the original
/// [Iterable.any] short-circuit: returns `true` as soon as an invadable
/// province's owner resolves to a [Game.minorNations] member; an unowned
/// (absent / `null`) entry or a Great-Power / tribe owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool anyInvadableProvinceOwnedByMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
}) =>
    snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
      final owner = provinceOwner[pid];
      return owner != null && game.minorNations.any((m) => m.id == owner);
    });
