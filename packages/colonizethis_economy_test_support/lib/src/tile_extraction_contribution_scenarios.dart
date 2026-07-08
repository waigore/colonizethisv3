// Table-driven `computeTileExtractionContributionForPlayer` scenarios (Refs #3939).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'extraction_fixture_support.dart';

/// One row for per-tile extraction contribution scenario tables.
class TileExtractionContributionScenario {
  const TileExtractionContributionScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  final String label;
  final void Function() run;
  final String? refs;
}

void runTileExtractionContributionScenario(
  TileExtractionContributionScenario scenario,
) {
  scenario.run();
}

List<TileExtractionContributionScenario>
tileExtractionContributionScenarios({
  required TileMapResult grainTileMap,
}) => [
  TileExtractionContributionScenario(
    label: 'tile extraction contribution excludes aggregate capital grain bonus',
    run: () {
      const tileKey = 'oldWorld|p1|0|0';
      const connected = {tileKey};
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
        tileState: tileStateFromSpecs(const [
          TileImprovementSpec(tileKey, improvement: 1, roadLevel: 1),
        ]),
        players: [player],
      );
      final contribution = computeTileExtractionContributionForPlayer(
        game: game,
        tileMapByRegion: {'oldWorld': grainTileMap},
        player: player,
        tileKey: tileKey,
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
        tileMapByRegion: {'oldWorld': grainTileMap},
        player: player,
        tileKey: tileKey,
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
  ),
  TileExtractionContributionScenario(
    label: 'tile extraction contribution is null for disconnected tile',
    run: () {
      const tileKey = 'oldWorld|p1|0|0';
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
        tileMapByRegion: {'oldWorld': grainTileMap},
        player: player,
        tileKey: tileKey,
        connectedTileKeys: const {},
        pathTransportCap: const {},
        connectedByRoadRule: const {},
        portTileKeys: const {},
        prospectedTileKeys: const {},
        capitalRegionId: 'oldWorld',
        techCapForPlayer: (_) => 4,
      );
      expect(contribution, isNull);
    },
  ),
];
