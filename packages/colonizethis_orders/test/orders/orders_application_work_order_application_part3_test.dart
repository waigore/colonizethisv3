import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('build_fort with sufficient materials deducts materials', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final cost = workOrderCostBuildFort(0);
      var stockpile = const Stockpile();
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
                fortLevel: 0,
              ),
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
              target: kWorkTargetBuildFort,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      for (final e in cost.entries) {
        expect(
          next.players.single.stockpile.quantityOf(e.key),
          game.players.single.stockpile.quantityOf(e.key) - e.value,
        );
      }
    });

    test('build_fort to level 2 is skipped without Mine Engineering', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
                fortLevel: 1,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: {},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildFort,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
      expect(next.worldState.oldWorld.units.single.currentWork, isNull);
    });

    test('build_fort to level 3 is skipped without Modern Forts', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
                fortLevel: 2,
              ),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          const Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            techUnlocked: {kTechIdMineEngineering: true},
          ),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetBuildFort,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      expect(next.worldState.oldWorld.provinces.single.fortLevel, 2);
      expect(next.worldState.oldWorld.units.single.currentWork, isNull);
    });

    test('upgrade_town completion increases province townDevelopmentLevel', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
        status: UnitStatus.working,
        currentWork: const CurrentWork(
          workTarget: kWorkTargetUpgradeTown,
          tileKey: tileKey,
          totalTurns: 1,
          remainingTurns: 1,
        ),
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: ow,
                ownerId: 'p1',
                townDevelopmentLevel: 1,
              ),
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
            techUnlocked: const {kTechIdNationalBureaucracy: true},
          ),
        ],
      );
      final next = applyBuildAndWorkOrders(
        game,
        Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
      );
      expect(next.worldState.oldWorld.provinces.single.townDevelopmentLevel, 2);
    });

    test(
      'steal_tech completion clears currentWork after remainingTurns reach zero',
      () {
        const p2Capital = 'oldWorld|P2';
        const capTileKey = 'oldWorld|P2|0|0';
        final spy = Unit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: 'p1',
          locationProvinceId: p2Capital,
          tileKey: capTileKey,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetStealTech,
            tileKey: capTileKey,
            totalTurns: 5,
            remainingTurns: 1,
          ),
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: p2Capital, regionId: ow, ownerId: 'p2'),
              ],
              units: [spy],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                p2Capital: [capTileKey],
              },
            },
          ),
          players: [
            const Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: 'oldWorld|P1',
            ),
            Player(
              id: 'p2',
              displayName: 'P2',
              isHuman: true,
              capitalProvinceId: p2Capital,
              techUnlocked: {'some_tech': true},
            ),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]}),
        );
        final spyAfter = next.worldState.oldWorld.units.single;
        expect(spyAfter.id, 'spy1');
        expect(spyAfter.ownerId, 'p1');
      },
    );

    test(
      'counter_spy processWork runs and may remove enemy Spy in same province',
      () {
        const provId = 'oldWorld|P1';
        const tileKeyP1 = 'oldWorld|P1|0|0';
        final p1Spy = Unit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: 'p1',
          locationProvinceId: provId,
          tileKey: tileKeyP1,
          status: UnitStatus.working,
          currentWork: const CurrentWork(
            workTarget: kWorkTargetCounterSpy,
            tileKey: tileKeyP1,
            totalTurns: 0,
            remainingTurns: 1,
          ),
        );
        final p2Spy = Unit(
          id: 'spy2',
          type: kUnitTypeSpy,
          ownerId: 'p2',
          locationProvinceId: provId,
          tileKey: tileKeyP1,
        );
        final game = Game(
          id: 'g',
          globalGameSeed: 12345,
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [Province(id: provId, regionId: ow, ownerId: 'p1')],
              units: [p1Spy, p2Spy],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provId: [tileKeyP1],
              },
            },
          ),
          players: const [
            Player(id: 'p1', displayName: 'P1', isHuman: true),
            Player(id: 'p2', displayName: 'P2', isHuman: true),
          ],
        );
        final next = applyBuildAndWorkOrders(
          game,
          Orders(
            buildUnitOrdersByPlayerId: {
              'p1': <BuildUnitOrder>[],
              'p2': <BuildUnitOrder>[],
            },
          ),
        );
        final units = next.worldState.oldWorld.units;
        expect(units.any((u) => u.id == 'spy1'), isTrue);
        expect(units.length, lessThanOrEqualTo(2));
      },
    );
  });
}
