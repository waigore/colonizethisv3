import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_build_civilian_topology_test_support.dart';

void main() {
  group('OrderEngine', () {
    group('validateBuild (civilian)', () {
      const ow = 'oldWorld';
      final topology = civilianBuildSingleProvinceTopology();

      test('accepts Merchant when tech and resources ok', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
              units: [],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: '$ow|P1',
              capitalTile: const CapitalTile(
                regionId: ow,
                provinceId: 'P1',
                x: 0,
                y: 0,
              ),
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 3000,
              techUnlocked: {kTechIdMerchantCompanies: true},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: kUnitTypeMerchant,
            isMilitary:
                buildUnitCategoryForUnitType(kUnitTypeMerchant) ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.accepted);
      });

      test(
        'accepts build when spawnProvinceId is empty (falls back to capital)',
        () {
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                ],
                units: [],
              ),
              newWorld: const RegionData(),
            ),
            players: [
              Player(
                id: 'p1',
                displayName: 'P1',
                isHuman: true,
                capitalProvinceId: '$ow|P1',
                capitalTile: const CapitalTile(
                  regionId: ow,
                  provinceId: 'P1',
                  x: 0,
                  y: 0,
                ),
                stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
                workerPool: const WorkerPool(peasants: 0),
                treasury: 2000,
              ),
            ],
          );
          final engine = OrderEngine();
          engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: '',
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.accepted);
        },
      );

      test(
        'accepts build when spawnProvinceId is foreign (falls back to capital)',
        () {
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                  Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
                ],
                units: [],
              ),
              newWorld: const RegionData(),
            ),
            players: [
              Player(
                id: 'p1',
                displayName: 'P1',
                isHuman: true,
                capitalProvinceId: '$ow|P1',
                capitalTile: const CapitalTile(
                  regionId: ow,
                  provinceId: 'P1',
                  x: 0,
                  y: 0,
                ),
                stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
                workerPool: const WorkerPool(peasants: 0),
                treasury: 2000,
              ),
            ],
          );
          final engine = OrderEngine();
          engine.addBuildOrder(
            'p1',
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$ow|P2',
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.accepted);
        },
      );
    });
  });
}
