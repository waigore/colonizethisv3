import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_service/try_get_game_map_data.dart';
import '../features/game/widgets/diplomacy/diplomacy_panel_rows_builder.dart';
import '../features/game/widgets/diplomacy/diplomacy_panel_rows.dart';
import '../features/game/widgets/shell/shell_player_context.dart';
import 'panel_session_revision.dart'
    show panelOrdersRevision, panelWorldRevision;
import 'game_service_provider.dart';
import 'games_provider.dart';

typedef DiplomacyPanelSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
  String humanPlayerId,
  int ordersRevision,
  int topologyRevision,
});

class DiplomacyPanelSessionCacheState {
  const DiplomacyPanelSessionCacheState({
    this.revision,
    this.rows,
  });

  final DiplomacyPanelSessionRevision? revision;
  final List<DiplomacyRowData>? rows;
}

/// Cross-visit cache for `GAME30001` row projections (Refs #4688 Slice 5).
class DiplomacyPanelSessionCache {
  DiplomacyPanelSessionCacheState state = const DiplomacyPanelSessionCacheState();

  void reset() {
    state = const DiplomacyPanelSessionCacheState();
  }
}

final diplomacyPanelSessionCacheProvider = Provider<DiplomacyPanelSessionCache>(
  (ref) => DiplomacyPanelSessionCache(),
);

DiplomacyPanelSessionRevision diplomacyPanelSessionRevision({
  required Game game,
  required String humanPlayerId,
  required Orders orders,
  required MapTopology topology,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
    humanPlayerId: humanPlayerId,
    ordersRevision: panelOrdersRevision(orders),
    topologyRevision: Object.hashAll(topology.nodes.map((n) => n.id)),
  );
}

List<DiplomacyRowData> resolveDiplomacyPanelRows({
  required DiplomacyPanelSessionCache cache,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Orders orders,
}) {
  final revision = diplomacyPanelSessionRevision(
    game: game,
    humanPlayerId: humanPlayerId,
    orders: orders,
    topology: topology,
  );
  if (cache.state.revision == revision && cache.state.rows != null) {
    return cache.state.rows!;
  }
  final rows = ctAppPerfSync(
    'diplomacy.rowsBuild',
    () => buildDiplomacyRows(game, topology, humanPlayerId, orders),
  );
  cache.state = DiplomacyPanelSessionCacheState(
    revision: revision,
    rows: rows,
  );
  return rows;
}

/// Session-cached diplomacy rows for `GAME30001` reopen (Refs #4688 Slice 5).
final diplomacyPanelRowsProvider =
    Provider.autoDispose<List<DiplomacyRowData>?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final orders = ref.watch(currentOrdersProvider);
  final mapData = tryGetGameMapData(
    () => ref.watch(gameServiceProvider).getMapData(game.id),
  );
  final topology = mapData?.combinedTopology ?? const MapTopology();

  final humanPlayerId = resolveShellPanelPlayerId(
    ref.watch(shellPlayerContextProvider),
    game,
  );
  return resolveDiplomacyPanelRows(
    cache: ref.read(diplomacyPanelSessionCacheProvider),
    game: game,
    topology: topology,
    humanPlayerId: humanPlayerId,
    orders: orders,
  );
});
