import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_service_provider.dart';
import 'game_summary_support.dart';
import '../features/game/shell_player_context.dart';
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
  return computeGameSummary<TreasurySummary>(
    game: ref.watch(currentGameProvider),
    shell: ref.watch(shellPlayerContextProvider),
    orders: ref.watch(currentOrdersProvider),
    gameService: ref.watch(gameServiceProvider),
    whenNoGame: const TreasurySummary(treasury: 0),
    notDefined: (shell) => shell.treasuryNotDefined,
    whenNotDefined: () => const TreasurySummary(treasury: 0, notDefined: true),
    log: _treasurySummaryLog,
    compute: (context) {
      final game = context.game;
      final player = game.playerById(context.playerId) ?? game.players.first;
      final treasury = player.treasury;
      final orders = context.orders;
      if (!context.hasMapData) {
        return TreasurySummary(treasury: treasury);
      }
      final projected = projectOrderEffects(
        game: game,
        orders: orders,
        topology: context.topology,
        tileMapByRegion: context.tileMapByRegion!,
        playerId: player.id,
      );
      return TreasurySummary(
        treasury: treasury,
        projectedDelta: projected.treasuryDelta,
      );
    },
    onError: (game, playerId) {
      final player = game.playerById(playerId) ?? game.players.first;
      return TreasurySummary(treasury: player.treasury);
    },
  );
});
