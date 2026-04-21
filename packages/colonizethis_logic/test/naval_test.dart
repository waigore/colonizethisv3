import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_logic/src/world/naval_resolution.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Naval', () {
    late MapTopology topology;

    setUp(() {
      topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'sea1'),
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );
    });

    group('indexTopologyNodesByRegion', () {
      test('groups nodes by regionId and id', () {
        final idx = indexTopologyNodesByRegion(topology);
        expect(idx.keys, contains('oldWorld'));
        expect(
          idx['oldWorld']!.keys,
          containsAll(['p1', 'p2', 'sea1', 'sea2']),
        );
        expect(idx['oldWorld']!['p1']!.type, TopologyNodeType.province);
      });
    });

    group('isAdjacentSeaZone', () {
      test('returns true when sea zones are connected by edge', () {
        expect(isAdjacentSeaZone(topology, 'sea1', 'sea2'), isTrue);
        expect(isAdjacentSeaZone(topology, 'sea2', 'sea1'), isTrue);
      });

      test('returns true when province is adjacent to sea zone', () {
        expect(isAdjacentSeaZone(topology, 'p1', 'sea1'), isTrue);
        expect(isAdjacentSeaZone(topology, 'sea1', 'p1'), isTrue);
      });

      test('returns false for same zone', () {
        expect(isAdjacentSeaZone(topology, 'sea1', 'sea1'), isFalse);
      });

      test('returns false when no edge between zones', () {
        expect(isAdjacentSeaZone(topology, 'p1', 'sea2'), isFalse);
        expect(isAdjacentSeaZone(topology, 'p2', 'sea2'), isFalse);
      });
    });

    group('isAdjacentSeaSeaZone', () {
      test('true only for S–S edges between sea-zone nodes', () {
        expect(isAdjacentSeaSeaZone(topology, 'sea1', 'sea2'), isTrue);
        expect(isAdjacentSeaSeaZone(topology, 'sea1', 'p1'), isFalse);
        expect(isAdjacentSeaSeaZone(topology, 'p1', 'sea1'), isFalse);
      });
    });

    group('navalMoveTopologyPicksForFleet', () {
      test('at sea: sea list is S–S only; dock list from S–P', () {
        final fleet = Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          seaZoneId: 'sea1',
          shipTypeIds: const ['carrack'],
        );
        final picks = navalMoveTopologyPicksForFleet(
          topology: topology,
          fleet: fleet,
        );
        expect(picks.adjacentSeaZoneIds, ['sea2']);
        expect(picks.adjacentProvinceIdsForDock.toSet(), {'p1', 'p2'});
      });

      test('in port: undock list is P–S only (all seas touching port)', () {
        final top = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'sea2'),
          ],
        );
        final fleet = Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          inPortAtProvinceId: 'p1',
          shipTypeIds: const ['carrack'],
        );
        final picks = navalMoveTopologyPicksForFleet(
          topology: top,
          fleet: fleet,
        );
        expect(picks.adjacentSeaZoneIds.toSet(), {'sea1', 'sea2'});
        expect(picks.adjacentProvinceIdsForDock, isEmpty);
      });
    });

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
                'sea2': [sea2WaterA, sea2WaterB],
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
              'sea2': [nwSea2Tile],
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
      'combined-topology ship reveal uses local sea bucket and coastal ring only',
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
                localSeaDest: [seaDestWater, seaDestWaterB],
                localSeaOrigin: ['$nw|$localSeaOrigin|0|2'],
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

    test(
      'ship reveal finds province tiles when tile map keys province by local id only',
      () {
        const nw = 'newWorld';
        const fullProv = '$nw|provA';
        const localProvBucket = 'provA';
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
          id: 'gLocalProvBucket',
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
                // Land bucket keyed by **local** id only (some maps/fixtures).
                localProvBucket: [coastalLand, inlandLand, '$nw|provA|0|1'],
                localSeaDest: [seaDestWater, seaDestWaterB],
                localSeaOrigin: ['$nw|$localSeaOrigin|0|2'],
              },
            },
            playerVisibilityByTile: {'gp1': visStart},
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final after = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            NavalMoveOrder(fleetId: 'fNw', destinationSeaZoneId: prefixedDest),
          ],
        });
        final vis = after.worldState.playerVisibilityByTile['gp1']!;
        expect(vis[coastalLand], VisibilityLevel.fullyVisible.name);
        expect(vis[inlandLand], VisibilityLevel.unknown.name);
        expect(vis[seaDestWater], VisibilityLevel.fullyVisible.name);
      },
    );

    test(
      'S->S entry remains fully visible after end-of-turn and in PlayerView',
      () {
        const ow = 'oldWorld';
        const startSea = '$ow|seaStart';
        const destSea = '$ow|seaDest';
        const destSeaTileA = '$ow|seaDest|2|0';
        const destSeaTileB = '$ow|seaDest|2|1';
        const destProv = '$ow|pDest';
        const destCoast = '$destProv|1|0';

        final combinedTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|pDest',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$ow|seaStart',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$ow|seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: '$ow|pDest', id2: '$ow|seaDest'),
            TopologyEdge(id1: '$ow|seaStart', id2: '$ow|seaDest'),
          ],
        );
        final localRegionTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pDest',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'seaStart',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'pDest', id2: 'seaDest'),
            TopologyEdge(id1: 'seaStart', id2: 'seaDest'),
          ],
        );

        final game = Game(
          id: 'gS2S',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 3,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'gp1',
                seaZoneId: startSea,
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              ow: {
                destProv: [destCoast],
                'seaDest': [destSeaTileA, destSeaTileB],
              },
            },
            playerVisibilityByTile: {
              'gp1': {
                destSeaTileA: VisibilityLevel.unknown.name,
                destSeaTileB: VisibilityLevel.unknown.name,
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final moved = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: destSea),
          ],
        });
        final ended = runEndOfTurnPhase(
          moved.copyWith(
            worldState: moved.worldState.copyWith(
              turnState: const TurnState(
                phase: TurnPhase.endOfTurn,
                turnNumber: 3,
              ),
            ),
          ),
          topology: localRegionTopology,
          topologyByRegion: {ow: localRegionTopology},
        );
        final view = buildPlayerView(ended, localRegionTopology, 'gp1');

        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          view.visibilityForTile(destSeaTileA),
          VisibilityLevel.fullyVisible,
        );
        expect(
          view.visibilityForTile(destSeaTileB),
          VisibilityLevel.fullyVisible,
        );
      },
    );

    test(
      'P->S undock entry remains fully visible after end-of-turn and in PlayerView',
      () {
        const ow = 'oldWorld';
        const portProv = '$ow|pPort';
        const destSeaPrefixed = '$ow|seaDest';
        const destSeaTileA = '$ow|seaDest|4|0';
        const destSeaTileB = '$ow|seaDest|4|1';
        const coastTile = '$portProv|3|0';

        final combinedTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|pPort',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$ow|seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: '$ow|pPort', id2: '$ow|seaDest')],
        );
        final localRegionTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pPort',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'pPort', id2: 'seaDest')],
        );

        final game = Game(
          id: 'gP2S',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 7,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f2',
                ownerId: 'gp1',
                inPortAtProvinceId: portProv,
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              ow: {
                portProv: [coastTile],
                'seaDest': [destSeaTileA, destSeaTileB],
              },
            },
            playerVisibilityByTile: {
              'gp1': {
                destSeaTileA: VisibilityLevel.unknown.name,
                destSeaTileB: VisibilityLevel.unknown.name,
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final moved = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            const NavalMoveOrder(
              fleetId: 'f2',
              destinationSeaZoneId: destSeaPrefixed,
            ),
          ],
        });
        final ended = runEndOfTurnPhase(
          moved.copyWith(
            worldState: moved.worldState.copyWith(
              turnState: const TurnState(
                phase: TurnPhase.endOfTurn,
                turnNumber: 7,
              ),
            ),
          ),
          topology: localRegionTopology,
          topologyByRegion: {ow: localRegionTopology},
        );
        final view = buildPlayerView(ended, localRegionTopology, 'gp1');

        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          view.visibilityForTile(destSeaTileA),
          VisibilityLevel.fullyVisible,
        );
        expect(
          view.visibilityForTile(destSeaTileB),
          VisibilityLevel.fullyVisible,
        );
      },
    );

    group('firstAdjacentSeaZone', () {
      test('returns id2 when id1 matches seaZoneId', () {
        final seaOnly = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        expect(firstAdjacentSeaZone(seaOnly, 'sea1'), 'sea2');
      });

      test('returns id1 when id2 matches seaZoneId', () {
        final seaOnly = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'sea2',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
        );
        expect(firstAdjacentSeaZone(seaOnly, 'sea2'), 'sea1');
      });

      test('returns null when sea zone has no edges', () {
        final noEdgeTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea0',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        expect(firstAdjacentSeaZone(noEdgeTopology, 'sea0'), isNull);
      });
    });

    group('seaZoneIdForProvince', () {
      test('returns adjacent sea zone for coastal province', () {
        expect(seaZoneIdForProvince(topology, 'p1'), 'sea1');
        expect(seaZoneIdForProvince(topology, 'p2'), 'sea1');
      });

      test(
        'when regionId is provided, lookup is region-scoped (world-model-identity)',
        () {
          final multiRegion = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'p1',
                regionId: 'oldWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea1',
                regionId: 'oldWorld',
                type: TopologyNodeType.seaZone,
              ),
              TopologyNode(
                id: 'p1',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'sea2',
                regionId: 'newWorld',
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: const [
              TopologyEdge(id1: 'p1', id2: 'sea1'),
              TopologyEdge(id1: 'p1', id2: 'sea2'),
            ],
          );
          expect(
            seaZoneIdForProvince(multiRegion, 'p1', regionId: 'oldWorld'),
            'sea1',
          );
          expect(
            seaZoneIdForProvince(multiRegion, 'p1', regionId: 'newWorld'),
            'sea2',
          );
          expect(seaZoneIdForProvince(multiRegion, 'p1'), isNotNull);
        },
      );

      test('returns null for province with no sea edge', () {
        final inland = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
        );
        expect(seaZoneIdForProvince(inland, 'p1'), isNull);
      });

      test(
        'supports combined topology: prefixed node ids and edges (app/turn resolver graph)',
        () {
          const ow = 'oldWorld';
          final combined = MapTopology(
            nodes: [
              TopologyNode(
                id: '$ow|cap',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: '$ow|sea1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: '$ow|cap', id2: '$ow|sea1')],
          );
          expect(
            seaZoneIdForProvince(combined, 'cap', regionId: ow),
            '$ow|sea1',
          );
          expect(
            seaZoneIdForProvince(combined, '$ow|cap', regionId: ow),
            '$ow|sea1',
          );
        },
      );
    });

    group('provinceIdsAdjacentToSeaZone', () {
      test('returns coastal provinces for sea zone', () {
        final ids = provinceIdsAdjacentToSeaZone(topology, 'sea1');
        expect(ids, containsAll(['p1', 'p2']));
        expect(ids.length, 2);
      });

      test('returns empty for sea zone with no province adjacent', () {
        final coastal = provinceIdsAdjacentToSeaZone(topology, 'sea2');
        expect(coastal, isEmpty);
      });

      test(
        'local sea id matches prefixed sea node on P–S edges (combined topology)',
        () {
          const nw = 'newWorld';
          const fullProv = '$nw|provA';
          const localSea = 'seaDest';
          const prefixedSea = '$nw|$localSea';
          final combined = MapTopology(
            nodes: [
              TopologyNode(
                id: fullProv,
                regionId: nw,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: prefixedSea,
                regionId: nw,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: fullProv, id2: prefixedSea)],
          );
          expect(
            provinceIdsAdjacentToSeaZone(combined, localSea, regionId: nw),
            equals({fullProv}),
          );
          expect(regionIdForSeaZone(combined, localSea), nw);
        },
      );
    });

    group('seaZoneIdsAdjacentToProvince', () {
      test(
        'full province id matches prefixed province node on P–S edge '
        '(combined topology)',
        () {
          const ow = 'oldWorld';
          final combined = MapTopology(
            nodes: [
              TopologyNode(
                id: '$ow|p1',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: '$ow|s1',
                regionId: ow,
                type: TopologyNodeType.seaZone,
              ),
            ],
            edges: [TopologyEdge(id1: '$ow|p1', id2: '$ow|s1')],
          );
          expect(
            seaZoneIdsAdjacentToProvince(combined, '$ow|p1', regionId: ow),
            equals(<String>{'$ow|s1'}),
          );
        },
      );
    });

    group('regionIdForSeaZone', () {
      test('returns regionId from topology node', () {
        expect(regionIdForSeaZone(topology, 'sea1'), 'oldWorld');
        expect(regionIdForSeaZone(topology, 'sea2'), 'oldWorld');
      });

      test('resolves local id when exactly one prefixed sea node matches', () {
        const nw = 'newWorld';
        final combined = MapTopology(
          nodes: [
            TopologyNode(
              id: '$nw|seaA',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$nw|seaB',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [],
        );
        expect(regionIdForSeaZone(combined, 'seaA'), nw);
        expect(regionIdForSeaZone(combined, 'seaX'), isNull);
      });

      test('returns null when sea zone not found (no default region)', () {
        expect(regionIdForSeaZone(topology, 'nonexistent'), isNull);
      });
    });

    group('isWarpZoneSeaZone', () {
      test('returns true when sea zone has cross-region S-S edge', () {
        const ow = 'oldWorld';
        const nw = 'newWorld';
        final combined = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|sea_a',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$ow|sea_b',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$nw|sea_c',
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: '$ow|sea_a', id2: '$ow|sea_b'),
            TopologyEdge(id1: '$ow|sea_b', id2: '$nw|sea_c'),
          ],
        );

        expect(isWarpZoneSeaZone(combined, '$ow|sea_b'), isTrue);
        expect(isWarpZoneSeaZone(combined, '$nw|sea_c'), isTrue);
      });

      test('returns false for same-region edges only', () {
        expect(isWarpZoneSeaZone(topology, 'sea1'), isFalse);
        expect(isWarpZoneSeaZone(topology, 'sea2'), isFalse);
      });
    });

    group('provinceIdsAdjacentToSeaZone region-scoped', () {
      test('when regionId passed, returns only provinces in that region', () {
        final multiRegion = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'oldWorld',
          ),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'newWorld',
          ),
          equals({'p1'}),
        );
        expect(
          provinceIdsAdjacentToSeaZone(
            multiRegion,
            'sea1',
            regionId: 'otherRegion',
          ),
          isEmpty,
        );
      });

      test('when sea zone not in topology, returns empty', () {
        expect(provinceIdsAdjacentToSeaZone(topology, 'nonexistent'), isEmpty);
      });
    });

    group('fleetsInPortAtProvince', () {
      test('returns fleets in port at province (inPortAtProvinceId)', () {
        final worldState = WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|p1|sea1': 'oldWorld|p1|0|0'},
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'gp1',
              seaZoneId: null,
              inPortAtProvinceId: 'oldWorld|p1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack', 'carrack'],
            ),
            Fleet(
              id: 'f2',
              ownerId: 'gp2',
              seaZoneId: 'sea2',
              inPortAtProvinceId: null,
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
        );
        final inPort = fleetsInPortAtProvince(worldState, 'oldWorld|p1');
        expect(inPort.length, 1);
        expect(inPort.first.id, 'f1');
        expect(inPort.first.inPortAtProvinceId, 'oldWorld|p1');
      });

      test('returns empty when no fleet in port at province', () {
        final worldState = WorldState(
          turnState: TurnState(phase: TurnPhase.movement, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: {'oldWorld|p2|sea1': 'oldWorld|p2|0|0'},
          fleets: const [],
        );
        expect(fleetsInPortAtProvince(worldState, 'oldWorld|p1'), isEmpty);
      });
    });
  });
}
