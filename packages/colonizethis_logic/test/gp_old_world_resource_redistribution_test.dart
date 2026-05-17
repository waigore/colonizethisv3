import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('applyGreatPowerOldWorldResourceRedistribution', () {
    test(
      'preserves per-resource totals on GP tiles and leaves minor tiles unchanged',
      () {
        const pa = 'pa';
        const pb = 'pb';
        // GP `pa` (left 2 cols), minor `pb` (right col) with an extra row so `pb` has a
        // non-capital, non-town tile for copper.
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

        final ws = WorldState(
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
                townTileKey: CapitalTile.tileKey(
                  kRegionOldWorld,
                  pbFull,
                  2,
                  0,
                ), // distinct from minor capital (2,1)
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
        );

        var game = Game(
          id: 't',
          worldState: ws,
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
    );

    test(
      'same setupSeedBase yields identical OW resource grid for two runs',
      () {
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
          resourceGrid: [
            for (final row in resources) List<Resource?>.from(row),
          ],
        );

        final paFull = ProvinceId.full(kRegionOldWorld, pa);
        final pbFull = ProvinceId.full(kRegionOldWorld, pb);

        Game buildGame() {
          final resGrid = [
            [null, null, Resource.copper],
            [Resource.grain, Resource.tin, Resource.copper],
          ];
          return Game(
            id: 't',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: [
                  Province(
                    id: paFull,
                    regionId: kRegionOldWorld,
                    ownerId: 'gp1',
                    townTileKey: CapitalTile.tileKey(
                      kRegionOldWorld,
                      paFull,
                      1,
                      0,
                    ),
                  ),
                  Province(
                    id: pbFull,
                    regionId: kRegionOldWorld,
                    ownerId: 'gp2',
                    townTileKey: CapitalTile.tileKey(
                      kRegionOldWorld,
                      pbFull,
                      2,
                      1,
                    ),
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
        }

        TileMapResult runOnce() {
          var g = buildGame();
          var m = buildMap();
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
      },
    );

    test('throws when terrain-eligible capacity is below N_r', () {
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
                townTileKey: CapitalTile.tileKey(kRegionOldWorld, paFull, 1, 0),
              ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
          resourceByTileKey: {
            CapitalTile.tileKey(kRegionOldWorld, paFull, 0, 1): 'tin',
            CapitalTile.tileKey(kRegionOldWorld, paFull, 1, 1): 'tin',
          },
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

      expect(
        () => applyGreatPowerOldWorldResourceRedistribution(
          game: game,
          tileMapOldWorld: map,
          resourceRules: ResourceRules.defaultRules,
          setupSeedBase: 1,
        ),
        throwsA(isA<GpOldWorldResourceRedistributionInfeasibleException>()),
      );
    });
  });
}
