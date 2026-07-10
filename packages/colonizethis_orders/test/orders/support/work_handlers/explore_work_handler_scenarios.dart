// Table-driven explore work handler scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/explore_work_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/simple_work_order_handler.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

void ewhRunSupportsOnlyExplore() {
  expect(exploreWorkOrderHandler.supports(kWorkTargetExplore), isTrue);
  expect(exploreWorkOrderHandler.supports(kWorkTargetPurchaseLand), isFalse);
}

void ewhRunAssignsExploreCurrentWork() {
  const ow = 'oldWorld';
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  final game = TestFixtures.minimalGame(
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
      units: [
        Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      ow: {
        provinceId: [tileKey, '$ow|P1|0|1'],
      },
    },
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final unit = game.worldState.oldWorld.units.single;
  Unit? updated;
  final ok = tryApplyExploreWorkOrder(
    game: game,
    order: const WorkOrder(
      unitId: 'u1',
      target: kWorkTargetExplore,
      targetTileKey: tileKey,
    ),
    unit: unit,
    targetTileKey: tileKey,
    regionForUnit: (_) => ow,
    updateUnit: (id, u) {
      expect(id, 'u1');
      updated = u;
    },
  );
  expect(ok, isTrue);
  final out = updated;
  expect(out, isNotNull);
  expect(out!.status, UnitStatus.working);
  expect(out.currentWork?.workTarget, kWorkTargetExplore);
  expect(out.currentWork?.tileKey, tileKey);
}

void ewhRunReturnsFalseNoTileKeys() {
  const ow = 'oldWorld';
  const provinceId = '$ow|P1';
  const tileKey = '$ow|P1|0|0';
  final game = TestFixtures.minimalGame(
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
      units: [
        Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        ),
      ],
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final unit = game.worldState.oldWorld.units.single;
  var updateCalls = 0;
  final ok = tryApplyExploreWorkOrder(
    game: game,
    order: const WorkOrder(
      unitId: 'u1',
      target: kWorkTargetExplore,
      targetTileKey: tileKey,
    ),
    unit: unit,
    targetTileKey: tileKey,
    regionForUnit: (_) => ow,
    updateUnit: (_, __) => updateCalls++,
  );
  expect(ok, isFalse);
  expect(updateCalls, 0);
}

/// Canonical scenarios for explore_work_handler family tests.
List<RunnableScenario> exploreWorkHandlerScenarios() => const [
  rs('supports only explore target', ewhRunSupportsOnlyExplore),
  rs('assigns explore currentWork when province has discoverable tiles', ewhRunAssignsExploreCurrentWork),
  rs('returns false when province has no tile keys in world state', ewhRunReturnsFalseNoTileKeys),
];
