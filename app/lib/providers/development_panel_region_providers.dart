import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentPanelAssignRowStateCache,
        buildLazyDevelopmentPanelAssignRowStateCache;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/screens/development/development_panel_map_snapshot.dart';
import 'development_panel_session_cache.dart';
import 'development_panel_session_revision.dart';
import 'development_panel_shared_providers.dart';
import 'development_panel_static_providers.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

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
