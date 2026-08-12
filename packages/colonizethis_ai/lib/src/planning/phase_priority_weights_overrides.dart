/// § Resource-need override predicates for phase priority weights (Refs #4310 Slice B).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'expand_phase_planner.dart' show ExpandEconomyPlan;
import 'phase_priority_weights.dart';

/// True when the § Resource-need overrides treasury-recovery predicate
/// is active for this dispatch (Refs #2847).
///
/// Predicate: `economy.treasury == 0` **and**
/// `colonial.newWorldProvincesOwned == 0` **and**
/// `expandEconomyPlan.boostTreasuryRecoveryCargo == true`.
///
/// Used for the `newWorldAcquisition` weight floor only. Path E colonial
/// dispatch uses [isNwLockRecoveryPathEActive] so the NW chain stays armed
/// after Path F world-market credits raise treasury above zero.
bool isNwTreasuryRecoveryOverrideActive({
  required AIWorldSnapshot snapshot,
  required ExpandEconomyPlan expandEconomyPlan,
}) =>
    snapshot.economy.treasury == 0 &&
    snapshot.colonial.newWorldProvincesOwned == 0 &&
    expandEconomyPlan.boostTreasuryRecoveryCargo;

/// True when the EXPAND lock-recovery Path E chain should stay active
/// (Refs #2924).
///
/// Predicate: `colonial.newWorldProvincesOwned == 0` **and** at least one of
/// `expandEconomyPlan.boostTreasuryRecoveryCargo` (treasury still below the
/// cheapest regiment build cost) or `expandEconomyPlan.forceCheapestRegimentBuild`
/// (geographic peer-war lock Arm D). Without this broader gate,
/// `planColonialMilitary` / `planColonialNaval` revert to `defaultPlan` as
/// soon as treasury rises above zero even though the GP still owns no NW
/// provinces and the beachhead / invasion chain is unfinished.
bool isNwLockRecoveryPathEActive({
  required AIWorldSnapshot snapshot,
  required ExpandEconomyPlan expandEconomyPlan,
}) =>
    snapshot.colonial.newWorldProvincesOwned == 0 &&
    (expandEconomyPlan.boostTreasuryRecoveryCargo ||
        expandEconomyPlan.forceCheapestRegimentBuild);

/// Returns the lifted `newWorldAcquisition` floor from § Resource-need
/// overrides, or `0.0` when no override fires.
double nwAcquisitionFloor({
  required AIWorldSnapshot snapshot,
  required Game game,
  required ExpandEconomyPlan expandEconomyPlan,
}) {
  var floor = 0.0;
  if (isNwTreasuryRecoveryOverrideActive(
    snapshot: snapshot,
    expandEconomyPlan: expandEconomyPlan,
  )) {
    if (kPhasePriorityNwTreasuryRecoveryFloor > floor) {
      floor = kPhasePriorityNwTreasuryRecoveryFloor;
    }
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      regimentCountForPlayer(game, snapshot.playerId) == 0) {
    if (kPhasePriorityNwZeroRegimentFloor > floor) {
      floor = kPhasePriorityNwZeroRegimentFloor;
    }
  }
  return floor;
}
