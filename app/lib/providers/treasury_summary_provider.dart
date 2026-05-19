import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

final _treasurySummaryLog = packageLogger('treasury_summary');

class TreasurySummary {
  const TreasurySummary({
    required this.treasury,
    this.projectedDelta,
    this.notDefined = false,
  });

  final int treasury;
  final int? projectedDelta;
  final bool notDefined;
}

final treasurySummaryProvider = Provider<TreasurySummary>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) {
    return const TreasurySummary(treasury: 0);
  }

  final shell = ref.watch(shellPlayerContextProvider);
  if (shell.treasuryNotDefined) {
    return const TreasurySummary(treasury: 0, notDefined: true);
  }

  final playerId = shell.viewingPlayerId ?? shell.mapPlayerIdFor(game);
  final player =
      game.players.where((p) => p.id == playerId).firstOrNull ??
      game.players.first;
  final treasury = player.treasury;
  final orders = ref.watch(currentOrdersProvider);

  try {
    final service = ref.watch(gameServiceProvider);
    final mapData = service.getMapData(game.id);
    final tileMaps = mapData?.tileMapByRegion;
    if (tileMaps == null || tileMaps.isEmpty) {
      return TreasurySummary(treasury: treasury);
    }
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final projected = projectOrderEffects(
      game: game,
      orders: orders,
      topology: topology,
      tileMapByRegion: tileMaps,
      playerId: player.id,
    );
    return TreasurySummary(
      treasury: treasury,
      projectedDelta: projected.treasuryDelta,
    );
  } catch (e, stackTrace) {
    _treasurySummaryLog.w(
      'summary_failed gameId=${game.id}',
      error: e,
      stackTrace: stackTrace,
    );
    return TreasurySummary(treasury: treasury);
  }
});
