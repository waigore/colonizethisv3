// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

WorldState provinceLookupTestWorld() => TestFixtures.worldStateAtOrdersPhase(
  oldWorld: const RegionData(
    provinces: [
      Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        ownerId: 'gp1',
        fortLevel: 2,
      ),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
    ],
  ),
  newWorld: const RegionData(
    provinces: [
      Province(id: 'newWorld|n1', regionId: 'newWorld', ownerId: 'gp2'),
    ],
  ),
  tileKeysByRegionAndProvince: const {
    'oldWorld': {
      'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
    },
  },
);

const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);

final pOld = Province(
  id: 'oldWorld|P1',
  regionId: kRegionOldWorld,
  ownerId: 'gp1',
);
final pNew = Province(
  id: 'newWorld|P2',
  regionId: kRegionNewWorld,
  ownerId: 'gp2',
);

final pOld1 = Province(
  id: 'oldWorld|P1',
  regionId: kRegionOldWorld,
  ownerId: 'gp1',
);
final pOld2Owned = Province(
  id: 'oldWorld|P2',
  regionId: kRegionOldWorld,
  ownerId: 'gp2',
);
final pOld2Bare = Province(id: 'oldWorld|P2', regionId: kRegionOldWorld);
final pNew1Gp1 = Province(
  id: 'newWorld|P3',
  regionId: kRegionNewWorld,
  ownerId: 'gp1',
);
final pNew1Gp2 = Province(
  id: 'newWorld|P3',
  regionId: kRegionNewWorld,
  ownerId: 'gp2',
);
final pNew2 = Province(
  id: 'newWorld|P4',
  regionId: kRegionNewWorld,
  ownerId: 'gp2',
);

WorldState makeWorld({
  List<Province> oldProvinces = const [],
  List<Province> newProvinces = const [],
}) {
  return TestFixtures.worldStateAtOrdersPhase(
    turnNumber: 0,
    oldWorld: RegionData(provinces: oldProvinces),
    newWorld: RegionData(provinces: newProvinces),
  );
}

