/// EXPAND-phase peer-peace: zero-regiment and mutual-exhausted stalemate peace (Refs #3967 step 4).
///
/// Topic split from `expand_phase_planner_peer_peace.dart`; public
/// symbols remain re-exported by that barrel.
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'planning_helpers.dart'
    show
        gpFactionIdsAtWarWith,
        isOwnOldWorldExpansionStalled,
        mutualExhaustedGpStalemateSideQualifies,
        nonGreatPowerAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

/// Peace every at-war GP when stalled below quota with zero regiments.
///
/// `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
List<String> stalledZeroRegimentGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isZeroRegimentSurvivalOwContext(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final targets = gpFactionIdsAtWarWith(game, snapshot);
  return targets;
}

/// Peace the sole GP foe when both sides have zero standing regiments.
List<String> mutualZeroRegimentGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldExpansionStalled(snapshot)) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  if (regimentCountForPlayer(game, enemy) > 0) {
    return const [];
  }
  return [enemy];
}

/// Peace every at-war minor and tribe when stalled with zero regiments.
List<String> stalledZeroRegimentAllFactionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isZeroRegimentSurvivalOwContext(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return const [];
  }
  if (regimentCountForPlayer(game, snapshot.playerId) > 0) {
    return const [];
  }
  // Route the non-GP (minor + tribe) at-war filter + ascending sort through the
  // shared [nonGreatPowerAtWarPeaceTargetsWhere] collector (Refs #3749 step 5
  // expand-peace collector dedup). Byte-identical to the inline
  // `playerById == null` comprehension + `..sort()`: the collector keeps the
  // bare non-GP `playerById == null` membership test (not the minor/tribe
  // membership predicates) so absorbed-faction at-war ids are preserved.
  return nonGreatPowerAtWarPeaceTargetsWhere(game: game, snapshot: snapshot);
}

/// Peace the sole GP foe when both sides are mutual-plateau and exhausted.
List<String> mutualExhaustedBelowQuotaGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  // Route the duplicated per-side "mutual-exhausted below-quota GP stalemate"
  // qualification through the shared [mutualExhaustedGpStalemateSideQualifies]
  // helper (Refs #3717 offer-peace / expand-peace scoring-skeleton dedup). The
  // helper bundles the same side-effect-free guards (min-OW + below-quota +
  // stalled + known player + treasury/regiment exhaustion) the inline checks
  // applied for both the active player and the enemy GP, so the result is
  // byte-identical; the inter-side `(enemyOw - ownOw).abs()` proximity gate
  // stays here.
  if (!mutualExhaustedGpStalemateSideQualifies(
    game: game,
    factionId: snapshot.playerId,
    ow: ownOw,
  )) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1) {
    return const [];
  }
  final enemy = gpWars.single;
  final enemyOw = provinceCountOwnedBy(game, enemy);
  if (!mutualExhaustedGpStalemateSideQualifies(
    game: game,
    factionId: enemy,
    ow: enemyOw,
  )) {
    return const [];
  }
  if ((enemyOw - ownOw).abs() > 1) {
    return const [];
  }
  return [enemy];
}
