import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';

const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);

final uOld = Unit(
  id: 'u-old',
  type: kUnitTypeExplorer,
  ownerId: 'p1',
  locationProvinceId: 'oldWorld|P1',
  tileKey: 'oldWorld|P1|0|0',
);
final uNew = Unit(
  id: 'u-new',
  type: kUnitTypeBuilder,
  ownerId: 'p1',
  locationProvinceId: 'newWorld|P2',
  tileKey: 'newWorld|P2|0|0',
);

final uOld1 = Unit(
  id: 'u-old-1',
  type: kUnitTypeExplorer,
  ownerId: 'p1',
  locationProvinceId: 'oldWorld|P1',
  tileKey: 'oldWorld|P1|0|0',
);
final uOld2 = Unit(
  id: 'u-old-2',
  type: kUnitTypeBuilder,
  ownerId: 'p1',
  locationProvinceId: 'oldWorld|P1',
  tileKey: 'oldWorld|P1|0|1',
);
final uNew1 = Unit(
  id: 'u-new-1',
  type: kUnitTypeBuilder,
  ownerId: 'p1',
  locationProvinceId: 'newWorld|P2',
  tileKey: 'newWorld|P2|0|0',
);
final uNew2 = Unit(
  id: 'u-new-2',
  type: kUnitTypeExplorer,
  ownerId: 'p2',
  locationProvinceId: 'newWorld|P3',
  tileKey: 'newWorld|P3|0|0',
);

WorldState makeWorld({
  List<Unit> oldUnits = const [],
  List<Unit> newUnits = const [],
}) {
  return TestFixtures.worldStateAtOrdersPhase(
    turnNumber: 0,
    oldWorld: RegionData(units: oldUnits),
    newWorld: RegionData(units: newUnits),
  );
}

