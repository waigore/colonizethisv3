import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Regression coverage for GitHub #2070: explore must not be cancelled in
/// `_processWorkUnits` solely because the target province is not player-owned.
void main() {
  test('explore retains currentWork after Build/Work tick in foreign-owned '
      'partially-revealed province', () {
    const ow = 'oldWorld';
    const p1 = '$ow|P1';
    const p2 = '$ow|P2';
    const tP1 = '$ow|P1|0|0';
    const tP2a = '$ow|P2|0|0';
    const tP2b = '$ow|P2|1|0';

    final explorer = Unit(
      id: 'u1',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: p1,
      tileKey: tP1,
    );
    final game = TestFixtures.minimalGame(
      turnNumber: 0,
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
      oldWorld: RegionData(
        provinces: const [
          Province(id: p1, regionId: ow, ownerId: 'p1'),
          Province(id: p2, regionId: ow, ownerId: 'p2'),
        ],
        units: [explorer],
      ),
      playerVisibilityByTile: const {
        'p1': {tP1: 'fullyVisible', tP2a: 'fogged', tP2b: 'unknown'},
      },
      tileKeysByRegionAndProvince: const {
        ow: {
          p1: [tP1],
          p2: [tP2a, tP2b],
        },
      },
    );
    final orders = Orders(
      workOrdersByPlayerId: {
        'p1': [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetExplore,
            targetTileKey: tP2a,
          ),
        ],
      },
    );

    final next = applyBuildAndWorkOrders(game, orders);
    final u = next.worldState.oldWorld.units.single;
    expect(u.currentWork, isNotNull);
    expect(u.currentWork!.workTarget, kWorkTargetExplore);
    expect(u.currentWork!.remainingTurns, greaterThanOrEqualTo(1));
  });
}
