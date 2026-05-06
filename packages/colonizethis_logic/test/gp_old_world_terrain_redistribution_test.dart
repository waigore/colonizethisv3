import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyGreatPowerOldWorldTerrainRedistribution', () {
    test(
      'preserves per-terrain totals on eligible GP tiles; minors and '
      'town/capital terrain unchanged',
      () {
      const pa = 'pa';
      const pb = 'pb';
      final grid = [
        [pa, pa, pb],
        [pa, pa, pb],
      ];
      final terrain = [
        [
          TerrainType.plains,
          TerrainType.hills,
          TerrainType.plains,
        ],
        [
          TerrainType.forest,
          TerrainType.plains,
          TerrainType.desert,
        ],
      ];
      final resources = [
        [null, null, null],
        [null, null, null],
      ];
      var map = TileMapResult(
        width: 3,
        height: 2,
        grid: grid,
        terrainGrid: terrain,
        resourceGrid: resources,
      );

      final paFull = ProvinceId.full(kRegionOldWorld, pa);
      final pbFull = ProvinceId.full(kRegionOldWorld, pb);

      var game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
        ),
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
        minorNations: [
          MinorNation(
            id: 'minor1',
            displayName: 'M',
            capitalProvinceId: pbFull,
            capitalTile: CapitalTile(
              regionId: kRegionOldWorld,
              provinceId: pbFull,
              x: 2,
              y: 1,
            ),
          ),
        ],
      );

      int countTerrain(TerrainType t) =>
          countTerrainOnGpOldWorldEligibleTiles(game: game, map: map, terrain: t);

      final beforePlains = countTerrain(TerrainType.plains);
      final beforeHills = countTerrain(TerrainType.hills);
      final beforeForest = countTerrain(TerrainType.forest);
      final beforeDesert = countTerrain(TerrainType.desert);

      final out = applyGreatPowerOldWorldTerrainRedistribution(
        game: game,
        tileMapOldWorld: map,
        setupSeedBase: 777,
      );
      game = out.game;
      map = out.tileMap;

      expect(countTerrain(TerrainType.plains), beforePlains);
      expect(countTerrain(TerrainType.hills), beforeHills);
      expect(countTerrain(TerrainType.forest), beforeForest);
      expect(countTerrain(TerrainType.desert), beforeDesert);

      expect(map.terrainAt(2, 0), TerrainType.plains);
      expect(map.terrainAt(2, 1), TerrainType.desert);
      expect(map.terrainAt(0, 0), TerrainType.plains);
    });

    test('same setupSeedBase yields identical OW terrain grid for two runs', () {
      const pa = 'pa';
      const pb = 'pb';
      final grid = [
        [pa, pa, pb],
        [pa, pa, pb],
      ];
      final terrainFixed = [
        [
          TerrainType.plains,
          TerrainType.plains,
          TerrainType.hills,
        ],
        [
          TerrainType.hills,
          TerrainType.forest,
          TerrainType.plains,
        ],
      ];
      final resources = [
        [null, null, null],
        [null, null, null],
      ];
      TileMapResult buildMap() => TileMapResult(
        width: 3,
        height: 2,
        grid: grid,
        terrainGrid: [
          for (final row in terrainFixed) List<TerrainType?>.from(row),
        ],
        resourceGrid: [
          for (final row in resources) List<Resource?>.from(row),
        ],
      );

      final paFull = ProvinceId.full(kRegionOldWorld, pa);
      final pbFull = ProvinceId.full(kRegionOldWorld, pb);

      Game buildGame() => Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
                townTileKey: CapitalTile.tileKey(kRegionOldWorld, pbFull, 2, 0),
              ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
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
              y: 1,
            ),
          ),
        ],
      );

      TileMapResult runOnce() {
        final g = buildGame();
        var m = buildMap();
        final r = applyGreatPowerOldWorldTerrainRedistribution(
          game: g,
          tileMapOldWorld: m,
          setupSeedBase: 424242,
        );
        return r.tileMap;
      }

      final a = runOnce();
      final b = runOnce();
      expect(a.terrainGrid, b.terrainGrid);
    });

    test('skips when terrainGrid or resourceGrid is null', () {
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
      final game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: paFull,
                regionId: kRegionOldWorld,
                ownerId: 'gp1',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
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
      );
      final out = applyGreatPowerOldWorldTerrainRedistribution(
        game: game,
        tileMapOldWorld: mapNoRes,
        setupSeedBase: 1,
      );
      expect(identical(out.tileMap, mapNoRes), isTrue);
    });

    test('moves skewed plains toward capacity-weighted split for two GPs', () {
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

      var game = Game(
        id: 't',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: paFull,
                regionId: kRegionOldWorld,
                ownerId: 'gp1',
              ),
              Province(
                id: pbFull,
                regionId: kRegionOldWorld,
                ownerId: 'gp2',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
        ),
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
      );

      // Eligible tiles: (1,0) gp1 and (3,0) gp2 — capitals at (0,0) and (2,0) are excluded.
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
    });
  });
}
