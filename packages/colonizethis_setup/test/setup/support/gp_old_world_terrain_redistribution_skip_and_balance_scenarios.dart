// Scenario table for GP OW terrain redistribution skip/balance (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'scenario_runner.dart';

List<RunnableScenario>
gpOldWorldTerrainRedistributionSkipAndBalanceScenarios() => [
  rs('skips when terrainGrid or resourceGrid is null', () {
    const pa = 'pa';
    final grid = [
      [pa, pa],
      [pa, pa],
    ];
    final terrain = [
      [TerrainType.plains, TerrainType.plains],
      [TerrainType.plains, TerrainType.plains],
    ];
    final mapNoRes = TileMapResult(
      width: 2,
      height: 2,
      grid: grid,
      terrainGrid: terrain,
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
          Province(id: paFull, regionId: kRegionOldWorld, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
    );
    final out = applyGreatPowerOldWorldTerrainRedistribution(
      game: game,
      tileMapOldWorld: mapNoRes,
      setupSeedBase: 1,
    );
    expect(identical(out.tileMap, mapNoRes), isTrue);
  }),
  rs('moves skewed plains toward capacity-weighted split for two GPs', () {
    const pa = 'pa';
    const pb = 'pb';
    final grid = [
      [pa, pa, pb, pb],
    ];
    final terrain = [
      [
        TerrainType.plains,
        TerrainType.plains,
        TerrainType.hills,
        TerrainType.hills,
      ],
    ];
    final resources = [
      [null, null, null, null],
    ];
    var map = TileMapResult(
      width: 4,
      height: 1,
      grid: grid,
      terrainGrid: terrain,
      resourceGrid: resources,
    );

    final paFull = ProvinceId.full(kRegionOldWorld, pa);
    final pbFull = ProvinceId.full(kRegionOldWorld, pb);

    final game = TestFixtures.minimalGame(
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
          Province(id: paFull, regionId: kRegionOldWorld, ownerId: 'gp1'),
          Province(id: pbFull, regionId: kRegionOldWorld, ownerId: 'gp2'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
    );

    expect(map.terrainAt(1, 0), TerrainType.plains);
    expect(map.terrainAt(3, 0), TerrainType.hills);

    final out = applyGreatPowerOldWorldTerrainRedistribution(
      game: game,
      tileMapOldWorld: map,
      setupSeedBase: 100,
    );
    map = out.tileMap;

    expect(
      {map.terrainAt(1, 0), map.terrainAt(3, 0)},
      {TerrainType.plains, TerrainType.hills},
    );
    expect(
      countTerrainOnGpOldWorldEligibleTiles(
        game: game,
        map: map,
        terrain: TerrainType.plains,
      ),
      1,
    );
    expect(map.terrainAt(0, 0), TerrainType.plains);
    expect(map.terrainAt(2, 0), TerrainType.hills);
  }),
];
