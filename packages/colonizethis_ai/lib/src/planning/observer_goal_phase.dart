import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'colonial_pressure.dart';

/// Observer tuning phases for Full AI (Refs #2509 S10).
enum ObserverGoalPhase {
  /// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` — OW expansion first.
  expand,

  /// OW quota met and sea-reachable NW / colonial targets remain.
  colonial,

  /// OW quota met; no visible colonial acquisition targets — improve extractable tiles.
  develop,
}

/// Deterministic phase from [AIWorldSnapshot] (PlayerView-derived; Refs #2509).
ObserverGoalPhase observerGoalPhaseFor(AIWorldSnapshot snapshot) {
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  if (isBelowObserverConquestQuota(ownOw)) {
    return ObserverGoalPhase.expand;
  }
  if (hasColonialAcquisitionTargets(snapshot.colonial)) {
    return ObserverGoalPhase.colonial;
  }
  return ObserverGoalPhase.develop;
}

/// EXPAND phase: suppress NW colonial diplomacy, military, civilian, and naval work.
bool shouldSuppressNewWorldColonialOrders(AIWorldSnapshot snapshot) =>
    observerGoalPhaseFor(snapshot) == ObserverGoalPhase.expand;

/// Whether [targetFactionId] is a tribe/minor colonial diplomacy target in EXPAND.
bool isExpandPhaseColonialDiplomacyTarget({
  required AIWorldSnapshot snapshot,
  required String targetFactionId,
  required Map<String, String> provinceOwner,
  required bool isTribeFaction,
  required bool isMinorFaction,
}) {
  if (!shouldSuppressNewWorldColonialOrders(snapshot)) {
    return false;
  }
  if (isTribeFaction || isMinorFaction) {
    if (snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted
        .contains(targetFactionId)) {
      return true;
    }
    if (snapshot.colonial.preferredColonialTargetFactionIdsSorted
        .contains(targetFactionId)) {
      return true;
    }
    if (snapshot.colonial.invadableNewWorldProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == targetFactionId,
    )) {
      return true;
    }
  }
  return false;
}

/// True when a civilian work order targets New World colonial tiles (EXPAND suppress).
bool isNewWorldColonialWorkOrder(WorkOrder order) {
  final regionId = ProvinceId.regionIdFrom(order.targetTileKey);
  if (regionId == kNewWorldRegionId) {
    return order.target == kWorkTargetPurchaseLand ||
        order.target == kWorkTargetBuildImprovement;
  }
  return false;
}
