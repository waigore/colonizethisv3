// Scenario table for GP OW resource redistribution capacity (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'scenario_runner.dart';

List<RunnableScenario> gpOldWorldResourceRedistributionCapacityScenarios() => [
  rs('same setupSeedBase yields identical OW resource grid for two runs', () {
    const pa = 'pa';
    const pb = 'pb';
    final grid = [
      [pa, pa, pb],
      [pa, pa, pb],
    ];
    final terrainFixed = [
      [TerrainType.plains, TerrainType.plains, TerrainType.plains],
      [TerrainType.plains, TerrainType.swamp, TerrainType.plains],
    ];
    final resources = [
      [null, null, Resource.copper],
      [Resource.grain, Resource.tin, Resource.copper],
    ];
    TileMapResult buildMap() => TileMapResult(
      width: 3,
      height: 2,
      grid: grid,
      terrainGrid: terrainFixed,
      resourceGrid: [for (final row in resources) List<Resource?>.from(row)],
    );

    final paFull = ProvinceId.full(kRegionOldWorld, pa);
    final pbFull = ProvinceId.full(kRegionOldWorld, pb);

    Game buildGame() {
      final resGrid = [
        [null, null, Resource.copper],
        [Resource.grain, Resource.tin, Resource.copper],
      ];
      return TestFixtures.minimalGame(
        id: 't',
        players: [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: true,
            capitalProvinceId: paFull,
            capitalTile: CapitalTile(
              regionId: kRegionOldWorld,
              provinceId: paFull,
              x: 0,
              y: 0,
            ),
          ),
          Player(
            id: 'gp2',
            displayName: 'B',
            isHuman: false,
            capitalProvinceId: pbFull,
            capitalTile: CapitalTile(
              regionId: kRegionOldWorld,
              provinceId: pbFull,
              x: 2,
              y: 0,
            ),
          ),
        ],
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
              ownerId: 'gp2',
              townTileKey: CapitalTile.tileKey(kRegionOldWorld, pbFull, 2, 1),
            ),
          ],
        ),
        newWorld: const RegionData(provinces: []),
        resourceByTileKey: {
          for (var y = 0; y < 2; y++)
            for (var x = 0; x < 3; x++)
              if (resGrid[y][x] != null)
                CapitalTile.tileKey(
                  kRegionOldWorld,
                  ProvinceId.full(kRegionOldWorld, grid[y][x]),
                  x,
                  y,
                ): resGrid[y][x]!.name,
        },
      );
    }

    TileMapResult runOnce() {
      final g = buildGame();
      final m = buildMap();
      final r = applyGreatPowerOldWorldResourceRedistribution(
        game: g,
        tileMapOldWorld: m,
        resourceRules: ResourceRules.defaultRules,
        setupSeedBase: 9001,
      );
      return r.tileMap;
    }

    final a = runOnce();
    final b = runOnce();
    expect(a.resourceGrid, b.resourceGrid);
  }),
  rs('throws when terrain-eligible capacity is below N_r', () {
    const pa = 'pa';
    final grid = [
      [pa, pa],
      [pa, pa],
    ];
    final terrain = [
      [TerrainType.plains, TerrainType.plains],
      [TerrainType.plains, TerrainType.plains],
    ];
    final resources = [
      [null, null],
      [Resource.tin, Resource.tin],
    ];
    final map = TileMapResult(
      width: 2,
      height: 2,
      grid: grid,
      terrainGrid: terrain,
      resourceGrid: resources,
    );
    final paFull = ProvinceId.full(kRegionOldWorld, pa);
    final game = TestFixtures.minimalGame(
      id: 't',
      players: [
        Player(
          id: 'gp1',
          displayName: 'G',
          isHuman: true,
          capitalProvinceId: paFull,
          capitalTile: CapitalTile(
            regionId: kRegionOldWorld,
            provinceId: paFull,
            x: 0,
            y: 0,
          ),
        ),
      ],
      turnNumber: 0,
      oldWorld: RegionData(
        provinces: [
          Province(
            id: paFull,
            regionId: kRegionOldWorld,
            ownerId: 'gp1',
            townTileKey: CapitalTile.tileKey(kRegionOldWorld, paFull, 1, 0),
          ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: {
        CapitalTile.tileKey(kRegionOldWorld, paFull, 0, 1): 'tin',
        CapitalTile.tileKey(kRegionOldWorld, paFull, 1, 1): 'tin',
      },
    );

    expect(
      () => applyGreatPowerOldWorldResourceRedistribution(
        game: game,
        tileMapOldWorld: map,
        resourceRules: ResourceRules.defaultRules,
        setupSeedBase: 1,
      ),
      throwsA(isA<GpOldWorldResourceRedistributionInfeasibleException>()),
    );
  }),
];
