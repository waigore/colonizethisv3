import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import '../world_test_support/world_test_support.dart';

void main() {
  _connectivity_resolver_non_gp_testTests();
}

void _connectivity_resolver_non_gp_testTests() {
  group('resolveNonGreatPowerConnectivity', () {
    test('empty map when no minors and no tribes', () {
      const ow = 'oldWorld';
      final tileMap = tileMapFromGrid([
        ['p1', 'p1'],
        ['p1', 'p1'],
      ]);
      final topology = singleProvinceTopology(
        regionId: ow,
        provinceLocalId: 'p1',
      );
      final game = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
        ],
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        topology: topology,
      );

      expect(result, isEmpty);
    });

    for (final case_ in _nullCapitalCases) {
      test(case_.description, () {
        final result = resolveNonGreatPowerConnectivity(
          game: case_.game,
          tileMapByRegion: case_.tileMapByRegion,
          topology: case_.topology,
        );

        expect(result[case_.factionId], isNotNull);
        expect(result[case_.factionId]!.connected, isEmpty);
        if (case_.assertEmptyPathMaps) {
          expect(result[case_.factionId]!.pathTransportCap, isEmpty);
          expect(result[case_.factionId]!.connectedByRoadRule, isEmpty);
        }
      });
    }

    test(
      'minor with capital and no roads: capital + 4-adjacent owned tiles connected',
      () {
        const ow = 'oldWorld';
        final tileMap = tileMapFromGrid([
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
          ['p1', 'p1', 'p1'],
        ]);
        final topology = singleProvinceTopology(
          regionId: ow,
          provinceLocalId: 'p1',
        );
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
          ],
          players: const [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              displayName: 'Luxembourg',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final result = resolveNonGreatPowerConnectivity(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          topology: topology,
        );

        expect(result['minor_lux'], isNotNull);
        final connected = result['minor_lux']!.connected;
        expect(connected.contains('oldWorld|p1|1|1'), isTrue);
        expect(connected.contains('oldWorld|p1|0|1'), isTrue);
        expect(connected.contains('oldWorld|p1|2|1'), isTrue);
        expect(connected.contains('oldWorld|p1|1|0'), isTrue);
        expect(connected.contains('oldWorld|p1|1|2'), isTrue);
        // Diagonals are NOT connected without roads (only Road rule + Town rule
        // 4-adjacency from capital tile).
        expect(connected.contains('oldWorld|p1|0|0'), isFalse);
      },
    );

    test('tribe in NW: road chain extends connectivity beyond adjacency', () {
      const nw = 'newWorld';
      final tileMap = tileMapFromGrid([
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ]);
      final topology = singleProvinceTopology(
        regionId: nw,
        provinceLocalId: 'p1',
      );
      final cap = CapitalTile(regionId: nw, provinceId: '$nw|p1', x: 0, y: 0);
      final tileState = TileMapState()
          .setRoadLevel('newWorld|p1|0|0', 1)
          .setRoadLevel('newWorld|p1|1|0', 1)
          .setRoadLevel('newWorld|p1|2|0', 1);
      final game = ordersPhaseGame(
        newWorldProvinces: [
          Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
        ],
        tileState: tileState,
        players: const [],
        tribes: [
          Tribe(
            id: 'tribe_iro',
            displayName: 'Iroquois',
            capitalProvinceId: '$nw|p1',
            capitalTile: cap,
          ),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'newWorld': tileMap},
        topology: topology,
      );

      final connected = result['tribe_iro']!.connected;
      expect(connected.contains('newWorld|p1|0|0'), isTrue);
      expect(connected.contains('newWorld|p1|1|0'), isTrue);
      expect(connected.contains('newWorld|p1|2|0'), isTrue);
      // (2,1) is adjacent to a road tile (2,0) under Road rule "on or next to" so
      // it is also connected.
      expect(connected.contains('newWorld|p1|2|1'), isTrue);
    });

    test('multi-faction: keys map separately by minor id and tribe id', () {
      const ow = 'oldWorld';
      const nw = 'newWorld';
      final owMap = tileMapFromGrid([
        ['p1', 'p1'],
        ['p2', 'p2'],
      ]);
      final nwMap = tileMapFromGrid([
        ['p3', 'p3'],
      ]);
      final topology = threeProvinceDualRegionLandTopology();
      final capLux = CapitalTile(
        regionId: ow,
        provinceId: '$ow|p1',
        x: 0,
        y: 0,
      );
      final capDen = CapitalTile(
        regionId: ow,
        provinceId: '$ow|p2',
        x: 0,
        y: 1,
      );
      final capIro = CapitalTile(
        regionId: nw,
        provinceId: '$nw|p3',
        x: 0,
        y: 0,
      );
      final game = ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
          Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_den'),
        ],
        newWorldProvinces: [
          Province(id: '$nw|p3', regionId: nw, ownerId: 'tribe_iro'),
        ],
        players: const [],
        minorNations: [
          MinorNation(
            id: 'minor_lux',
            capitalProvinceId: '$ow|p1',
            capitalTile: capLux,
          ),
          MinorNation(
            id: 'minor_den',
            capitalProvinceId: '$ow|p2',
            capitalTile: capDen,
          ),
        ],
        tribes: [
          Tribe(
            id: 'tribe_iro',
            capitalProvinceId: '$nw|p3',
            capitalTile: capIro,
          ),
        ],
      );

      final result = resolveNonGreatPowerConnectivity(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topology: topology,
      );

      expect(result.keys.toSet(), {'minor_lux', 'minor_den', 'tribe_iro'});
      // Each faction sees its own capital tile (same per-tile semantics as the
      // Great Power resolver — see capital-and-connectivity.md § Connectivity
      // (Game Rule)).
      expect(
        result['minor_lux']!.connected.contains('oldWorld|p1|0|0'),
        isTrue,
      );
      expect(
        result['minor_den']!.connected.contains('oldWorld|p2|0|1'),
        isTrue,
      );
      expect(
        result['tribe_iro']!.connected.contains('newWorld|p3|0|0'),
        isTrue,
      );
      // Region isolation: tribe_iro's New World province tiles never appear in
      // minor_lux's or minor_den's Old World result, and vice versa (no
      // cross-region leakage even via single-hop expansion).
      expect(
        result['minor_lux']!.connected.contains('newWorld|p3|0|0'),
        isFalse,
      );
      expect(
        result['minor_den']!.connected.contains('newWorld|p3|0|0'),
        isFalse,
      );
      expect(
        result['tribe_iro']!.connected.contains('oldWorld|p1|0|0'),
        isFalse,
      );
      expect(
        result['tribe_iro']!.connected.contains('oldWorld|p2|0|1'),
        isFalse,
      );
    });

    test(
      'war does not block market access: enemy fleet on Blockade against minor port leaves minor connectivity unchanged',
      () {
        const ow = 'oldWorld';
        // Two-province OW: p1 inland (capital), p2 seaboard (port).
        final tileMap = tileMapFromGrid([
          ['p1', 'p2'],
          ['p1', 'p2'],
        ]);
        final topology = inlandAndSeaboardProvincesTopology(regionId: ow);
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
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

        final gameNoFleet = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: ports,
          players: const [],
          minorNations: [
            MinorNation(
              id: 'minor_lux',
              capitalProvinceId: '$ow|p1',
              capitalTile: cap,
            ),
          ],
        );

        final gameWithBlockade = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
          ],
          tileState: tileState,
          portsByProvinceSeaboard: ports,
          fleets: [blockadingFleet],
          players: const [],
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
        final tileMap = uniformProvinceTileMap('p1', size: 3);
        final topology = singleProvinceTopology(
          regionId: ow,
          provinceLocalId: 'p1',
        );
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 1, y: 1);
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|1|1', 1)
            .setRoadLevel('oldWorld|p1|0|1', 1)
            .setRoadLevel('oldWorld|p1|0|0', 1);

        final gpGame = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ],
          tileState: tileState,
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
        final minorGame = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
          ],
          tileState: tileState,
          players: const [],
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
        final tileMap = tileMapFromGrid([
          ['p1', 'p2'],
        ]);
        final topology = twoProvinceLandTopology(regionId: ow);
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
        final game = ordersPhaseGame(
          oldWorldProvinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
            Province(id: '$ow|p2', regionId: ow, ownerId: 'minor_lux'),
          ],
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

