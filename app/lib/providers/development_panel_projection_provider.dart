import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentPanelAssignRowStateCache,
        buildLazyDevelopmentPanelAssignRowStateCache;
import 'package:colonizethis_world/colonizethis_world.dart'
    show ConnectivityResult, PlayerView, allProvinces, buildPlayerView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/screens/development/development_panel_map_snapshot.dart';
import '../features/game/widgets/shell/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';
import 'panel_session_revision.dart';

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

/// Static inputs for Development panel session reuse (game/map/fog only).
typedef DevelopmentPanelStaticSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
});

/// Full session revision including draft orders (Refs #4687 Slice C).
typedef DevelopmentPanelFullSessionRevision = ({
  DevelopmentPanelStaticSessionRevision staticRevision,
  int ordersRevision,
});

/// Cross-visit cache for expensive Development panel projections.
///
/// Survives `autoDispose` provider teardown when the player pops `GAME80001`
/// and re-opens within the same turn with unchanged inputs. Refs #4687 Slice C.
class DevelopmentPanelSessionCacheState {
  const DevelopmentPanelSessionCacheState({
    this.staticRevision,
    this.connectivity,
    this.staticContext,
    this.regionScopesByRegion = const {},
    this.ordersRevision,
    this.sharedContext,
    this.assignRowCacheByRegion = const {},
    this.mapSnapshotsByRegion = const {},
  });

  final DevelopmentPanelStaticSessionRevision? staticRevision;
  final Map<String, ConnectivityResult>? connectivity;
  final DevelopmentPanelStaticContext? staticContext;
  final Map<String, DevelopmentPanelRegionScopes> regionScopesByRegion;

  final int? ordersRevision;
  final DevelopmentPanelBuildContext? sharedContext;
  final Map<String, DevelopmentPanelAssignRowStateCache> assignRowCacheByRegion;
  final Map<String, DevelopmentPanelMapSnapshot> mapSnapshotsByRegion;
}

/// Mutable cross-visit cache holder (not a Notifier — stores run during provider build).
class DevelopmentPanelSessionCache {
  DevelopmentPanelSessionCacheState state = const DevelopmentPanelSessionCacheState();

  void _clearStaticIfMismatch(DevelopmentPanelStaticSessionRevision revision) {
    if (state.staticRevision == revision) return;
    state = DevelopmentPanelSessionCacheState(staticRevision: revision);
  }

  void storeConnectivity({
    required DevelopmentPanelStaticSessionRevision revision,
    required Map<String, ConnectivityResult> connectivity,
  }) {
    _clearStaticIfMismatch(revision);
    state = DevelopmentPanelSessionCacheState(
      staticRevision: revision,
      connectivity: connectivity,
      staticContext: state.staticContext,
      regionScopesByRegion: state.regionScopesByRegion,
      ordersRevision: state.ordersRevision,
      sharedContext: state.sharedContext,
      assignRowCacheByRegion: state.assignRowCacheByRegion,
      mapSnapshotsByRegion: state.mapSnapshotsByRegion,
    );
  }

  void storeStaticContext({
    required DevelopmentPanelStaticSessionRevision revision,
    required DevelopmentPanelStaticContext staticContext,
  }) {
    _clearStaticIfMismatch(revision);
    state = DevelopmentPanelSessionCacheState(
      staticRevision: revision,
      connectivity: state.connectivity,
      staticContext: staticContext,
      regionScopesByRegion: state.regionScopesByRegion,
      ordersRevision: state.ordersRevision,
      sharedContext: state.sharedContext,
      assignRowCacheByRegion: state.assignRowCacheByRegion,
      mapSnapshotsByRegion: state.mapSnapshotsByRegion,
    );
  }

  void storeRegionScopes({
    required DevelopmentPanelStaticSessionRevision revision,
    required String regionId,
    required DevelopmentPanelRegionScopes scopes,
  }) {
    _clearStaticIfMismatch(revision);
    state = DevelopmentPanelSessionCacheState(
      staticRevision: revision,
      connectivity: state.connectivity,
      staticContext: state.staticContext,
      regionScopesByRegion: {
        ...state.regionScopesByRegion,
        regionId: scopes,
      },
      ordersRevision: state.ordersRevision,
      sharedContext: state.sharedContext,
      assignRowCacheByRegion: state.assignRowCacheByRegion,
      mapSnapshotsByRegion: state.mapSnapshotsByRegion,
    );
  }

