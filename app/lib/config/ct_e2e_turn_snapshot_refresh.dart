import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../core/services/game_service.dart';
import 'ct_e2e.dart';
import 'ct_e2e_last_panel_snapshot.dart';

/// Refreshes [ctE2eNavalPanelSnapshot] from current game state after turn
/// resolution so fleet E2E loops can short-circuit [openNavalPanel] when world
/// state already shows NW arrival (Refs #2336 Bottleneck 4).
void refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled({
  required Game? game,
  required Orders draftOrders,
  required GameService gameService,
}) {
  if (!kCtE2EEnabled) {
    return;
  }
  if (game == null) {
    return;
  }
  final humanPlayerId = _humanPlayerIdForE2e(game);
  final mapData = gameService.getMapData(game.id);
  updateCtE2eNavalPanelSnapshotIfEnabled(
    CtE2eNavalPanelSnapshot(
      game: game,
      humanPlayerId: humanPlayerId,
      topology: mapData?.combinedTopology ?? const MapTopology(),
      draftOrders: draftOrders,
      tileMapByRegion: mapData?.tileMapByRegion,
      topologyByRegion: mapData?.topologyByRegion,
    ),
  );
}

String _humanPlayerIdForE2e(Game game) {
  for (final p in game.players) {
    if (p.isHuman) {
      return p.id;
    }
  }
  return game.players.first.id;
}
