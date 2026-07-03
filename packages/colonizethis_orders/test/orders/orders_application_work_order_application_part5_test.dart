import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application (part 5)', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('counter_spy work order sets currentWork for Spy unit', () {
      const targetProvinceId = 'oldWorld|P1';
      const targetTileKey = 'oldWorld|P1|0|0';
      final spy = Unit(
        id: 'spy1',
        type: kUnitTypeSpy,
        ownerId: 'p1',
        locationProvinceId: targetProvinceId,
        tileKey: targetTileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
              ),
            ],
            units: [spy],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
            },
          },
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            const WorkOrder(
              unitId: 'spy1',
              target: kWorkTargetCounterSpy,
              targetTileKey: targetTileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final spyAfter = next.worldState.oldWorld.units.single;
      expect(spyAfter.currentWork, isNotNull);
      expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
    });

    test('explore work order sets currentWork when province has tiles', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              provinceId: [tileKey, 'oldWorld|P1|1|0'],
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetExplore,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.currentWork, isNotNull);
      expect(u.currentWork!.workTarget, kWorkTargetExplore);
      expect(u.currentWork!.totalTurns, greaterThanOrEqualTo(1));
      // One turn processed in same phase after applying.
      expect(u.currentWork!.remainingTurns, u.currentWork!.totalTurns - 1);
    });

    test(
      'explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion)',
      () {
        // Region has two provinces with different tile counts; explorer in the
        // smaller one should get totalTurns = ceil(3 * tilesInP / maxTilesInRegion).
        const ow = 'oldWorld';
        const provinceSmall = '$ow|P1';
        const provinceLarge = '$ow|P2';
        const tileSmall1 = '$ow|P1|0|0';
        const tileSmall2 = '$ow|P1|1|0';
        const tileLarge1 = '$ow|P2|0|0';
        const tileLarge2 = '$ow|P2|1|0';
        const tileLarge3 = '$ow|P2|2|0';
        const tileLarge4 = '$ow|P2|3|0';

        final unit = Unit(
          id: 'u1',
          type: kUnitTypeExplorer,
          ownerId: 'p1',
          locationProvinceId: provinceSmall,
          tileKey: tileSmall1,
        );

        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceSmall, regionId: ow, ownerId: 'p1'),
                Province(id: provinceLarge, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceSmall: [tileSmall1, tileSmall2], // tilesInP = 2
                provinceLarge: [
                  tileLarge1,
                  tileLarge2,
                  tileLarge3,
                  tileLarge4,
                ], // maxTilesInRegion = 4
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );

        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'u1',
                target: kWorkTargetExplore,
                targetTileKey: tileSmall1,
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;

        // tilesInP = 2, maxTilesInRegion = 4 → ceil(3 * 2 / 4) = ceil(1.5) = 2.
        expect(u.currentWork, isNotNull);
        expect(u.currentWork!.workTarget, kWorkTargetExplore);
        expect(u.currentWork!.totalTurns, 2);
        // One turn processed in same phase after applying.
        expect(u.currentWork!.remainingTurns, 1);
      },
    );

    test('Engineer build_road work order sets currentWork', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final cost = workOrderCostBuildRoad;
      var stockpile = const Stockpile();
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            stockpile: stockpile,
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildRoad,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
      expect(u.currentWork, isNull);
      expect(u.status, UnitStatus.idle);
      expect(next.worldState.tileState.roadLevel(tileKey), 1);
    });

    test(
      'build_port work order sets currentWork when materials sufficient',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderMaterialCost(kWorkTargetBuildPort);
        expect(cost, isNotNull);
        var stockpile = const Stockpile();
        for (final e in cost!.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: stockpile,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildPort,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        // build_port totalTurns=1, so work completes in same phase; unit idle.
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
      },
    );
  });
}
