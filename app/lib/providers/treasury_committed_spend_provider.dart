import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import '../features/game/widgets/shell/treasury_committed_spend.dart';
import 'game_service_provider.dart';
import 'game_summary_support.dart';
import 'games_provider.dart';

final _treasuryCommittedSpendLog = packageLogger('treasury_committed_spend');

/// Non-zero committed gold families for the map treasury popover (Refs #4560).
final treasuryCommittedSpendProvider =
    Provider<TreasuryCommittedSpendSnapshot>((ref) {
  return computeGameSummary<TreasuryCommittedSpendSnapshot>(
    game: ref.watch(currentGameProvider),
    shell: ref.watch(shellPlayerContextProvider),
    orders: ref.watch(currentOrdersProvider),
    gameService: ref.watch(gameServiceProvider),
    whenNoGame: const TreasuryCommittedSpendSnapshot(),
    notDefined: (shell) => shell.treasuryNotDefined,
    whenNotDefined: () => const TreasuryCommittedSpendSnapshot(),
    log: _treasuryCommittedSpendLog,
    compute: (context) {
      final Player player =
          context.game.playerById(context.playerId) ??
          context.game.players.first;
      return computeTreasuryCommittedSpend(
        game: context.game,
        player: player,
        orders: context.orders,
      );
    },
    onError: (Game game, String playerId) =>
        const TreasuryCommittedSpendSnapshot(),
  );
});
