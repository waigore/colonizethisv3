import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_peace_default_start_quota.dart'
    show nearQuotaHoldPeaceTargets;
import 'expand_phase_planner_gp_blocker_peace.dart';
import 'expand_phase_planner_peace_default_start.dart'
    show
        defaultStartFutileMinorPeaceTargets,
        defaultStartGpPeaceTargets;
import 'expand_phase_planner_peace_targets.dart';
import 'expand_phase_planner_peer_peace.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

/// Returns `true` when at least one EXPAND-phase stalled-expansion
/// peace decider would emit a non-empty target list under the given
/// [game] / [snapshot] pair.
bool stalledOwExpansionNeedsPeacePass({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    stalledFutileGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledGpBlockerFocusPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledExpansionDistractionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    atWarGpDistractionTribePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    multiFrontNonBlockerGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalMultiFrontGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalWeakGpSurvivalPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    weakHoldingsInvadableBlockerPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    mutualZeroRegimentGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledZeroRegimentAllFactionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledZeroRegimentGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    mutualExhaustedBelowQuotaGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalOwHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledBelowQuotaGpLeadPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    defaultStartGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    defaultStartFutileMinorPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    quotaMetBelowQuotaAtWarPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    quotaMetFutileBelowQuotaGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot) != null;
