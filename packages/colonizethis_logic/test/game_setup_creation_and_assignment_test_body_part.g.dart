part of 'game_setup_creation_and_assignment_test.dart';

void _defineTests() {
  group('GameSetup', () {
    test(
      'createGameFromGeneratedMaps produces Game with GPs, minors, tribes and capitals',
      () {
        // OW: 2 provinces (p1 sea-bound, p2 inland)
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);

        // NW: 1 province (nw1 sea-bound)
        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-game',
        );

        expect(result.game.id, 'test-game');
        expect(result.game.players.length, 1);
        expect(result.game.players.first.id, 'gp1');
        expect(result.game.mapViewState.zoomMultiplier, 4.0);
        expect(
          result.game.greatPowerColorOverride,
          equals({
            'gp1': [180, 80, 80],
          }),
        );
        expect(result.game.players.first.capitalProvinceId, 'oldWorld|p1');
        expect(
          result.game.players.first.capitalTile?.provinceId,
          'oldWorld|p1',
        );
        final gpCapitalTile = result.game.players.first.capitalTile;
        expect(gpCapitalTile, isNotNull);
        final gpCivilianUnits = result.game.worldState.oldWorld.units
            .where((u) => u.ownerId == 'gp1' && u.tileKey != null)
            .toList();
        expect(gpCivilianUnits, isNotEmpty);
        for (final u in gpCivilianUnits) {
          expect(
            u.tileKey,
            gpCapitalTile!.toTileKey(),
            reason: 'starting civilian ${u.id} must spawn on capital tile',
          );
        }

        expect(result.game.minorNations, isEmpty);
        expect(result.game.tribes.length, 1);
        expect(result.game.tribes.first.id, 'tribe1');
        expect(result.game.tribes.first.capitalProvinceId, 'newWorld|nw1');
        expect(result.game.tribes.first.capitalTile?.regionId, 'newWorld');
        final tribeCapitalTile = result.game.tribes.first.capitalTile;
        expect(tribeCapitalTile, isNotNull);
        final tribeCivilianUnits = result.game.worldState.newWorld.units
            .where((u) => u.ownerId == 'tribe1' && u.tileKey != null)
            .toList();
        expect(tribeCivilianUnits, isNotEmpty);
        for (final u in tribeCivilianUnits) {
          expect(
            u.tileKey,
            tribeCapitalTile!.toTileKey(),
            reason: 'starting civilian ${u.id} must spawn on capital tile',
          );
        }

        expect(result.game.worldState.oldWorld.provinces.length, 2);
        expect(result.game.worldState.newWorld.provinces.length, 1);
        expect(
          result.game.worldState.portsByProvinceSeaboard.containsKey(
            'oldWorld|p1|sea1',
          ),
          true,
        );
        expect(
          result.game.worldState.portsByProvinceSeaboard.containsKey(
            'newWorld|nw1|sea1',
          ),
          true,
        );

        // SPEC capital-and-connectivity § Town per province: every province has townTileKey set.
        final gp = result.game.players.first;
        for (final p in allProvinces(result.game.worldState)) {
          expect(
            p.townTileKey,
            isNotNull,
            reason: 'province ${p.id} must have townTileKey',
          );
        }
        final capitalProvince = result.game.worldState.oldWorld.provinces
            .firstWhere((p) => p.id == gp.capitalProvinceId);
        expect(
          capitalProvince.townTileKey,
          gp.capitalTile?.toTileKey(),
          reason: 'Capital province townTileKey must equal capital tile key',
        );

        // Province naming: mandatory; GP capital gets capital city name, others from pool.
        expect(result.game.players.first.displayName, 'England');
        for (final p in allProvinces(result.game.worldState)) {
          expect(
            p.displayName,
            isNotNull,
            reason: 'province ${p.id} must have displayName',
          );
        }
        final p1 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p1',
        );
        expect(p1.displayName, 'London');
        final nw1 = result.game.worldState.newWorld.provinces.firstWhere(
          (p) => p.id == 'newWorld|nw1',
        );
        expect(nw1.displayName, 'Mexica');
        expect(result.game.tribes.first.displayName, 'Aztec');

        expect(result.tileMapByRegion['oldWorld'], owTileMap);
        expect(result.topologyByRegion['oldWorld'], owTopology);
      },
    );

    test(
      'createGameFromGeneratedMaps assigns identical townTileKeys on repeated runs',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
          seed: 9001,
        );
        final owMap = TileMapResult(width: 2, height: 2, grid: owGrid);
        final nwMap = TileMapResult(width: 2, height: 2, grid: nwGrid);
        Map<String, String?> towns(GameSetupResult r) => {
          for (final p in allProvinces(r.game.worldState)) p.id: p.townTileKey,
        };
        final r1 = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwMap,
          topologyNewWorld: nwTopology,
          gameId: 'town-determinism-a',
        );
        final r2 = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwMap,
          topologyNewWorld: nwTopology,
          gameId: 'town-determinism-b',
        );
        expect(towns(r2), towns(r1));
      },
    );

    test(
      'createGameFromGeneratedMaps honors preferredInitialMapZoomMultiplier with clamp',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );

        final preferredConfig = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
          preferredInitialMapZoomMultiplier: 3.25,
        );
        final preferredResult = createGameFromGeneratedMaps(
          config: preferredConfig,
          tileMapOldWorld: TileMapResult(width: 2, height: 2, grid: owGrid),
          topologyOldWorld: owTopology,
          tileMapNewWorld: TileMapResult(width: 2, height: 2, grid: nwGrid),
          topologyNewWorld: nwTopology,
          gameId: 'preferred-map-zoom',
        );
        expect(preferredResult.game.mapViewState.zoomMultiplier, 3.25);

        final clampedConfig = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
          preferredInitialMapZoomMultiplier: 9.0,
        );
        final clampedResult = createGameFromGeneratedMaps(
          config: clampedConfig,
          tileMapOldWorld: TileMapResult(width: 2, height: 2, grid: owGrid),
          topologyOldWorld: owTopology,
          tileMapNewWorld: TileMapResult(width: 2, height: 2, grid: nwGrid),
          topologyNewWorld: nwTopology,
          gameId: 'clamped-map-zoom',
        );
        expect(clampedResult.game.mapViewState.zoomMultiplier, 8.0);
      },
    );

    test(
      'init raises road level on shortest owned-tile path from OW town to capital (SPEC § Init town roads)',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-town-roads',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        final tk = p2.townTileKey;
        expect(tk, isNotNull);
        expect(
          result.game.worldState.tileState.roadLevel(tk!),
          greaterThanOrEqualTo(1),
          reason: 'land-connected OW town needs init road link toward capital',
        );
      },
    );

    test(
      'initTownRoadWiringRegionIds empty skips town→capital road wiring',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);
        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
          initTownRoadWiringRegionIds: <String>{},
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-town-roads-off',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        final tk = p2.townTileKey;
        expect(tk, isNotNull);
        expect(
          result.game.worldState.tileState.roadLevel(tk!),
          0,
          reason: 'wiring disabled: no init town roads on non-capital province',
        );
      },
    );

    test(
      'sea-bound same-region province town is placed on a sea-zone-adjacent tile',
      () {
        final owGrid = [
          ['p1', 'p1', 'sea1', 'sea1'],
          ['p1', 'p2', 'p2', 'sea1'],
          ['p1', 'p2', 'p2', 'sea1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final owTileMap = TileMapResult(width: 4, height: 3, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-seaboard-town-placement',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        expect(p2.townTileKey, isNotNull);
        expect(
          p2.townTileKey,
          'oldWorld|p2|2|2',
          reason:
              'sea-bound province town must be seaboard-valid and closest to '
              'province centroid before shortest-path tie-break',
        );
      },
    );

    test(
      'same-region non-seaboard province town ranks centroid before BFS to capital',
      () {
        final owGrid = [
          ['p1', 'p2', 'p2'],
          ['p1', 'p1', 'p2'],
          ['sea1', 'sea1', 'sea1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final owTileMap = TileMapResult(width: 3, height: 3, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-centroid-before-bfs',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        expect(
          p2.townTileKey,
          'oldWorld|p2|2|0',
          reason:
              'p2 centroid favors (2,0) over (1,0) even though BFS from capital '
              'is shorter to (1,0)',
        );
      },
    );

    test(
      'sea-bound mismatch falls back to full-tile centroid then BFS selection',
      () {
        final owGrid = [
          ['p1', 'p1', 'sea1'],
          ['p1', 'p2', 'p1'],
          ['p1', 'p1', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final owTileMap = TileMapResult(width: 3, height: 3, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-seaboard-town-fallback',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        expect(
          p2.townTileKey,
          'oldWorld|p2|1|1',
          reason:
              'when no sea-zone-adjacent tile exists, seaboard town selection '
              'falls back to all tiles with centroid-then-BFS ordering',
        );
      },
    );

    test(
      'overseas province (capital in other region, no port) picks town by centroid',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p1', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);

        final nwGrid = [
          ['col', 'col', 'col'],
          ['col', 'col', 'col'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'col',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final nwTileMap = TileMapResult(width: 3, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 0,
          numProvincesOldWorld: 1,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
          initTownRoadWiringRegionIds: <String>{},
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-overseas-centroid',
        );

        var game = result.game;
        final nwProvinces = game.worldState.newWorld.provinces.map((p) {
          if (p.id == 'newWorld|col') {
            return p.copyWith(ownerId: 'gp1');
          }
          return p;
        }).toList();
        game = game.copyWith(
          worldState: game.worldState.copyWith(
            newWorld: RegionData(
              provinces: nwProvinces,
              units: game.worldState.newWorld.units,
            ),
          ),
        );

        game = assignProvinceTownsForTesting(
          game: game,
          topologyByRegion: result.topologyByRegion,
          tileMapByRegion: result.tileMapByRegion,
        );

        final col = game.worldState.newWorld.provinces.firstWhere(
          (p) => p.id == 'newWorld|col',
        );
        expect(
          col.townTileKey,
          'newWorld|col|1|1',
          reason:
              'GP capital in oldWorld; inland NW province has no port — town is '
              'the tile at rounded centroid (1,1), with lexicographic key as '
              'final tie-break when BFS to capital is not applicable',
        );
      },
    );

    test(
      'each Great Power has enough resources to build 5 improvements (bootstrap)',
      () {
        // SPEC/program/game-setup-pipeline.md §7f: initialImprovementSlots default 5.
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
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
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);
        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);
        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );
        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-bootstrap',
        );
        final start = config.startingResources;
        final expectedGrain = start.initialPeasants * start.initialGrainTurns;
        for (final player in result.game.players) {
          expect(
            player.stockpile.quantityOf(CommodityCatalog.grain.id),
            expectedGrain,
            reason: '${player.id} grain',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.lumber.id),
            start.initialImprovementSlots,
            reason: '${player.id} lumber for 5 improvements',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.castIron.id),
            start.initialImprovementSlots,
            reason: '${player.id} castIron for 5 improvements',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.wool.id),
            start.initialWool,
            reason: '${player.id} starting wool',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.paper.id),
            start.initialPaper,
            reason: '${player.id} starting paper',
          );
        }
      },
    );

    test(
      'Old World assignment reserves provinces for minors based on config',
      () {
        // Simple OW topology with 12 provinces in a line, p1 and p2 sea-bound.
        final owNodes = <TopologyNode>[
          const TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          for (var i = 1; i <= 12; i++)
            TopologyNode(
              id: 'p$i',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
        ];
        final owEdges = <TopologyEdge>[
          const TopologyEdge(id1: 'p1', id2: 'sea1'),
          const TopologyEdge(id1: 'p2', id2: 'sea1'),
          const TopologyEdge(id1: 'p12', id2: 'sea1'),
          for (var i = 1; i < 12; i++)
            TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
        ];
        final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
        final owTileMap = TileMapResult(
          width: 12,
          height: 2,
          grid: [
            [for (var i = 1; i <= 12; i++) 'p$i'],
            [for (var i = 1; i <= 12; i++) 'sea1'],
          ],
        );

        // NW not relevant for this assertion; keep minimal valid data.
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'nwSea',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
        );
        final nwTileMap = TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['nw1'],
            ['nwSea'],
          ],
        );

        const minorCount = 2;
        const minPerMinor = 3;
        const totalOw = 12;
        const availableForGps = totalOw - (minorCount * minPerMinor);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england', 'france'],
          continentCount: 1,
          minorNationCount: minorCount,
          tribeCount: 1,
          numProvincesOldWorld: totalOw,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: minPerMinor,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'ow-reservation',
        );

        final ow = result.game.worldState.oldWorld.provinces;
        final gpOwned = ow
            .where((p) => p.ownerId == 'gp1' || p.ownerId == 'gp2')
            .length;
        final minorOwned = ow
            .where((p) => p.ownerId == 'minor1' || p.ownerId == 'minor2')
            .length;

        expect(gpOwned, availableForGps);
        expect(minorOwned, totalOw - availableForGps);
        for (final minor in result.game.minorNations) {
          final minorCapitalTile = minor.capitalTile;
          expect(minorCapitalTile, isNotNull);
          final minorUnits = result.game.worldState.oldWorld.units
              .where((u) => u.ownerId == minor.id && u.tileKey != null)
              .toList();
          expect(minorUnits, isNotEmpty);
          for (final unit in minorUnits) {
            expect(unit.tileKey, minorCapitalTile!.toTileKey());
          }
        }
      },
    );

    test('New World assignment balances tribes by province count', () {
      // NW: 9 provinces in a 3x3 grid; simple adjacency.
      final nwGrid = [
        ['n1', 'n2', 'n3'],
        ['n4', 'n5', 'n6'],
        ['n7', 'n8', 'n9'],
      ];
      final nwNodes = <TopologyNode>[
        for (final id in ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9'])
          TopologyNode(
            id: id,
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final nwEdges = <TopologyEdge>[];
      List<String> neighboursOf(int x, int y) {
        final coords = <String>[];
        for (final d in const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ]) {
          final nx = x + d[0];
          final ny = y + d[1];
          if (nx >= 0 && nx < 3 && ny >= 0 && ny < 3) {
            coords.add(nwGrid[ny][nx]);
          }
        }
        return coords;
      }

      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final id = nwGrid[y][x];
          for (final nb in neighboursOf(x, y)) {
            nwEdges.add(TopologyEdge(id1: id, id2: nb));
          }
        }
      }

      final nwTopology = MapTopology(nodes: nwNodes, edges: nwEdges);
      final nwTileMap = TileMapResult(width: 3, height: 3, grid: nwGrid);

      // Minimal OW to satisfy config; single GP and no minors.
      final owTopology = MapTopology(
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
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final owTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['p1'],
          ['sea1'],
        ],
      );

      const tribeCount = 3;
      const totalNw = 9;
      const basePerTribe = totalNw ~/ tribeCount; // 3

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: tribeCount,
        numProvincesOldWorld: 1,
        numProvincesNewWorld: totalNw,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'nw-balance',
      );

      final nwProvs = result.game.worldState.newWorld.provinces;
      final countsByTribe = <String, int>{};
      for (final p in nwProvs) {
        final ownerId = p.ownerId ?? '';
        countsByTribe[ownerId] = (countsByTribe[ownerId] ?? 0) + 1;
      }

      expect(countsByTribe.length, tribeCount);
      for (final count in countsByTribe.values) {
        expect(count, inInclusiveRange(basePerTribe - 1, basePerTribe + 1));
      }
    });

    test('Old World minor assignment balances minors by province count', () {
      // OW: 24 provinces in a line, p1 and p2 sea-bound. 2 GPs, 6 minors.
      // reservedForMinors = 6 * 2 = 12, availableForGps = 12.
      // Minors get 12 provinces, basePerMinor = 2 each.
      final owNodes = <TopologyNode>[
        const TopologyNode(
          id: 'sea1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        for (var i = 1; i <= 24; i++)
          TopologyNode(
            id: 'p$i',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final owEdges = <TopologyEdge>[
        const TopologyEdge(id1: 'p1', id2: 'sea1'),
        const TopologyEdge(id1: 'p2', id2: 'sea1'),
        const TopologyEdge(id1: 'p24', id2: 'sea1'),
        for (var i = 1; i < 24; i++) TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
      ];
      final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
      final owTileMap = TileMapResult(
        width: 24,
        height: 2,
        grid: [
          [for (var i = 1; i <= 24; i++) 'p$i'],
          [for (var i = 1; i <= 24; i++) 'sea1'],
        ],
      );

      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
      );
      final nwTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['nw1'],
          ['nwSea'],
        ],
      );

      const minorCount = 6;
      const minPerMinor = 2;
      const totalOw = 24;
      const reservedForMinors = minorCount * minPerMinor; // 12
      const basePerMinor = reservedForMinors ~/ minorCount; // 2

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 1,
        minorNationCount: minorCount,
        tribeCount: 1,
        numProvincesOldWorld: totalOw,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: minPerMinor,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'ow-minor-balance',
      );

      final owProvs = result.game.worldState.oldWorld.provinces;
      final minorCounts = <String, int>{};
      for (final p in owProvs) {
        final ownerId = p.ownerId ?? '';
        if (ownerId.startsWith('minor')) {
          minorCounts[ownerId] = (minorCounts[ownerId] ?? 0) + 1;
        }
      }

      expect(
        minorCounts.length,
        minorCount,
        reason: 'Every minor should have at least one province',
      );
      for (final count in minorCounts.values) {
        expect(
          count,
          greaterThanOrEqualTo(1),
          reason: 'Each minor must have at least 1 province',
        );
        expect(
          count,
          inInclusiveRange(basePerMinor - 1, basePerMinor + 1),
          reason: 'Minor province counts should be within ±1 of equal split',
        );
      }
    });
  });
}
