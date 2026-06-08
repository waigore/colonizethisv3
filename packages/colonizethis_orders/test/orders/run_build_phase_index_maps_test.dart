/// End-to-end build-phase coverage for the O(1) army/fleet index maps shared
/// inside `runBuildPhase` (Refs #2394;
/// SPEC/program/order-suggestions.md § Throughput bounds).
///
/// Verifies that multiple military/naval builds in a single phase converge on
/// a single home army/fleet via the rebased `armiesByIdForWorld` /
/// `fleetsByIdForWorld` snapshots, instead of duplicating or fragmenting state.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'p1';
  const capProvinceId = 'oldWorld|P1';

  group('runBuildPhase O(1) maps end-to-end (Refs #2394)', () {
    test(
      'consecutive military recruits build one home army with all regiments',
      () {
        const k = 3;
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        var stockpile = const Stockpile();
        for (final entry in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(entry.key, entry.value * k + 1);
        }
        final player = Player(
          id: playerId,
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: capProvinceId,
          stockpile: stockpile,
          workerPool: const WorkerPool(peasants: k + 1),
          treasury: econ.buildTreasuryCost * k + 100,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: capProvinceId,
                regionId: 'oldWorld',
                ownerId: playerId,
              ),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g', worldState: world, players: [player]);
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            playerId: [
              for (var i = 0; i < k; i++)
                BuildUnitOrder(
                  unitType: 'peasant_levies',
                  isMilitary: true,
                  spawnProvinceId: capProvinceId,
                ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(game, orders);

        expect(next.worldState.armies.length, 1);
        final army = next.worldState.armies.single;
        expect(army.id, homeArmyIdFor(playerId));
        expect(army.isHomeArmy, isTrue);
        expect(army.regimentUnitIds.length, k);
      },
    );

    test(
      'consecutive ship recruits add ships to a single home fleet (cache reuse)',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
        );
        final shipEcon = ShipEconomyCatalog.byId['fluyte']!;
        const k = 2;
        var stockpile = const Stockpile();
        for (final e in shipEcon.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value * k + 1);
        }
        final player = Player(
          id: playerId,
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: capProvinceId,
          stockpile: stockpile,
          workerPool: const WorkerPool(peasants: k + 1),
          treasury: shipEcon.buildTreasuryCost * k + 100,
          techUnlocked: const {kTechIdSuperiorHullDesign: true},
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: playerId),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        );
        final game = Game(id: 'g', worldState: world, players: [player]);
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            playerId: [
              for (var i = 0; i < k; i++)
                BuildUnitOrder(
                  unitType: 'fluyte',
                  isMilitary: false,
                  spawnProvinceId: capProvinceId,
                ),
            ],
          },
        );

        final next = applyBuildAndWorkOrders(
          game,
          orders,
          topology: topology,
        );

        final ownedFleets = next.worldState.fleets
            .where((f) => f.ownerId == playerId)
            .toList();
        expect(ownedFleets.length, 1);
        expect(ownedFleets.single.shipTypeIds.length, k);
      },
    );
  });
}
