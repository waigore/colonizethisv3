import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateBuild (civilian)', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      test('rejects unknown unit type', () {
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
              stockpile: const Stockpile(),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 5000,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'UnknownTypeXyz',
            isMilitary:
                buildUnitCategoryForUnitType('UnknownTypeXyz') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, 'Insufficient resources');
      });

      test('rejects Builder when treasury too low', () {
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 999,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'Builder',
            isMilitary:
                buildUnitCategoryForUnitType('Builder') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, 'Insufficient treasury');
      });

      test('rejects Builder when paper insufficient', () {
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
              stockpile: const Stockpile(),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 2000,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'Builder',
            isMilitary:
                buildUnitCategoryForUnitType('Builder') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, 'Insufficient materials');
      });

      test('rejects Merchant when merchant_companies not unlocked', () {
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 3000,
              techUnlocked: {},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'Merchant',
            isMilitary:
                buildUnitCategoryForUnitType('Merchant') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, 'Required technology not unlocked');
      });

      test('accepts Builder when treasury and paper sufficient', () {
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
            unitType: 'Builder',
            isMilitary:
                buildUnitCategoryForUnitType('Builder') ==
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
              stockpile: Stockpile().applyDelta(CommodityCatalog.paper.id, 5),
              workerPool: const WorkerPool(peasants: 0),
              treasury: 3000,
              techUnlocked: {'merchant_companies': true},
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'Merchant',
            isMilitary:
                buildUnitCategoryForUnitType('Merchant') ==
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
              unitType: 'Builder',
              isMilitary:
                  buildUnitCategoryForUnitType('Builder') ==
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
              unitType: 'Builder',
              isMilitary:
                  buildUnitCategoryForUnitType('Builder') ==
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
