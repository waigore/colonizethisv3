import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/src/world/connectivity_resolver.dart';
import 'package:logger/logger.dart';

import 'test_fixtures.dart';

void main() {
  group('ResourceExtractor', () {
    test(
      'returns empty ExtractionTotals when player has no connected tiles',
      () {
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
        final game = TestFixtures.minimalGame(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
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
          players: [player],
        );
        final result = computeExtraction(
          game: game,
          tileMapByRegion: const {},
          connectivityResult: {'pl1': ConnectivityResult(connected: {})},
          techCapForPlayer: (_) => 4,
        );
        expect(result['pl1']!.land, isEmpty);
        expect(result['pl1']!.overseas, isEmpty);
      },
    );

    test(
      'skips connected tile and logs when province missing from region (world-model)',
      () {
        final captured = <LogEvent>[];
        void listener(LogEvent e) => captured.add(e);
        Logger.addLogListener(listener);
        addTearDown(() {
          Logger.removeLogListener(listener);
          captured.clear();
        });
        Logger.level = Level.error;
        addTearDown(() => Logger.level = Level.off);

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
            .setImprovement('oldWorld|p1|0|0', 2)
            .setRoadLevel('oldWorld|p1|0|0', 2);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        );
        final game = TestFixtures.minimalGame(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 0,
          oldWorld: const RegionData(provinces: []),
          tileState: tileState,
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
        expect(result['pl1']!.land['grain'], isNull);
        expect(
          captured.any(
            (e) => e.message.contains('extraction province missing'),
          ),
          isTrue,
        );
      },
    );

    test('capital tile grain bonus is unconditional on connectivity', () {
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
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
        players: [player],
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: const {},
        connectivityResult: {'pl1': const ConnectivityResult(connected: {})},
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 5);
      expect(result['pl1']!.overseas, isEmpty);
    });

    test(
      'tile extraction contribution excludes aggregate capital grain bonus',
      () {
        final tileMap = TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          resourceGrid: const [
            [Resource.grain],
          ],
        );
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        );
        final game = TestFixtures.minimalGame(
          id: 'g1',
          capitalTileGrainBonusPerTurn: 5,
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
          tileState: TileMapState()
              .setImprovement('oldWorld|p1|0|0', 1)
              .setRoadLevel('oldWorld|p1|0|0', 1),
          players: [player],
        );
        final connected = {'oldWorld|p1|0|0'};
        final contribution = computeTileExtractionContributionForPlayer(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          player: player,
          tileKey: 'oldWorld|p1|0|0',
          connectedTileKeys: connected,
          pathTransportCap: const {},
          connectedByRoadRule: connected,
          portTileKeys: const {},
          prospectedTileKeys: connected,
          capitalRegionId: 'oldWorld',
          techCapForPlayer: (_) => 4,
        );
        expect(contribution, isNotNull);
        expect(contribution!.commodityId, 'grain');
        expect(contribution.units, 1);

        final provincesByFullId = {
          for (final p in game.worldState.oldWorld.provinces) p.id: p,
          for (final p in game.worldState.newWorld.provinces) p.id: p,
        };
        final withIndex = computeTileExtractionContributionForPlayer(
          game: game,
          tileMapByRegion: {'oldWorld': tileMap},
          player: player,
          tileKey: 'oldWorld|p1|0|0',
          connectedTileKeys: connected,
          pathTransportCap: const {},
          connectedByRoadRule: connected,
          portTileKeys: const {},
          prospectedTileKeys: connected,
          capitalRegionId: 'oldWorld',
          techCapForPlayer: (_) => 4,
          provincesByFullId: provincesByFullId,
        );
        expect(withIndex, isNotNull);
        expect(withIndex!.commodityId, contribution.commodityId);
        expect(withIndex.units, contribution.units);
      },
    );

    test('tile extraction contribution is null for disconnected tile', () {
      final tileMap = TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['p1'],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 0,
          y: 0,
        ),
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
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
        tileState: TileMapState(),
        players: [player],
      );
      final contribution = computeTileExtractionContributionForPlayer(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        player: player,
        tileKey: 'oldWorld|p1|0|0',
        connectedTileKeys: const {},
        pathTransportCap: const {},
        connectedByRoadRule: const {},
        portTileKeys: const {},
        prospectedTileKeys: const {},
        capitalRegionId: 'oldWorld',
        techCapForPlayer: (_) => 4,
      );
      expect(contribution, isNull);
    });
  });
}
