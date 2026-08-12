import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/src/world/army_movement.dart';

/// Army fixture for army-movement pins (Refs #4330 Slice C).
Army testArmy(
  String id, {
  String ownerId = 'p1',
  String stationedProvinceId = 'oldWorld|p1',
  String regionId = 'oldWorld',
  List<String> regimentUnitIds = const [],
  bool isHomeArmy = false,
}) => Army(
  id: id,
  ownerId: ownerId,
  regionId: regionId,
  stationedProvinceId: stationedProvinceId,
  regimentUnitIds: regimentUnitIds,
  isHomeArmy: isHomeArmy,
);

/// Orders-phase world with optional OW/NW provinces and [armies].
WorldState armyMoveWorld({
  List<Army> armies = const [],
  List<Province> oldWorld = const [],
  List<Province> newWorld = const [],
  List<Unit> oldWorldUnits = const [],
}) => TestFixtures.worldStateAtOrdersPhase(
  oldWorld: RegionData(provinces: oldWorld, units: oldWorldUnits),
  newWorld: RegionData(provinces: newWorld),
  armies: armies,
);

/// Collects ignore reasons (or `'applied'`) from [applyArmyMoveOrdersToRegion].
List<String?> collectArmyMoveIgnoreReasons(
  WorldState world,
  MapTopology topology,
  Map<String, List<ArmyMoveOrder>> orders, {
  required String regionId,
  bool Function(String playerId, String destinationProvinceId)?
  isDestinationOwnedByPlayer,
}) {
  final traces = <String?>[];
  applyArmyMoveOrdersToRegion(
    world,
    topology,
    orders,
    regionId: regionId,
    isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    onArmyMoveOrderTrace:
        ({
          required playerId,
          required order,
          required applied,
          regionId,
          destinationProvinceId,
          ignoreReason,
        }) => traces.add(ignoreReason ?? (applied ? 'applied' : null)),
  );
  return traces;
}