  void storeSharedContext({
    required DevelopmentPanelFullSessionRevision revision,
    required DevelopmentPanelBuildContext sharedContext,
  }) {
    _clearStaticIfMismatch(revision.staticRevision);
    final ordersChanged = state.ordersRevision != revision.ordersRevision;
    state = DevelopmentPanelSessionCacheState(
      staticRevision: revision.staticRevision,
      connectivity: state.connectivity,
      staticContext: state.staticContext,
      regionScopesByRegion: state.regionScopesByRegion,
      ordersRevision: revision.ordersRevision,
      sharedContext: sharedContext,
      assignRowCacheByRegion:
          ordersChanged ? const {} : state.assignRowCacheByRegion,
      mapSnapshotsByRegion: state.mapSnapshotsByRegion,
    );
  }

  void storeAssignRowCache({
    required DevelopmentPanelFullSessionRevision revision,
    required String regionId,
    required DevelopmentPanelAssignRowStateCache cache,
  }) {
    _clearStaticIfMismatch(revision.staticRevision);
    state = DevelopmentPanelSessionCacheState(
      staticRevision: revision.staticRevision,
      connectivity: state.connectivity,
      staticContext: state.staticContext,
      regionScopesByRegion: state.regionScopesByRegion,
      ordersRevision: revision.ordersRevision,
      sharedContext: state.sharedContext,
      assignRowCacheByRegion: {
        ...state.assignRowCacheByRegion,
        regionId: cache,
      },
      mapSnapshotsByRegion: state.mapSnapshotsByRegion,
    );
  }

  void storeMapSnapshot({
    required DevelopmentPanelStaticSessionRevision revision,
    required String regionId,
    required DevelopmentPanelMapSnapshot snapshot,
  }) {
    _clearStaticIfMismatch(revision);
    state = DevelopmentPanelSessionCacheState(
      staticRevision: revision,
      connectivity: state.connectivity,
      staticContext: state.staticContext,
      regionScopesByRegion: state.regionScopesByRegion,
      ordersRevision: state.ordersRevision,
      sharedContext: state.sharedContext,
      assignRowCacheByRegion: state.assignRowCacheByRegion,
      mapSnapshotsByRegion: {
        ...state.mapSnapshotsByRegion,
        regionId: snapshot,
      },
    );
  }

  /// Drops all cached projections when the active game session ends.
  void reset() {
    state = const DevelopmentPanelSessionCacheState();
  }
}

final developmentPanelSessionCacheProvider =
    Provider<DevelopmentPanelSessionCache>(
  (ref) => DevelopmentPanelSessionCache(),
);

int developmentPanelWorldRevision(Game game) => panelWorldRevision(game);

DevelopmentPanelStaticSessionRevision developmentPanelStaticSessionRevision({
  required Game game,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: developmentPanelWorldRevision(game),
  );
}

int developmentPanelOrdersRevision(Orders orders) =>
    panelOrdersRevision(orders);

DevelopmentPanelFullSessionRevision developmentPanelFullSessionRevision({
  required Game game,
  required Orders orders,
}) {
  return (
    staticRevision: developmentPanelStaticSessionRevision(game: game),
    ordersRevision: developmentPanelOrdersRevision(orders),
  );
}

