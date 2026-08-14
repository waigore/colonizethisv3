// Scenario table for GP OW resource redistribution preserves (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'scenario_runner.dart';

List<RunnableScenario> gpOldWorldResourceRedistributionPreservesScenarios() => [
  rs(
    'preserves per-resource totals on GP tiles and leaves minor tiles unchanged',
    () {
      const pa = 'pa';
      const pb = 'pb';
      final grid = [
        [pa, pa, pb],
        [pa, pa, pb],
        [pa, pa, pb],
      ];
      final terrain = [
        [TerrainType.plains, TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains, TerrainType.plains],
        [TerrainType.plains, TerrainType.plains, TerrainType.hills],
      ];
      final resources = [
        [null, null, null],
        [Resource.grain, Resource.meat, null],
        [null, null, Resource.copper],
      ];
      var map = TileMapResult(
        width: 3,
        height: 3,
        grid: grid,
        terrainGrid: terrain,
        resourceGrid: resources,
      );

      final paFull = ProvinceId.full(kRegionOldWorld, pa);
      final pbFull = ProvinceId.full(kRegionOldWorld, pb);
      final capGp = CapitalTile(
        regionId: kRegionOldWorld,
        provinceId: paFull,
        x: 0,
        y: 0,
      );
      final capMinor = CapitalTile(
        regionId: kRegionOldWorld,
        provinceId: pbFull,
        x: 2,
        y: 1,
      );

      var game = TestFixtures.minimalGame(
        id: 't',
        turnNumber: 0,
        oldWorld: RegionData(
          provinces: [
            Province(
              id: paFull,
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
              townTileKey: CapitalTile.tileKey(kRegionOldWorld, paFull, 1, 0),
            ),
            Province(
              id: pbFull,
              regionId: kRegionOldWorld,
              ownerId: 'minor1',
              townTileKey: CapitalTile.tileKey(kRegionOldWorld, pbFull, 2, 0),
            ),
          ],
        ),
        newWorld: const RegionData(provinces: []),
        resourceByTileKey: {
          for (var y = 0; y < 3; y++)
            for (var x = 0; x < 3; x++)
              if (resources[y][x] != null)
                CapitalTile.tileKey(
                  kRegionOldWorld,
                  ProvinceId.full(kRegionOldWorld, grid[y][x]),
                  x,
                  y,
                ): resources[y][x]!.name,
        },
        tileState: TileMapState(
          improvementByTile: {
            CapitalTile.tileKey(kRegionOldWorld, paFull, 1, 1): 2,
            CapitalTile.tileKey(kRegionOldWorld, pbFull, 2, 2): 1,
          },
        ),
        players: [
          Player(
            id: 'gp1',
            displayName: 'G',
            isHuman: true,
            capitalProvinceId: paFull,
            capitalTile: capGp,
          ),
        ],
        minorNations: [
          MinorNation(
            id: 'minor1',
            displayName: 'M',
            capitalProvinceId: pbFull,
            capitalTile: capMinor,
          ),
        ],
      );

      final nGrainBefore = countResourceOnGpOldWorldTiles(
        game: game,
        map: map,
        resource: Resource.grain,
      );
      final nMeatBefore = countResourceOnGpOldWorldTiles(
        game: game,
        map: map,
        resource: Resource.meat,
      );
      expect(nGrainBefore, 1);
      expect(nMeatBefore, 1);

      final minorCopperBefore = map.resourceAt(2, 2);

      final out = applyGreatPowerOldWorldResourceRedistribution(
        game: game,
        tileMapOldWorld: map,
        resourceRules: ResourceRules.defaultRules,
        setupSeedBase: 4242,
      );
      game = out.game;
      map = out.tileMap;

      expect(
        countResourceOnGpOldWorldTiles(
          game: game,
          map: map,
          resource: Resource.grain,
        ),
        nGrainBefore,
      );
      expect(
        countResourceOnGpOldWorldTiles(
          game: game,
          map: map,
          resource: Resource.meat,
        ),
        nMeatBefore,
      );

      expect(map.resourceAt(2, 2), minorCopperBefore);
      expect(
        game.worldState.tileState.improvementLevel(
          CapitalTile.tileKey(kRegionOldWorld, pbFull, 2, 2),
        ),
        1,
      );
      for (final k in collectTownAndCapitalTileKeys(game)) {
        expect(map.resourceGrid, isNotNull);
        final p = k.split('|');
        final x = int.parse(p[2]);
        final y = int.parse(p[3]);
        expect(map.resourceAt(x, y), isNull);
      }
    },
  ),
];
