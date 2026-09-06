import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show DevelopmentPanelAssignRowStateCache;
import 'package:colonizethis_world/colonizethis_world.dart'
    show ConnectivityResult, PlayerView;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/screens/development/development_panel_map_snapshot.dart';
import 'panel_session_revision.dart' show PanelStaticSessionRevision;

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
typedef DevelopmentPanelStaticSessionRevision = PanelStaticSessionRevision;

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
