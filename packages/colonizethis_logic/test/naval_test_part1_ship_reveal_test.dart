import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/world/naval_resolution.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Naval ship reveal (movement)', () {
    test(
      'ship reveal reveals only coastal tiles and keeps inland tiles unchanged',
      () {
        const nw = 'newWorld';
        const provinceP1 = '$nw|p1';
        const provinceP2 = '$nw|p2';
        const p1CoastalTile = '$provinceP1|0|0';
        const p1InlandTile = '$provinceP1|0|1';
        const p2CoastalTile = '$provinceP2|2|0';
        const sea2WaterA = '$nw|sea2|1|0';
        const sea2WaterB = '$nw|sea2|3|0';

        final revealTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'sea2'),
            TopologyEdge(id1: 'p2', id2: 'sea2'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 0,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'gp1',
                seaZoneId: 'sea1',
                regionId: nw,
                shipTypeIds: ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              nw: {
                provinceP1: [p1CoastalTile, p1InlandTile],
                provinceP2: [p2CoastalTile],
                '$nw|sea2': [sea2WaterA, sea2WaterB],
              },
            },
            playerVisibilityByTile: const {'gp1': {}},
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final orders = {
          'gp1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        };

        final next = applyNavalMovesAndShipReveal(game, revealTopology, orders);
        final visibility = next.worldState.playerVisibilityByTile['gp1'];

        expect(visibility?[p1CoastalTile], VisibilityLevel.fullyVisible.name);
        expect(visibility?[p2CoastalTile], VisibilityLevel.fullyVisible.name);
        expect(visibility?[p1InlandTile], isNull);
        expect(visibility?[sea2WaterA], VisibilityLevel.fullyVisible.name);
        expect(visibility?[sea2WaterB], VisibilityLevel.fullyVisible.name);
      },
    );

    test('ship reveal stays region-scoped when ids overlap across regions', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      const nwProvince = '$nw|p1';
      const owProvince = '$ow|p1';
      const nwCoastalTile = '$nwProvince|0|0';
      const owTile = '$owProvince|0|0';
      const nwSea2Tile = '$nw|sea2|1|0';

      final revealTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: nw, type: TopologyNodeType.province),
          TopologyNode(
            id: 'sea1',
            regionId: nw,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: nw,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(
            id: 'sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea2'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );

      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f2',
              ownerId: 'gp1',
              seaZoneId: 'sea1',
              regionId: nw,
              shipTypeIds: ['carrack'],
            ),
          ],
          tileKeysByRegionAndProvince: const {
            ow: {
              owProvince: [owTile],
            },
            nw: {
              nwProvince: [nwCoastalTile],
              '$nw|sea2': [nwSea2Tile],
            },
          },
          playerVisibilityByTile: const {'gp1': {}},
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );

      final orders = {
        'gp1': [
          const NavalMoveOrder(fleetId: 'f2', destinationSeaZoneId: 'sea2'),
        ],
      };

      final next = applyNavalMovesAndShipReveal(game, revealTopology, orders);
      final visibility = next.worldState.playerVisibilityByTile['gp1'];
      expect(visibility?[nwCoastalTile], VisibilityLevel.fullyVisible.name);
      expect(visibility?[nwSea2Tile], VisibilityLevel.fullyVisible.name);
      expect(visibility?[owTile], isNull);
    });

    test(
      'combined-topology ship reveal uses canonical sea bucket and coastal ring only',
      () {
        const nw = 'newWorld';
        const fullProv = '$nw|provA';
        const localSeaDest = 'seaDest';
        const localSeaOrigin = 'seaOrigin';
        const prefixedDest = '$nw|$localSeaDest';
        const prefixedOrigin = '$nw|$localSeaOrigin';
        const coastalLand = '$nw|provA|1|0';
        const inlandLand = '$nw|provA|0|0';
        const seaDestWater = '$nw|$localSeaDest|2|0';
        const seaDestWaterB = '$nw|$localSeaDest|2|1';

        final combinedTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: fullProv,
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: prefixedDest,
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: prefixedOrigin,
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$nw|seaFar',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: fullProv, id2: prefixedDest),
            TopologyEdge(id1: prefixedOrigin, id2: prefixedDest),
          ],
        );

        final visStart = <String, String>{
          for (final k in [
            coastalLand,
            inlandLand,
            seaDestWater,
            seaDestWaterB,
            '$nw|$localSeaOrigin|0|2',
          ])
            k: VisibilityLevel.unknown.name,
        };

        final game = Game(
          id: 'gCombined',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 0,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fNw',
                ownerId: 'gp1',
                seaZoneId: prefixedOrigin,
                regionId: nw,
                shipTypeIds: ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: {
              nw: {
                fullProv: [
                  coastalLand,
                  inlandLand,
                  '$nw|provA|0|1',
                  '$nw|provA|1|1',
                ],
                prefixedDest: [seaDestWater, seaDestWaterB],
                prefixedOrigin: ['$nw|$localSeaOrigin|0|2'],
              },
            },
            playerVisibilityByTile: {'gp1': visStart},
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final ordersOk = {
          'gp1': [
            NavalMoveOrder(fleetId: 'fNw', destinationSeaZoneId: prefixedDest),
          ],
        };
        final afterOk = applyNavalMovesAndShipReveal(
          game,
          combinedTopology,
          ordersOk,
        );
        final visOk = afterOk.worldState.playerVisibilityByTile['gp1']!;
        expect(visOk[coastalLand], VisibilityLevel.fullyVisible.name);
        expect(visOk[inlandLand], VisibilityLevel.unknown.name);
        expect(visOk[seaDestWater], VisibilityLevel.fullyVisible.name);
        expect(visOk[seaDestWaterB], VisibilityLevel.fullyVisible.name);

        final ordersBad = {
          'gp1': [
            NavalMoveOrder(fleetId: 'fNw', destinationSeaZoneId: '$nw|seaFar'),
          ],
        };
        final afterBad = applyNavalMovesAndShipReveal(
          game,
          combinedTopology,
          ordersBad,
        );
        final visBad = afterBad.worldState.playerVisibilityByTile['gp1']!;
        expect(visBad[coastalLand], VisibilityLevel.unknown.name);
        expect(visBad[seaDestWater], VisibilityLevel.unknown.name);
      },
    );
  });
}
