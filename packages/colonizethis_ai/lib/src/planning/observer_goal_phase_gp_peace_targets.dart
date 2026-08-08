import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'planning_helpers.dart';

/// EXPAND: peace non-blocker Great Power fronts when fighting 2+ GPs (Refs #2509 S10).
List<String> expandPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!(observerGoalPhaseFor(snapshot: snapshot, game: game) ==
      ObserverGoalPhase.expand)) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  // Minor-first: exit every GP front while uninvaded minors remain (Refs #2509).
  if (gpWars.isNotEmpty &&
      hasUninvadedOldWorldMinor(game: game, snapshot: snapshot) &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return gpWars..sort();
  }
  if (gpWars.length == 1) {
    final soleGp = gpWars.single;
    final ownOw = snapshot.conquest.oldWorldProvincesOwned;
    final partnerOw = provinceCountOwnedBy(game, soleGp);
    if (isMutualBelowQuotaPlateauPeer(ownOw: ownOw, partnerOw: partnerOw) &&
        isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot) &&
        !hasUninvadedOldWorldMinor(game: game, snapshot: snapshot)) {
      return gpWars;
    }
    return const [];
  }
  if (gpWars.isEmpty) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null || !gpWars.contains(blocker)) {
    return const [];
  }
  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}

/// GP owning the most invadable New World provinces (colonial frontier blocker).
String? primaryColonialGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final counts = <String, int>{};
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null || game.playerById(owner) == null) {
      continue;
    }
    counts[owner] = (counts[owner] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  String? bestGpId;
  var bestCount = 0;
  for (final provinceId in invadable) {
    final owner = provinceOwner[provinceId];
    if (owner == null) {
      continue;
    }
    final count = counts[owner];
    if (count == null) {
      continue;
    }
    if (count > bestCount) {
      bestCount = count;
      bestGpId = owner;
    }
  }
  return bestGpId;
}

/// COLONIAL: peace non-blocker Great Power fronts when fighting 2+ GPs (Refs #2509 S10).
List<String> colonialPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!(observerGoalPhaseFor(snapshot: snapshot, game: game) ==
      ObserverGoalPhase.colonial)) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length <= 1) {
    return const [];
  }
  final blocker = primaryColonialGpBlocker(game: game, snapshot: snapshot);
  if (blocker == null || !gpWars.contains(blocker)) {
    return const [];
  }
  return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
}

/// DEVELOP: peace all at-war Great Powers (Refs #2509 S10).
List<String> developPhaseGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isObserverDevelopPhase(snapshot: snapshot, game: game)) {
    return const [];
  }
  return gpFactionIdsAtWarWith(game, snapshot);
}