typedef _NullCapitalCase = ({
  String description,
  String factionId,
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
  bool assertEmptyPathMaps,
});

List<_NullCapitalCase> get _nullCapitalCases {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  return [
    (
      description: 'minor with null capitalTile gets empty ConnectivityResult',
      factionId: 'minor_lux',
      assertEmptyPathMaps: true,
      topology: singleProvinceTopology(
        regionId: ow,
        provinceLocalId: 'p1',
      ),
      tileMapByRegion: {
        'oldWorld': tileMapFromGrid([
          ['p1', 'p1'],
        ]),
      },
      game: ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
        ],
        players: const [],
        minorNations: [
          // Capital intentionally unset (e.g. before terminal fall).
          const MinorNation(id: 'minor_lux'),
        ],
      ),
    ),
    (
      description: 'tribe with null capitalTile gets empty ConnectivityResult',
      factionId: 'tribe_iro',
      assertEmptyPathMaps: false,
      topology: singleProvinceTopology(
        regionId: nw,
        provinceLocalId: 'p1',
      ),
      tileMapByRegion: {
        'newWorld': tileMapFromGrid([
          ['p1'],
        ]),
      },
      game: ordersPhaseGame(
        newWorldProvinces: [
          Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
        ],
        players: const [],
        tribes: [const Tribe(id: 'tribe_iro')],
      ),
    ),
  ];
}
