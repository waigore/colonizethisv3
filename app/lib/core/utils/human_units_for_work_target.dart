/// Combined-region lookup of human units that can perform a work target.
///
/// Iterates [WorldState.allUnitsById] so overlay action-state modules do not
/// concatenate `oldWorld.units` + `newWorld.units` (Refs #4534).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Units owned by [playerId] whose type lists [workTarget] in
/// [workOrderTargetsByUnitType]. Missing type keys yield no match.
List<Unit> humanUnitsMatchingWorkTarget({
  required Game game,
  required String playerId,
  required String workTarget,
}) {
  return [
    for (final unit in game.worldState.allUnitsById.values)
      if (unit.ownerId == playerId &&
          (workOrderTargetsByUnitType[unit.type]?.contains(workTarget) ??
              false))
        unit,
  ];
}
