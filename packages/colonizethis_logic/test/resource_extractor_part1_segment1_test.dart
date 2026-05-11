import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('ResourceExtractor', () {
    test('stub connectivity: land totals and tech cap applied', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final resourceGrid = [
        [Resource.grain, Resource.timber],
        [Resource.iron, null],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 3)
          .setImprovement('oldWorld|p1|1|0', 2)
          .setImprovement('oldWorld|p1|0|1', 4)
          .setRoadLevel('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p1|0|1', 0);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final connectivity = {
        'pl1': ConnectivityResult(
          connected: {'oldWorld|p1|0|0', 'oldWorld|p1|1|0', 'oldWorld|p1|0|1'},
        ),
      };
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivity,
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1'], isNotNull);
      final tot = result['pl1']!;
      expect(tot.overseas, isEmpty);
      expect(tot.land['grain'], 2);
      expect(tot.land['timber'], 1);
      expect(tot.land['iron'], isNull);
    });

    test('effective extraction capped by transport level', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 1);
    });

    test('effective extraction capped by player tech cap when improvement and '
        'transport are high', () {
      final grid = [
        ['p1'],
      ];
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: grid,
        resourceGrid: [
          [Resource.grain],
        ],
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 4);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = Game(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'pl1',
                townDevelopmentLevel: 4,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileState: tileState,
        ),
        players: [player],
      );
      final resultCap2 = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 2,
      );
      expect(resultCap2['pl1']!.land['grain'], 2);

      final resultCap3 = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: {
          'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
        },
        techCapForPlayer: (_) => 3,
      );
      expect(resultCap3['pl1']!.land['grain'], 3);
    });

    test(
      'tech cap from extractionCapForUnlocked matches turn_resolver wiring',
      () {
        final grid = [
          ['p1'],
        ];
        final tileMap = TileMapResult(
          width: 1,
          height: 1,
          grid: grid,
          resourceGrid: [
            [Resource.grain],
          ],
        );
        final tileState = TileMapState()
            .setImprovement('oldWorld|p1|0|0', 4)
            .setRoadLevel('oldWorld|p1|0|0', 4);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
          techUnlocked: {kTechIdSawMill: true, kTechIdSeedDrill: true},
        );
        final game = Game(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                  townDevelopmentLevel: 4,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [player],
        );
        final result = computeExtraction(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          connectivityResult: {
            'pl1': ConnectivityResult(connected: {'oldWorld|p1|0|0'}),
          },
          techCapForPlayer: (playerId) {
            final p = game.playerById(playerId);
            return extractionCapForUnlocked(p?.techUnlocked);
          },
        );
        expect(extractionCapForUnlocked(player.techUnlocked), 3);
        expect(result['pl1']!.land['grain'], 3);
      },
    );
  });
}
