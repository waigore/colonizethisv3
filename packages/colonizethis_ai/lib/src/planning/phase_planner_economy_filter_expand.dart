/// EXPAND / NW economy filter resolvers (Refs #4079 Slice C).
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart'
    show ExpandEconomyPlan, cheapestRegimentBuildTreasuryCost;
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';

bool resolvePhaseEconomyExpandQuotaPressureActive({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseConquestExtraPassesActive(phasePlan: phasePlan);

/// When `true`, apply the GP-blocker-focus build threshold cap.
bool resolvePhaseEconomyExpandGpBlockerFocusActive({
  required PhasePlanOutcome phasePlan,
}) =>
    resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: phasePlan) &&
    phasePlan.expandGpOnlyInvadableFrontierActive;

/// Primary OW invadable GP blocker for the build pass, or `null`.
String? expandPrimaryInvadableGpBlockerFromPhasePlan({
  required PhasePlanOutcome phasePlan,
}) {
  if (!resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: phasePlan)) {
    return null;
  }
  return phasePlan.expandPrimaryInvadableGpBlockerFactionId;
}

/// Below-quota EXPAND regiment-rebuild trap (non-zero but thin standing army).
///
/// EXPAND / COLONIAL-lite only. `SPEC/ai/phase-planner-dispatch.md`.
bool resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive({
  required PhasePlanOutcome phasePlan,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
}) {
  if (!resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: phasePlan)) {
    return false;
  }
  if (atWarWithAnyGreatPower) {
    return false;
  }
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return false;
  }
  return hasInvadableProvinces;
}

/// Zero-regiment EXPAND rebuild trap with an invadable OW frontier.
bool resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive({
  required PhasePlanOutcome phasePlan,
  required int regimentCount,
  required bool hasInvadableProvinces,
}) {
  if (!resolvePhaseEconomyExpandQuotaPressureActive(phasePlan: phasePlan)) {
    return false;
  }
  return regimentCount == 0 && hasInvadableProvinces;
}

/// Treasury-recovery resource-need override (zero cash, zero NW, cargo on).
bool resolvePhaseNwTreasuryRecoveryResourceNeedOverrideActive({
  required AIWorldSnapshot snapshot,
  required ExpandEconomyPlan expandEconomyPlan,
}) =>
    snapshot.economy.treasury == 0 &&
    snapshot.colonial.newWorldProvincesOwned == 0 &&
    expandEconomyPlan.boostTreasuryRecoveryCargo;

/// Returns `true` when [playerId] owns at least one naval hull with
/// `cargoHold > 0` in any fleet.
bool playerOwnsCargoCapableNavalUnit(Game game, String playerId) {
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    for (final ship in fleet.ships) {
      if (NavalStatsCatalog.get(ship.typeId).cargoHold > 0) {
        return true;
      }
    }
  }
  return false;
}

/// First NW-acquisition transport bootstrap (Refs #2847 / #2924 Path F).
///
/// Relaxes planner-level regiment bias only; build affordability is unchanged.
bool resolvePhaseFirstNavalTransportBootstrapActive({
  required Game game,
  required AIWorldSnapshot snapshot,
  required ExpandEconomyPlan expandEconomyPlan,
  required String playerId,
}) {
  if (snapshot.colonial.newWorldProvincesOwned != 0) return false;
  if (playerOwnsCargoCapableNavalUnit(game, playerId)) return false;
  final ow = snapshot.conquest.oldWorldProvincesOwned;
  if (ow >= 2 && isBelowObserverConquestQuota(ow)) {
    return true;
  }
  return expandEconomyPlan.boostTreasuryRecoveryCargo &&
      snapshot.economy.treasury < cheapestRegimentBuildTreasuryCost();
}
