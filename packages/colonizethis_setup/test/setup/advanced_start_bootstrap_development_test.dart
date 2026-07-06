import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

Game _developmentFixture() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|p1',
            regionId: kRegionOldWorld,
            ownerId: 'gp1',
            townTileKey: 'oldWorld|p1|1|1',
          ),
          Province(
            id: 'oldWorld|m1',
            regionId: kRegionOldWorld,
            ownerId: 'minor1',
            townTileKey: 'oldWorld|m1|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      tileKeysByRegionAndProvince: {
        kRegionOldWorld: {
          'oldWorld|p1': [
            'oldWorld|p1|0|0',
            'oldWorld|p1|1|0',
            'oldWorld|p1|1|1',
            'oldWorld|p1|2|0',
          ],
          'oldWorld|m1': [
            'oldWorld|m1|0|0',
            'oldWorld|m1|1|0',
            'oldWorld|m1|2|0',
          ],
        },
      },
      resourceByTileKey: {
        'oldWorld|p1|0|0': 'grain',
        'oldWorld|p1|1|0': 'timber',
        'oldWorld|p1|2|0': 'wool',
        'oldWorld|m1|1|0': 'grain',
        'oldWorld|m1|2|0': 'meat',
      },
    ),
    players: const [
      Player(
        id: 'gp1',
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: kRegionOldWorld,
          provinceId: 'p1',
          x: 1,
          y: 1,
        ),
      ),
    ],
    minorNations: const [
      MinorNation(
        id: 'minor1',
        displayName: 'Minor 1',
        capitalProvinceId: 'oldWorld|m1',
        capitalTile: CapitalTile(
          regionId: kRegionOldWorld,
          provinceId: 'm1',
          x: 0,
          y: 0,
        ),
      ),
    ],
  );
}

TileMapResult _owTileMap() => TileMapResult(
  width: 4,
  height: 2,
  grid: const [
    ['m1', 'm1', 'm1', 'm1'],
    ['p1', 'p1', 'p1', 'p1'],
  ],
);

void main() {
  group('applyAdvancedStartDevelopment', () {
    test('turns50 develops 25% of GP and minor tiles with roads', () {
      final game = applyAdvancedStartDevelopment(
        game: _developmentFixture(),
        startType: AdvancedStartType.turns50,
        tileMapByRegion: {kRegionOldWorld: _owTileMap()},
        topologyByRegion: const {
          kRegionOldWorld: MapTopology(nodes: [], edges: []),
        },
      );

      expect(
        game.worldState.tileState.improvementLevel('oldWorld|p1|0|0'),
        1,
      );
      expect(
        game.worldState.purchasedTilesByTileKey['oldWorld|m1|1|0'],
        'gp1',
      );
      expect(
        game.worldState.tileState.roadLevel('oldWorld|p1|0|0'),
        greaterThanOrEqualTo(1),
      );
    });

    test('turns50 develops prospected minerals when no higher-priority tiles', () {
      final mineralFixture = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: kRegionOldWorld,
                ownerId: 'gp1',
                townTileKey: 'oldWorld|p1|1|1',
              ),
              Province(
                id: 'oldWorld|m1',
                regionId: kRegionOldWorld,
                ownerId: 'minor1',
                townTileKey: 'oldWorld|m1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(provinces: []),
          tileKeysByRegionAndProvince: {
            kRegionOldWorld: {
              'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|1'],
              'oldWorld|m1': ['oldWorld|m1|0|0', 'oldWorld|m1|1|0'],
            },
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'iron',
            'oldWorld|m1|1|0': 'copper',
          },
          playerProspectedTiles: const {
            'gp1': {'oldWorld|p1|0|0', 'oldWorld|m1|1|0'},
          },
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'England',
            isHuman: true,
            capitalProvinceId: 'oldWorld|p1',
            capitalTile: CapitalTile(
              regionId: kRegionOldWorld,
              provinceId: 'p1',
              x: 1,
              y: 1,
            ),
          ),
        ],
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor 1',
            capitalProvinceId: 'oldWorld|m1',
            capitalTile: CapitalTile(
              regionId: kRegionOldWorld,
              provinceId: 'm1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      final game = applyAdvancedStartDevelopment(
        game: mineralFixture,
        startType: AdvancedStartType.turns50,
        tileMapByRegion: {kRegionOldWorld: _owTileMap()},
        topologyByRegion: const {
          kRegionOldWorld: MapTopology(nodes: [], edges: []),
        },
      );

      expect(
        game.worldState.tileState.improvementLevel('oldWorld|p1|0|0'),
        1,
      );
      expect(
        game.worldState.tileState.improvementLevel('oldWorld|m1|1|0'),
        1,
      );
      expect(
        game.worldState.purchasedTilesByTileKey['oldWorld|m1|1|0'],
        'gp1',
      );
    });
  });
}
