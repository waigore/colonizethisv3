import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show
        economyPreviewInputs,
        forcesFeedingForPlayer,
        labourReadinessForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';
import 'production_allocation_provider.dart';
import 'production_panel_session_cache.dart';

/// Stockpile preview, labour readiness, and forces feeding — session-cached
/// across `GAME20001` reopen when game/orders/allocation are unchanged.
final productionPanelOpenPathProvider =
    Provider.autoDispose<ProductionPanelOpenPathSnapshot?>((ref) {
      final game = ref.watch(currentGameProvider);
      if (game == null) return null;
      final orders = ref.watch(currentOrdersProvider);
      final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      if (mapData == null) return null;

      final playerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      final revision = productionPanelSessionRevision(
        game: game,
        orders: orders,
        desiredOutputByRecipe: desiredOutputByRecipe,
      );
      final session = ref.read(productionPanelSessionCacheProvider).state;
      if (session.openPathRevision == revision && session.openPath != null) {
        return session.openPath;
      }

      final topology = mapData.combinedTopology;
      final tileMapByRegion = mapData.tileMapByRegion;
      final openPath = ctAppPerfSync('production.openPath', () {
        final netDeltasByCommodity =
            previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: topology,
          playerId: playerId,
          inputs: economyPreviewInputs(
            tileMapByRegion: tileMapByRegion,
            currentOrders: orders,
            defaultAssignmentsByPlayerId: {
              playerId: assignedRecipesFromDesiredOutput(desiredOutputByRecipe),
            },
          ),
        );
        final regimentCounts = regimentTypeCountsForPlayer(
          game.worldState,
          playerId,
        );
        final shipCounts = shipTypeCountsForPlayer(game.worldState, playerId);
        final foodCounts = MilitaryNavyFoodCounts(
          regimentCountsById: regimentCounts,
          shipCountsById: shipCounts,
        );
        final previewInputs = economyPreviewInputs(
          tileMapByRegion: tileMapByRegion,
          currentOrders: orders,
        );
        return ProductionPanelOpenPathSnapshot(
          netDeltasByCommodity: netDeltasByCommodity,
          labourReadiness: labourReadinessForPlayer(
            game: game,
            topology: topology,
            playerId: playerId,
            foodCounts: foodCounts,
            inputs: previewInputs,
          ),
          forcesFeeding: forcesFeedingForPlayer(
            game: game,
            topology: topology,
            playerId: playerId,
            foodCounts: foodCounts,
            inputs: previewInputs,
          ),
        );
      });
      ref
          .read(productionPanelSessionCacheProvider)
          .storeOpenPath(revision: revision, openPath: openPath);
      return openPath;
    });
