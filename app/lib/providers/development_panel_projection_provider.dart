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

/// Game/map/shell inputs that do not depend on draft orders.
class DevelopmentPanelStaticContext {
  const DevelopmentPanelStaticContext({
    required this.game,
    required this.humanPlayerId,
    required this.playerView,
    required this.provinceDisplayNamesById,
    required this.playerDisplayNamesById,
    required this.topology,
    required this.tileMapByRegion,
  });

  final Game game;
  final String humanPlayerId;
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

/// [PlayerView], display-name maps, and map topology — invalidates on game/map/shell
/// changes only (not draft orders).
final developmentPanelStaticContextProvider =
    Provider<DevelopmentPanelStaticContext?>((ref) {
      final game = ref.watch(currentGameProvider);
      if (game == null) {
        return null;
      }
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      if (mapData == null) {
        return null;
      }
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

      return DevelopmentPanelStaticContext(
        game: game,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
        provinceDisplayNamesById: provinceDisplayNamesById,
        playerDisplayNamesById: playerDisplayNamesById,
        topology: mapData.combinedTopology,
        tileMapByRegion: mapData.tileMapByRegion,
      );
    });

/// Idle counts and connectivity slice — invalidates when draft orders change.
final developmentPanelSharedContextProvider =
    Provider<DevelopmentPanelBuildContext?>((ref) {
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      if (staticContext == null) {
        return null;
      }
      final connectivity = ref.watch(developmentPanelConnectivityProvider);
      if (connectivity == null) {
        return null;
      }
      final orders = ref.watch(currentOrdersProvider);
      return buildDevelopmentPanelBuildContextFromConnectivity(
        connectivity: connectivity,
        game: staticContext.game,
        playerId: staticContext.humanPlayerId,
        currentOrders: orders,
      );
    });

/// Combined projection for panel consumers.
final developmentPanelProjectionProvider =
    Provider<DevelopmentPanelProjection?>((ref) {
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      final shared = ref.watch(developmentPanelSharedContextProvider);
      if (staticContext == null || shared == null) {
        return null;
      }
      return DevelopmentPanelProjection(
        game: staticContext.game,
        humanPlayerId: staticContext.humanPlayerId,
        shared: shared,
        playerView: staticContext.playerView,
        provinceDisplayNamesById: staticContext.provinceDisplayNamesById,
        playerDisplayNamesById: staticContext.playerDisplayNamesById,
        topology: staticContext.topology,
        tileMapByRegion: staticContext.tileMapByRegion,
      );
    });

/// Per-region read model; invalidates when static inputs, shared context, or orders change.
final developmentPanelRegionModelProvider =
    Provider.family<DevelopmentPanelRegionModel?, String>((ref, regionId) {
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      final shared = ref.watch(developmentPanelSharedContextProvider);
      if (staticContext == null || shared == null) {
        return null;
      }
      final orders = ref.watch(currentOrdersProvider);
      return buildDevelopmentPanelRegionModel(
        shared: shared,
        game: staticContext.game,
        playerId: staticContext.humanPlayerId,
        regionId: regionId,
        tileMapByRegion: staticContext.tileMapByRegion,
        currentOrders: orders,
        provinceDisplayNamesById: staticContext.provinceDisplayNamesById,
        playerDisplayNamesById: staticContext.playerDisplayNamesById,
        playerView: staticContext.playerView,
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
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      final shared = ref.watch(developmentPanelSharedContextProvider);
      final regionModel = ref.watch(developmentPanelRegionModelProvider(regionId));
      if (staticContext == null || shared == null || regionModel == null) {
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
            game: staticContext.game,
            playerId: staticContext.humanPlayerId,
            currentOrders: orders,
            topology: staticContext.topology,
            tileMapByRegion: staticContext.tileMapByRegion,
            commodityTileKeys: row.tileKeys.toSet(),
            connectedTileKeys: shared.connectedTileKeys,
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
