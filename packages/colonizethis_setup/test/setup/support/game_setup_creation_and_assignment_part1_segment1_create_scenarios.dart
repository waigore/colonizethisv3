// Scenario table for GameSetup creation (segment 1 create) (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario>
gameSetupCreationAndAssignmentPart1Segment1CreateScenarios() => [
  rs(
    'createGameFromGeneratedMaps produces Game with GPs, minors, tribes and capitals',
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

      final config = configWithOverrides(
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
      expect(result.game.mapViewState.showPlayersBar, isFalse);
      expect(
        result.game.greatPowerColorOverride,
        equals({
          'gp1': [180, 80, 80],
        }),
      );
      expect(result.game.players.first.capitalProvinceId, 'oldWorld|p1');
      expect(result.game.players.first.capitalTile?.provinceId, 'oldWorld|p1');
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
  ),
];
