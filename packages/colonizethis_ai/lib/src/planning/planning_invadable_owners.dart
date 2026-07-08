/// Invadable Old-World frontier ownership scans and collectors (Refs #3941).
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';

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
/// province's owner resolves to a [Game.minorNations] member (via the shared
/// [isMinorFaction] predicate); an unowned (absent / `null`) entry or a
/// Great-Power / tribe owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool anyInvadableProvinceOwnedByMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
}) => snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
  final owner = provinceOwner[pid];
  return owner != null && isMinorFaction(game, owner);
});

/// Whether any invadable Old-World frontier province is currently owned by a
/// Great Power.
///
/// Single source of truth for the `gpOwnsInvadable` scan —
/// `snapshot.conquest.invadableProvinceIdsSorted.any((pid) =>
/// game.playerById(provinceOwner[pid] ?? '') != null)` — duplicated across the
/// EXPAND GP-only-frontier gate ([expandIsOldWorldGpOnlyInvadableFrontier]) and
/// the declare-war candidate-scoring near-parity suppression (the
/// `invadableOwOwnedByGp` projection in `diplomatic_candidate_scoring_declare_
/// war.dart`) (Refs #3717 expand-peace / diplomatic-scoring scoring-skeleton
/// dedup). Companion of [anyInvadableProvinceOwnedByMinor], which answers the
/// minor-owner variant of the same invadable-frontier ownership question.
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc`.
/// Walks [ConquestSummary.invadableProvinceIdsSorted] with the original
/// [Iterable.any] short-circuit: returns `true` as soon as an invadable
/// province's owner resolves to a [Game.playerById] Great Power; an unowned
/// (absent / `null`) entry — normalised to the empty string so `playerById`
/// returns `null` — or a minor / tribe owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool anyInvadableProvinceOwnedByGreatPower({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
}) => snapshot.conquest.invadableProvinceIdsSorted.any(
  (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
);

/// Whether [factionId] owns at least one invadable Old-World frontier province.
///
/// Single source of truth for the
/// `snapshot.conquest.invadableProvinceIdsSorted.any((pid) =>
/// provinceOwner[pid] == <factionId>)` scan duplicated across the conquest /
/// expand-peace planners ([stalledStrongerGpBlockerPeaceTarget]'s sibling
/// peer-peace / peace-target / default-start collectors and the conquest
/// declared-target check) and the declare-war / offer-peace candidate-scoring
/// families (the declare-war target context's `invadableGpBlocker` /
/// `tribeOwnsOwInvadable` projections and the offer-peace stalled-GP-war
/// adjustments) (Refs #3717 diplomatic-scoring / expand-peace scoring-skeleton
/// dedup). Companion of [anyInvadableProvinceOwnedByMinor], which answers the
/// minor-owner variant of the same invadable-frontier ownership question.
///
/// Takes a non-nullable-value [provinceOwner] (`Map<String, String>`), matching
/// the `getProvinceOwnerMap(game)` callers; the structurally-identical
/// move-scoring site that threads a `Map<String, String?>` owner map keeps its
/// inline scan.
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc`.
/// Walks [ConquestSummary.invadableProvinceIdsSorted] with the original
/// [Iterable.any] short-circuit: returns `true` as soon as an invadable
/// province's owner equals [factionId]; an unowned (absent / `null`) entry or a
/// different owner never matches.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
bool factionOwnsInvadableOldWorldProvince({
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required String factionId,
}) => snapshot.conquest.invadableProvinceIdsSorted.any(
  (pid) => provinceOwner[pid] == factionId,
);

/// Adds, into [into], every minor-nation owner of an invadable Old-World
/// frontier province with whom this Great Power is not already at war.
///
/// Single source of truth for the `for (final pid in
/// snapshot.conquest.invadableProvinceIdsSorted) { final owner =
/// provinceOwner[pid]; if (owner == null || !isMinorFaction(game, owner) ||
/// snapshot.threats.atWarWith.contains(owner)) continue; candidates.add(owner);
/// }` collector skeleton duplicated across the legacy colonial-pressure
/// declare-war target deciders in `diplomacy_planner_declare_war_targets.dart`
/// ([criticalWeakUninvadedMinorDeclareTarget], [plateauOwMinorDeclareTarget],
/// [defaultStartOwMinorDeclareTarget]) (Refs #3717 declare-war target collector
/// dedup).
///
/// Callers pass the already-resolved [provinceOwner] map
/// (`getProvinceOwnerMap(game)`) so no extra O(provinces) ownership scan is
/// introduced — consistent with `colonizethis-turn-resolution-budget.mdc` — and
/// supply their own mutable [into] set so a caller may seed it with
/// adjacent-owner candidates first (set membership de-duplicates; final
/// ordering is the caller's `..sort()`). Walks
/// [ConquestSummary.invadableProvinceIdsSorted] in order, skipping unowned
/// (absent / `null`) entries, non-minor (Great-Power / tribe) owners, and minors
/// already in [ThreatSummary.atWarWith].
///
/// Pure and deterministic — identical inputs always yield identical additions
/// (Refs #2509 Must-have #7).
void addInvadableProvinceMinorOwnersNotAtWar({
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required Set<String> into,
}) {
  for (final pid in snapshot.conquest.invadableProvinceIdsSorted) {
    final owner = provinceOwner[pid];
    if (owner == null ||
        !isMinorFaction(game, owner) ||
        snapshot.threats.atWarWith.contains(owner)) {
      continue;
    }
    into.add(owner);
  }
}