/// Connectivity map — invalidates on game/map changes only (not draft orders).
final developmentPanelConnectivityProvider =
    Provider.autoDispose<Map<String, ConnectivityResult>?>((ref) {
      final game = ref.watch(currentGameProvider);
      final mapData = game == null
          ? null
          : ref.watch(gameServiceProvider).getMapData(game.id);
      if (game == null || mapData == null) return null;
      final staticRevision = developmentPanelStaticSessionRevision(game: game);
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      if (session.staticRevision == staticRevision &&
          session.connectivity != null) {
        return session.connectivity;
      }
      final humanPlayerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      final connectivity = ctAppPerfSync(
        'developmentPanel.connectivity',
        () => resolveDevelopmentPanelConnectivity(
          game: game,
          tileMapByRegion: mapData.tileMapByRegion,
          topology: mapData.combinedTopology,
          humanPlayerId: humanPlayerId,
        ),
      );
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeConnectivity(revision: staticRevision, connectivity: connectivity);
      return connectivity;
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
      final staticRevision = developmentPanelStaticSessionRevision(game: game);
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      if (session.staticRevision == staticRevision &&
          session.staticContext != null) {
        return session.staticContext;
      }
      final humanPlayerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      final staticContext = ctAppPerfSync('developmentPanel.staticContext', () {
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
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeStaticContext(
            revision: staticRevision,
            staticContext: staticContext,
          );
      return staticContext;
    });

/// Idle counts and connectivity slice — invalidates when draft orders change.
final developmentPanelSharedContextProvider =
    Provider.autoDispose<DevelopmentPanelBuildContext?>((ref) {
      final staticContext = ref.watch(developmentPanelStaticContextProvider);
      final connectivity = ref.watch(developmentPanelConnectivityProvider);
      if (staticContext == null || connectivity == null) return null;
      final orders = ref.watch(currentOrdersProvider);
      final fullRevision = developmentPanelFullSessionRevision(
        game: staticContext.game,
        orders: orders,
      );
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      if (session.staticRevision == fullRevision.staticRevision &&
          session.ordersRevision == fullRevision.ordersRevision &&
          session.sharedContext != null) {
        return session.sharedContext;
      }
      final shared = ctAppPerfSync(
        'developmentPanel.sharedContext',
        () => buildDevelopmentPanelBuildContextFromConnectivity(
          connectivity: connectivity,
          game: staticContext.game,
          playerId: staticContext.humanPlayerId,
          currentOrders: orders,
        ),
      );
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeSharedContext(revision: fullRevision, sharedContext: shared);
      return shared;
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
      final staticRevision = developmentPanelStaticSessionRevision(
        game: ctx.game,
      );
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      final cached = session.regionScopesByRegion[regionId];
      if (session.staticRevision == staticRevision && cached != null) {
        return cached;
      }
      final scopes = ctAppPerfSync(
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
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeRegionScopes(
            revision: staticRevision,
            regionId: regionId,
            scopes: scopes,
          );
      return scopes;
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
      final orders = ref.watch(currentOrdersProvider);
      final fullRevision = developmentPanelFullSessionRevision(
        game: ctx.game,
        orders: orders,
      );
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      final cached = session.assignRowCacheByRegion[regionId];
      if (session.staticRevision == fullRevision.staticRevision &&
          session.ordersRevision == fullRevision.ordersRevision &&
          cached != null) {
        return cached;
      }
      final cache = ctAppPerfSync(
        'developmentPanel.assignRowCache.$regionId',
        () => buildLazyDevelopmentPanelAssignRowStateCache(
          ownedScopes: scopes.ownedScopes,
          purchasedScopes: scopes.purchasedScopes,
          game: ctx.game,
          playerId: ctx.humanPlayerId,
          currentOrders: orders,
          topology: ctx.topology,
          tileMapByRegion: ctx.tileMapByRegion,
          connectedTileKeys: shared.connectedTileKeys,
        ),
      );
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeAssignRowCache(
            revision: fullRevision,
            regionId: regionId,
            cache: cache,
          );
      return cache;
    });

/// Per-region minimap view-data; invalidates on game/map/fog only (Refs #4687 Slice D).
final developmentPanelMapSnapshotProvider =
    Provider.autoDispose.family<DevelopmentPanelMapSnapshot?, String>((
      ref,
      regionId,
    ) {
      final ctx = ref.watch(developmentPanelStaticContextProvider);
      if (ctx == null) return null;
      final mapData = ref.read(gameServiceProvider).getMapData(ctx.game.id);
      if (mapData == null) return null;
      final staticRevision = developmentPanelStaticSessionRevision(
        game: ctx.game,
      );
      final session = ref.read(developmentPanelSessionCacheProvider).state;
      final cached = session.mapSnapshotsByRegion[regionId];
      if (session.staticRevision == staticRevision && cached != null) {
        return cached;
      }
      final snapshot = ctAppPerfSync(
        'developmentPanel.mapSnapshot.$regionId',
        () => buildDevelopmentPanelMapSnapshot(
          game: ctx.game,
          humanPlayerId: ctx.humanPlayerId,
          regionId: regionId,
          playerView: ctx.playerView,
          tileMapByRegion: ctx.tileMapByRegion,
          topologyByRegion: mapData.topologyByRegion,
        ),
      );
      ref
          .read(developmentPanelSessionCacheProvider)
          .storeMapSnapshot(
            revision: staticRevision,
            regionId: regionId,
            snapshot: snapshot,
          );
      return snapshot;
    });
