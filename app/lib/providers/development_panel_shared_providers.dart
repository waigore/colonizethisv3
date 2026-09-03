import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'development_panel_session_cache.dart';
import 'development_panel_session_revision.dart';
import 'development_panel_static_providers.dart';
import 'games_provider.dart';

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
