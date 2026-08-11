import 'package:colonizethis_app/features/game/screens/development/development_panel_map_snapshot.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  test(
    'developmentPanelMapSnapshotCacheKey is stable for highlight-only inputs (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final playerView = buildPlayerView(
        game,
        developmentPanelMapCombinedTopology,
        kPanelTestHumanPlayerId,
      );
      final baseKey = developmentPanelMapSnapshotCacheKey(
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        regionId: kRegionOldWorld,
        playerView: playerView,
      );
      expect(
        developmentPanelMapSnapshotCacheKey(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          regionId: kRegionOldWorld,
          playerView: playerView,
        ),
        baseKey,
      );
    },
  );

  test(
    'developmentPanelMapSnapshotCacheKey changes when visibility changes (Refs #4175 Slice E)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final playerView = buildPlayerView(
        game,
        developmentPanelMapCombinedTopology,
        kPanelTestHumanPlayerId,
      );
      final baseKey = developmentPanelMapSnapshotCacheKey(
        game: game,
        humanPlayerId: kPanelTestHumanPlayerId,
        regionId: kRegionOldWorld,
        playerView: playerView,
      );
      final alteredVisibility = Map<String, VisibilityLevel>.from(
        playerView.visibilityByTile,
      );
      final firstKey = alteredVisibility.keys.first;
      alteredVisibility[firstKey] = VisibilityLevel.unknown;
      final alteredView = PlayerView(
        playerId: playerView.playerId,
        player: playerView.player,
        ownUnitsById: playerView.ownUnitsById,
        provincesById: playerView.provincesById,
        visibilityByTile: alteredVisibility,
        prospectedTiles: playerView.prospectedTiles,
        diplomacyByOtherId: playerView.diplomacyByOtherId,
      );
      expect(
        developmentPanelMapSnapshotCacheKey(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          regionId: kRegionOldWorld,
          playerView: alteredView,
        ),
        isNot(baseKey),
      );
    },
  );
}
