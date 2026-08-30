import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentPanelAssignRowStateCache,
        buildLazyDevelopmentPanelAssignRowStateCache,
        buildDevelopmentPanelAssignRowStateCache;
import 'package:colonizethis_world/colonizethis_world.dart'
    show ConnectivityResult, PlayerView, allProvinces, buildPlayerView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

/// Shared Development panel inputs memoized across [DevelopmentScreenBody] rebuilds
/// when game, orders, map data, or shell player context change. Refs #4175 Slice E.
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
typedef DevelopmentPanelStaticContext = ({
  Game game,
  String humanPlayerId,
  PlayerView playerView,
  Map<String, String> provinceDisplayNamesById,
  Map<String, String> playerDisplayNamesById,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
});

/// Connectivity map — invalidates on game/map changes only (not draft orders).
final developmentPanelConnectivityProvider =
    Provider.autoDispose<Map<String, ConnectivityResult>?>((ref) {
      final game = ref.watch(currentGameProvider);
      final mapData = game == null
          ? null
          : ref.watch(gameServiceProvider).getMapData(game.id);
      if (game == null || mapData == null) return null;
      final humanPlayerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      return ctAppPerfSync(
        'developmentPanel.connectivity',
        () => resolveDevelopmentPanelConnectivity(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          topology: mapData.combinedTopology,
          humanPlayerId: humanPlayerId,
        ),
      );
    });

/// [PlayerView], display-name maps, and map topology — invalidates on game/map/shell
/// changes only (not draft orders).
final developmentPanelStaticContextProvider =
    Provider.autoDispose<DevelopmentPanelStaticContext?>((ref) {
      final game = ref.watch(currentGameProvider);
      final mapData = game == null
          ? null
          : ref.watch(gameServiceProvider).getMapData(game.id);
      if (game == null || mapData == null) return null;
      final humanPlayerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      return ctAppPerfSync('developmentPanel.staticContext', () {
        final topology = mapData.combinedTopology;
        return (
          game: game,
          humanPlayerId: humanPlayerId,
          playerView: buildPlayerView(game, topology, humanPlayerId),
          provinceDisplayNamesById: {
            for (final p in allProvinces(game.worldState))
              p.id: p.displayName ?? p.id,
          },
          playerDisplayNamesById: {
            for (final player in game.players) player.id: player.displayName,
          },
          topology: topology,
          tileMapByRegion: mapData.tileMapByRegion,
        );
      });
    });

/// Idle counts and connectivity slice — invalidates when draft orders change.
final developmentPanelSharedContextProvider =
    Provider.autoDispose<DevelopmentPanelBuildContext?>((ref) {
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      final connectivity = ref.watch(developmentPanelConnectivityProvider);
      if (staticContext == null || connectivity == null) return null;
      final orders = ref.watch(currentOrdersProvider);
      return ctAppPerfSync(
        'developmentPanel.sharedContext',
        () => buildDevelopmentPanelBuildContextFromConnectivity(
          connectivity: connectivity,
          game: staticContext.game,
          playerId: staticContext.humanPlayerId,
          currentOrders: orders,
        ),
      );
    });

/// Combined projection for panel consumers.
final developmentPanelProjectionProvider =
    Provider.autoDispose<DevelopmentPanelProjection?>((ref) {
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      final shared = ref.watch(developmentPanelSharedContextProvider);
      if (staticContext == null || shared == null) return null;
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

/// Per-region scopes + extraction — invalidates on game/map/shell only (Slice E).
final developmentPanelRegionScopesProvider =
    Provider.autoDispose.family<DevelopmentPanelRegionScopes?, String>((
      ref,
      regionId,
    ) {
      final ctx = ref.watch(developmentPanelStaticContextProvider);
      final connectivity = ref.watch(developmentPanelConnectivityProvider);
      if (ctx == null || connectivity == null) return null;
      return ctAppPerfSync(
        'developmentPanel.regionScopes.$regionId',
        () => buildDevelopmentPanelRegionScopesForPlayer(
          game: ctx.game,
          playerId: ctx.humanPlayerId,
          regionId: regionId,
          tileMapByRegion: ctx.tileMapByRegion,
          provinceDisplayNamesById: ctx.provinceDisplayNamesById,
          playerDisplayNamesById: ctx.playerDisplayNamesById,
          connectivityByPlayer: connectivity,
          playerView: ctx.playerView,
        ),
      );
    });

/// Per-region read model; invalidates when static inputs, shared context, or orders change.
final developmentPanelRegionModelProvider =
    Provider.autoDispose.family<DevelopmentPanelRegionModel?, String>((
      ref,
      regionId,
    ) {
      final scopes = ref.watch(developmentPanelRegionScopesProvider(regionId));
      final shared = ref.watch(developmentPanelSharedContextProvider);
      final ctx = ref.watch(developmentPanelStaticContextProvider);
      if (scopes == null || shared == null || ctx == null) return null;
      return ctAppPerfSync(
        'developmentPanel.regionModel.$regionId',
        () => composeDevelopmentPanelRegionModel(
          scopes: scopes,
          shared: shared,
          game: ctx.game,
          playerId: ctx.humanPlayerId,
          currentOrders: ref.watch(currentOrdersProvider),
        ),
      );
    });

/// Per-scope assign affordance; lazy per-row resolution (Refs #4687 Slice B).
final developmentPanelAssignRowStateCacheProvider =
    Provider.autoDispose.family<DevelopmentPanelAssignRowStateCache, String>((
      ref,
      regionId,
    ) {
      final ctx = ref.watch(developmentPanelStaticContextProvider);
      final shared = ref.watch(developmentPanelSharedContextProvider);
      final scopes = ref.watch(developmentPanelRegionScopesProvider(regionId));
      if (ctx == null || shared == null || scopes == null) {
        return DevelopmentPanelAssignRowStateCache.empty;
      }
      return ctAppPerfSync(
        'developmentPanel.assignRowCache.$regionId',
        () => buildLazyDevelopmentPanelAssignRowStateCache(
          ownedScopes: scopes.ownedScopes,
          purchasedScopes: scopes.purchasedScopes,
          game: ctx.game,
          playerId: ctx.humanPlayerId,
          currentOrders: ref.watch(currentOrdersProvider),
          topology: ctx.topology,
          tileMapByRegion: ctx.tileMapByRegion,
          connectedTileKeys: shared.connectedTileKeys,
        ),
      );
    });
