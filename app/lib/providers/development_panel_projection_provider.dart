import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show DevelopmentAssignRowState, resolveDevelopmentAssignRowState;
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

/// Stable cache key for per-scope improvable commodity assign affordance.
String developmentPanelAssignRowStateKey(String scopeKey, String commodityId) =>
    '$scopeKey|$commodityId';

/// Per-scope assign affordance + material-shortage flags for one region tab.
///
/// Memoized across highlight-only tab rebuilds so Show-tile [setState] does not
/// re-run [resolveDevelopmentAssignRowState] for every improvable row.
class DevelopmentPanelAssignRowStateCache {
  const DevelopmentPanelAssignRowStateCache({
    required this.byScopeCommodityKey,
    required this.materialShortageCommodityIds,
  });

  final Map<String, DevelopmentAssignRowState> byScopeCommodityKey;
  final Set<String> materialShortageCommodityIds;
}

final developmentPanelAssignRowStateCacheProvider =
    Provider.family<DevelopmentPanelAssignRowStateCache, String>((ref, regionId) {
      final projection = ref.watch(developmentPanelProjectionProvider);
      final regionModel = ref.watch(developmentPanelRegionModelProvider(regionId));
      if (projection == null || regionModel == null) {
        return const DevelopmentPanelAssignRowStateCache(
          byScopeCommodityKey: {},
          materialShortageCommodityIds: {},
        );
      }
      final orders = ref.watch(currentOrdersProvider);
      final byKey = <String, DevelopmentAssignRowState>{};
      final shortages = <String>{};
      for (final scope in [
        ...regionModel.ownedScopes,
        ...regionModel.purchasedScopes,
      ]) {
        for (final row in scope.improvableCommodities) {
          final state = resolveDevelopmentAssignRowState(
            game: projection.game,
            playerId: projection.humanPlayerId,
            currentOrders: orders,
            topology: projection.topology,
            tileMapByRegion: projection.tileMapByRegion,
            commodityTileKeys: row.tileKeys.toSet(),
            connectedTileKeys: projection.shared.connectedTileKeys,
          );
          byKey[developmentPanelAssignRowStateKey(scope.scopeKey, row.commodityId)] =
              state;
          if (state.disabledReason == 'Insufficient materials') {
            shortages.add(row.commodityId);
          }
        }
      }
      return DevelopmentPanelAssignRowStateCache(
        byScopeCommodityKey: byKey,
        materialShortageCommodityIds: shortages,
      );
    });

/// Material-shortage flags per region — derived from assign affordance cache.
final developmentPanelMaterialShortageProvider =
    Provider.family<Set<String>, String>((ref, regionId) {
      return ref
          .watch(developmentPanelAssignRowStateCacheProvider(regionId))
          .materialShortageCommodityIds;
    });
