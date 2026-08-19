import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

import 'expand_phase_planner_gp_blocker_peace_pivot.dart';

export 'expand_phase_planner_gp_blocker_peace_distraction.dart';
export 'expand_phase_planner_gp_blocker_peace_pivot.dart';

/// Strongest at-war non-blocker GP that owns invadable OW land, or `null`.
String? stalledStrongerGpBlockerPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldExpansionStalled(snapshot)) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final pivot = resolveStalledMinorOrGpBlockerPivot(
    game: game,
    snapshot: snapshot,
  );
  if (pivot == null) {
    return null;
  }
  final provinceOwner = pivot.provinceOwner;
  final gpBlockerFocus = pivot.gpBlockerFocus;
  if (gpBlockerFocus) {
    final anyMinorOwnsOw = anyMinorOwnsOldWorldProvince(game);
    if (!anyMinorOwnsOw) {
      return null;
    }
  }
  final primaryBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  String? bestFactionId;
  var bestLead = 0;
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (factionId == primaryBlocker) continue;
    final ownsInvadable = factionOwnsInvadableOldWorldProvince(
      snapshot: snapshot,
      provinceOwner: provinceOwner,
      factionId: factionId,
    );
    if (!ownsInvadable) continue;
    final lead = oldWorldProvinceLeadOver(
      game: game,
      snapshot: snapshot,
      factionId: factionId,
    );
    if (lead <= 0) continue;
    if (lead > bestLead) {
      bestLead = lead;
      bestFactionId = factionId;
    }
  }
  return bestFactionId;
}

/// Peace every non-blocker GP war on a GP-only (or mixed) invadable frontier.
List<String> stalledGpBlockerFocusPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
    game: game,
    snapshot: snapshot,
    provinceOwner: provinceOwner,
  );
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    return const [];
  }
  if (minorsOwnInvadable && gpWars.length <= 1) {
    // Sole GP war on a mixed frontier must still drop non-blocker fronts
    // (seed-42 gp4/gp5 vs gp3 blocker; Refs #2509).
    if (gpWars.length == 1 && gpWars.single != blocker) {
      return [gpWars.single];
    }
    return const [];
  }
  if (minorsOwnInvadable) {
    return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
  }
  return peaceTargetsExcludingBlocker(
    factionIds: snapshot.threats.atWarWith,
    blocker: blocker,
  );
}

/// Peace the OW frontier blocker when this GP is critically weak and outmatched.
List<String> weakHoldingsInvadableBlockerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final zeroRegiments = regimentCountForPlayer(game, snapshot.playerId) == 0;
  final belowQuota = isOwnOldWorldBelowConquestQuota(snapshot);
  if (snapshot.conquest.oldWorldProvincesOwned >
          kFewOldWorldProvincesDefendThreshold &&
      !belowQuota &&
      !(zeroRegiments && isOwnOldWorldExpansionStalled(snapshot))) {
    return const [];
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      !snapshot.threats.atWarWith.contains(blocker) ||
      game.playerById(blocker) == null) {
    return const [];
  }
  final lead = oldWorldProvinceLeadOver(
    game: game,
    snapshot: snapshot,
    factionId: blocker,
  );
  final minLead = belowQuota
      ? (snapshot.conquest.oldWorldProvincesOwned <=
                kObserverDefaultStartOldWorldProvincesPerGp + 2
            ? 1
            : kUnwinnableSoleGpMinProvinceDeficit)
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  if (lead < minLead) {
    return const [];
  }
  return [blocker];
}
