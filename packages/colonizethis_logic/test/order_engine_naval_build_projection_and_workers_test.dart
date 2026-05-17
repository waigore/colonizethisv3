import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    test(
      'projectedEffects returns treasuryDelta when orders affect treasury',
      () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        var stockpile = const Stockpile();
        for (final e in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value + 1);
        }
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
              stockpile: stockpile,
              workerPool: const WorkerPool(peasants: 3),
              treasury: econ.buildTreasuryCost + 100,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addBuildOrder(
          'p1',
          BuildUnitOrder(
            unitType: 'peasant_levies',
            isMilitary:
                buildUnitCategoryForUnitType('peasant_levies') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$ow|P1',
          ),
        );
        final effects = engine.projectedEffects(game, topology, 'p1');
        expect(effects.workerCount, isNotNull);
        expect(effects.treasuryDelta, isNotNull);
      },
    );

    test('rejects naval build when peasants are zero', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final shipEcon = ShipEconomyCatalog.byId['carrack']!;
      var stockpile = const Stockpile();
      for (final e in shipEcon.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
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
            stockpile: stockpile,
            workerPool: const WorkerPool(peasants: 0),
            treasury: shipEcon.buildTreasuryCost + 10,
          ),
        ],
      );
      final engine = OrderEngine();
      final result = engine.addBuildOrderWithContext(
        game,
        topology,
        'p1',
        BuildUnitOrder(
          unitType: 'carrack',
          isMilitary: false,
          spawnProvinceId: '$ow|P1',
        ),
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Insufficient workers');
    });
  });
}
