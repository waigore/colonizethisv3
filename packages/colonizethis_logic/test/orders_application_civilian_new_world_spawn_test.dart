import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders civilian and New World spawn', () {
    test(
      'civilian spawn uses capitalTile key even when spawnProvinceId is different owned province',
      () {
        const ow = 'oldWorld';
        const capitalProvinceId = 'oldWorld|P1';
        const otherOwnedProvinceId = 'oldWorld|P2';
        const capitalTileKey = 'oldWorld|P1|0|1';
        final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
        var stockpile = const Stockpile();
        for (final e in explorerEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
                Province(id: otherOwnedProvinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                capitalProvinceId: ['oldWorld|P1|0|0', capitalTileKey],
                otherOwnedProvinceId: ['oldWorld|P2|0|0'],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: capitalProvinceId,
              capitalTile: const CapitalTile(
                regionId: ow,
                provinceId: capitalProvinceId,
                x: 0,
                y: 1,
              ),
              stockpile: stockpile,
              workerPool: const WorkerPool(peasants: 1),
              treasury: explorerEcon.buildTreasuryCost + 100,
            ),
          ],
        );
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            'p1': [
              BuildUnitOrder(
                unitType: kUnitTypeExplorer,
                isMilitary:
                    buildUnitCategoryForUnitType(kUnitTypeExplorer) ==
                    BuildUnitCategory.military,
                spawnProvinceId: otherOwnedProvinceId,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.oldWorld.units.length, 1);
        expect(next.worldState.oldWorld.units.single.tileKey, capitalTileKey);
        expect(
          next.worldState.oldWorld.units.single.locationProvinceId,
          capitalProvinceId,
        );
      },
    );

    test(
      'civilian build with empty spawnProvinceId uses capital tile and province',
      () {
        const ow = 'oldWorld';
        const capitalProvinceId = 'oldWorld|P1';
        const capitalTileKey = 'oldWorld|P1|0|1';
        final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
        var stockpile = const Stockpile();
        for (final e in explorerEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                capitalProvinceId: ['oldWorld|P1|0|0', capitalTileKey],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: capitalProvinceId,
              capitalTile: const CapitalTile(
                regionId: ow,
                provinceId: capitalProvinceId,
                x: 0,
                y: 1,
              ),
              stockpile: stockpile,
              treasury: explorerEcon.buildTreasuryCost + 100,
            ),
          ],
        );
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            'p1': [
              BuildUnitOrder(
                unitType: kUnitTypeExplorer,
                isMilitary: false,
                spawnProvinceId: '',
              ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.oldWorld.units.length, 1);
        expect(
          next.worldState.oldWorld.units.single.locationProvinceId,
          capitalProvinceId,
        );
        expect(next.worldState.oldWorld.units.single.tileKey, capitalTileKey);
      },
    );

    test('civilian build with missing capital tile throws explicit error', () {
      const ow = 'oldWorld';
      const capitalProvinceId = 'oldWorld|P1';
      final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
      var stockpile = const Stockpile();
      for (final e in explorerEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: capitalProvinceId, regionId: ow, ownerId: 'p1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              capitalProvinceId: ['oldWorld|P1|0|0'],
            },
          },
        ),
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: capitalProvinceId,
            stockpile: stockpile,
            treasury: explorerEcon.buildTreasuryCost + 100,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: kUnitTypeExplorer,
              isMilitary: false,
              spawnProvinceId: capitalProvinceId,
            ),
          ],
        },
      );

      expect(
        () => applyBuildAndWorkOrders(game, orders),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('No capital tile to spawn civilian unit'),
          ),
        ),
      );
    });

    test('New World spawn adds unit to newWorld', () {
      const nw = 'newWorld';
      const provinceId = 'newWorld|N1';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: nw, ownerId: 'p1')],
            units: [],
          ),
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: provinceId,
            stockpile: Stockpile(),
            workerPool: WorkerPool(peasants: 1),
            treasury: 500,
          ),
        ],
      );
      final orders = Orders(
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'peasant_levies',
              isMilitary:
                  buildUnitCategoryForUnitType('peasant_levies') ==
                  BuildUnitCategory.military,
              spawnProvinceId: provinceId,
            ),
          ],
        },
      );
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final gameWithStock = game.copyWith(
        players: [
          game.players.single.copyWith(
            stockpile: stockpile,
            treasury: econ.buildTreasuryCost + 10,
          ),
        ],
      );
      final next = applyBuildAndWorkOrders(gameWithStock, orders);
      expect(next.worldState.oldWorld.units, isEmpty);
      expect(next.worldState.newWorld.units.length, 1);
      expect(
        next.worldState.newWorld.units.single.locationProvinceId,
        provinceId,
      );
    });
  });
}
