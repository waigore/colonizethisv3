import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/features/game/flame/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_app/features/game/flame/province_action_state_calculator.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceActionStateCalculator.compute', () {
    test(
      'AC (negative) returns canonical hidden defaults when selectedTileKey is '
      'null (no order-engine validation invoked)',
      () {
        final states = ProvinceActionStateCalculator.compute(
          game: demoGameForOverlay,
          humanPlayerId: demoGameForOverlay.players.first.id,
          selectedTileKey: null,
          region: demoRegionForOverlay,
          playerView: demoHumanPlayerViewForOverlay,
          currentOrders: const ct_models.Orders(),
          workTargetSelectionCache: PerPlayerWorkTargetSelectionCache(),
          mapData: null,
        );

        expect(
          states.explore,
          GameMapAreaStateLogic.kHiddenExplorerInlineActionState,
        );
        expect(
          states.prospect,
          GameMapAreaStateLogic.kHiddenExplorerInlineActionState,
        );
        expect(
          states.buildImprovement,
          GameMapAreaStateLogic.kHiddenBuilderInlineActionState,
        );
      },
    );

    test(
      'AC (positive) forwards each state identically to the GameMapAreaStateLogic '
      'entry points for a resolved tile (behavior parity with the prior '
      'duplicated overlay computations)',
      () {
        final game = demoGameForOverlay;
        final region = demoRegionForOverlay;
        final humanPlayerId = game.players.first.id;
        final playerView = demoHumanPlayerViewForOverlay;
        final tileKey = sampleTileKeyForProvinceOverlay;
        const orders = ct_models.Orders();
        final cache = PerPlayerWorkTargetSelectionCache();

        final states = ProvinceActionStateCalculator.compute(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: tileKey,
          region: region,
          playerView: playerView,
          currentOrders: orders,
          workTargetSelectionCache: cache,
          mapData: null,
        );

        final expectedExplore =
            GameMapAreaStateLogic.provinceExploreActionState(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: tileKey,
          selectedRegion: region,
          workTargetSelectionCache: cache,
        );
        final expectedProspect =
            GameMapAreaStateLogic.provinceProspectActionState(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: tileKey,
          playerView: playerView,
          topology: null,
          currentOrders: orders,
          tileMapByRegion: null,
        );
        final expectedBuild =
            GameMapAreaStateLogic.provinceBuildImprovementActionState(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: tileKey,
          playerView: playerView,
          workTargetSelectionCache: cache,
        );

        expect(states.explore, expectedExplore);
        expect(states.prospect, expectedProspect);
        expect(states.buildImprovement, expectedBuild);
      },
    );
  });
}
