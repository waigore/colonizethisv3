import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show ConnectivityResult, PlayerView, allProvinces, buildPlayerView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

/// Shared Development panel inputs memoized across [DevelopmentScreenBody] rebuilds.
///
/// Recomputes only when game, orders, map data, or shell player context change.
/// Refs #4175 Slice E.
class DevelopmentPanelProjection {
  const DevelopmentPanelProjection({
    required this.game,
    required this.humanPlayerId,
    required this.shared,
    required this.playerView,
    required this.provinceDisplayNamesById,
    required this.playerDisplayNamesById,
    required this.topology,
    required this.tileMapByRegion,
  });

  final Game game;
  final String humanPlayerId;
  final DevelopmentPanelBuildContext shared;
  final PlayerView playerView;
  final Map<String, String> provinceDisplayNamesById;
  final Map<String, String> playerDisplayNamesById;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
}

/// Connectivity map — invalidates on game/map changes only (not draft orders).
final developmentPanelConnectivityProvider =
    Provider<Map<String, ConnectivityResult>?>((ref) {
      final game = ref.watch(currentGameProvider);
      if (game == null) {
        return null;
      }
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      if (mapData == null) {
        return null;
      }
      return resolveDevelopmentPanelConnectivity(
        game: game,
        tileMapByRegion: mapData.tileMapByRegion,
        topology: mapData.combinedTopology,
      );
    });

/// Connectivity, [PlayerView], and display-name maps — once per relevant input change.
final developmentPanelProjectionProvider =
    Provider<DevelopmentPanelProjection?>((ref) {
      final game = ref.watch(currentGameProvider);
      if (game == null) {
        return null;
      }
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      if (mapData == null) {
        return null;
      }
      final connectivity = ref.watch(developmentPanelConnectivityProvider);
      if (connectivity == null) {
        return null;
      }
      final orders = ref.watch(currentOrdersProvider);
      final shell = ref.watch(shellPlayerContextProvider);
      final humanPlayerId = resolveShellPanelPlayerId(shell, game);

      final provinceDisplayNamesById = <String, String>{};
      for (final province in allProvinces(game.worldState)) {
        provinceDisplayNamesById[province.id] =
            province.displayName ?? province.id;
      }
      final playerDisplayNamesById = {
        for (final player in game.players) player.id: player.displayName,
      };

      final playerView = buildPlayerView(
        game,
        mapData.combinedTopology,
        humanPlayerId,
      );
      final shared = buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: connectivity,
        game: game,
        playerId: humanPlayerId,
        currentOrders: orders,
      );

      return DevelopmentPanelProjection(
        game: game,
        humanPlayerId: humanPlayerId,
        shared: shared,
        playerView: playerView,
        provinceDisplayNamesById: provinceDisplayNamesById,
        playerDisplayNamesById: playerDisplayNamesById,
        topology: mapData.combinedTopology,
        tileMapByRegion: mapData.tileMapByRegion,
      );
    });

/// Per-region read model; invalidates when [developmentPanelProjectionProvider]
/// or [currentOrdersProvider] change.
final developmentPanelRegionModelProvider =
    Provider.family<DevelopmentPanelRegionModel?, String>((ref, regionId) {
      final projection = ref.watch(developmentPanelProjectionProvider);
      if (projection == null) {
        return null;
      }
      final orders = ref.watch(currentOrdersProvider);
      return buildDevelopmentPanelRegionModel(
        shared: projection.shared,
        game: projection.game,
        playerId: projection.humanPlayerId,
        regionId: regionId,
        tileMapByRegion: projection.tileMapByRegion,
        currentOrders: orders,
        provinceDisplayNamesById: projection.provinceDisplayNamesById,
        playerDisplayNamesById: projection.playerDisplayNamesById,
        playerView: projection.playerView,
      );
    });
