import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_service_provider.dart';
import '../providers/games_provider.dart';
import 'ct_e2e.dart';
import 'ct_e2e_last_panel_snapshot.dart';

/// Refreshes [ctE2eNavalPanelSnapshot] from current game providers after turn
/// resolution so fleet E2E loops can short-circuit [openNavalPanel] when world
/// state already shows NW arrival (Refs #2336 Bottleneck 4).
void refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(WidgetRef ref) {
  if (!kCtE2EEnabled) {
    return;
  }
  final game = ref.read(currentGameProvider);
  if (game == null) {
    return;
  }
  final humanPlayerId = _humanPlayerIdForE2e(game);
  final mapData = ref.read(gameServiceProvider).getMapData(game.id);
  final draftOrders = ref.read(currentOrdersProvider);
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
