/// Near-quota / below-quota EXPAND peace default-start arms (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

export 'expand_phase_planner_peace_stalled_pass_predicate.dart'
    show stalledOwExpansionNeedsPeacePass;

import 'expand_phase_planner_peace_targets.dart';

/// Near-quota hold-gains GP peace at 8–9 OW (issue #2509 S1).
///
/// Contract: `SPEC/ai/ai-architecture.md` § Diplomacy targeting. Peaces
/// distracting GP wars so the OW push can finish.
List<String> nearQuotaHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (!isBelowObserverConquestQuota(ownOw) ||
      !isStalledOldWorldExpansion(ownOw)) {
    return const [];
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
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
    return peaceTargetsExcludingBlocker(factionIds: gpWars, blocker: blocker);
  }
  return gpWars;
}

/// Below-quota at-war minor that still owns invadable OW land, or `null`.
String? belowQuotaActiveMinorWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return null;
  }
  return stalledFocusMinorTarget(game: game, snapshot: snapshot);
}

/// Peace every distracting at-war minor except the focused front.
///
/// Below quota and regiment-thin: concentrate remaining troops on one
/// minor. `SPEC/ai/ai-architecture.md` § Diplomacy targeting.
List<String> belowQuotaMultiMinorDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
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
  // Route the at-war-minor filter + ascending sort through the shared
  // [minorAtWarPeaceTargetsWhere] collector (Refs #3717 expand-peace
  // scoring-skeleton dedup); only the focused-minor exclusion remains
  // caller-specific. Byte-identical to the inline `isMinorFaction` + sort.
  return minorAtWarPeaceTargetsWhere(
    game: game,
    snapshot: snapshot,
    keep: (factionId) => factionId != focus,
  );
}
