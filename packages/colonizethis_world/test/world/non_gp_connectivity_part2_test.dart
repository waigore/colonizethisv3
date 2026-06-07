import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

/// Tests for [resolveNonGreatPowerConnectivity] (Refs #2991 C3 — part 2).
void main() {
  group('resolveNonGreatPowerConnectivity', () {
    test('minor with null capitalTile gets empty ConnectivityResult', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 2, height: 1, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [],
        minorNations: [
          // Capital intentionally unset (e.g. before terminal fall).
          const MinorNation(id: 'minor_lux'),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );

      expect(result['minor_lux'], isNotNull);
      expect(result['minor_lux']!.connected, isEmpty);
      expect(result['minor_lux']!.pathTransportCap, isEmpty);
      expect(result['minor_lux']!.connectedByRoadRule, isEmpty);
    });

    test('tribe with null capitalTile gets empty ConnectivityResult', () {
      const nw = 'newWorld';
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(width: 1, height: 1, grid: grid);
      final topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
            ],
          ),
        ),
        players: [],
        tribes: [const Tribe(id: 'tribe_iro')],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'newWorld': tileMap},
        topology: topology,
      );

      expect(result['tribe_iro'], isNotNull);
      expect(result['tribe_iro']!.connected, isEmpty);
    });

    test(
      'war does not block market access: enemy fleet on Blockade against minor port leaves minor connectivity unchanged',
      () {
        const ow = 'oldWorld';
        // Two-province OW: p1 inland (capital), p2 seaboard (port).
        final grid = [
          ['p1', 'p2'],
          ['p1', 'p2'],
        ];
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          // p2 is sea-bound to sea1.
          edges: [TopologyEdge(id1: 'p2', id2: 'sea1')],
        );
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        // Road from capital tile through both provinces' tiles to the port.
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|1|1', 1);
        // Port tile in p2.
        final ports = {'$ow|p2|sea1': 'oldWorld|p2|1|0'};
        // Enemy GP fleet at sea on Blockade against minor's port province p2.
        final blockadingFleet = Fleet(
          id: 'fleet_attacker',
          ownerId: 'gp_enemy',
          seaZoneId: 'sea1',
          inPortAtProvinceId: null,
          regionId: ow,
          mission: FleetMission.blockade,
          targetProvinceId: '$ow|p2',
        );

        final gameNoFleet = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final gameWithBlockade = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            portsByProvinceSeaboard: ports,
            fleets: [blockadingFleet],
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final tileMapByRegion = {'oldWorld': tileMap};
        final noFleetResult = resolveNonGreatPowerConnectivity(
          game: gameNoFleet,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final blockadedResult = resolveNonGreatPowerConnectivity(
          game: gameWithBlockade,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );

        // Identical connected sets: blockade does not affect non-GP connectivity.
        expect(
          blockadedResult['minor_lux']!.connected,
          equals(noFleetResult['minor_lux']!.connected),
        );
        // Sanity: the port tile is connected in both cases.
        expect(
          blockadedResult['minor_lux']!.connected.contains('oldWorld|p2|1|0'),
          isTrue,
        );
      },
    );

    test(
      'parity: GP and non-GP resolvers produce the same per-tile connected set for equivalent inputs',
      () {
        // Build a single 3x3 owned province with a road at (0,1). Run the GP
        // resolver for a player with capitalProvinceId/capitalTile set, and the
        // non-GP resolver for a minor with the same capitalProvinceId and
        // capitalTile values. Verify their `connected` sets are identical (the
        // shared Road and Town rules apply faction-agnostically).
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ];
        final tileMap = TileMapResult(width: 3, height: 3, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final cap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 1,
          y: 1,
        );
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|1|1', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p1|0|0', 1);

        final gpGame = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );
        final minorGame = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final tileMapByRegion = {'oldWorld': tileMap};
        final gpResult = resolveConnectivity(
          game: gpGame,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );
        final minorResult = resolveNonGreatPowerConnectivity(
          game: minorGame,
          tileMapByRegion: tileMapByRegion,
          topology: topology,
        );

        expect(
          minorResult['minor_lux']!.connected,
          equals(gpResult['pl1']!.connected),
        );
      },
    );

    test(
      'GP and non-GP resolvers run independently — non-GP call does not return GP keys',
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p2'],
        ];
        final tileMap = TileMapResult(width: 2, height: 1, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        final gpCap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p1',
          x: 0,
          y: 0,
        );
        final minorCap = CapitalTile(
          regionId: ow,
          provinceId: '$ow|p2',
          x: 1,
          y: 0,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'pl1',
              displayName: 'Spain',
              isHuman: true,
              capitalProvinceId: '$ow|p1',
              capitalTile: gpCap,
            ),
          ],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p2',
              capitalTile: minorCap,
            ),
          ],
        );

        final nonGpResult = resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          topology: topology,
        );

        // The non-GP call only emits keys for minors and tribes. No GP player
        // id appears in the result map.
        expect(nonGpResult.containsKey('pl1'), isFalse);
        expect(nonGpResult.keys.toSet(), {'minor_lux'});
      },
    );
  });
}
