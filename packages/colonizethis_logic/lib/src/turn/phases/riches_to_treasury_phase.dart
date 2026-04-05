import 'package:colonizethis_models/colonizethis_models.dart';

import '../../economy/economy_riches_to_treasury.dart';

Game runRichesToTreasuryPhase(Game game) {
  final updatedPlayers = <Player>[];
  final multiplier = game.richesCashMultiplier;

  for (final player in game.players) {
    final result = resolveRichesToTreasury(
      stockpile: player.stockpile,
      richesCashMultiplier: multiplier,
    );
    updatedPlayers.add(
      player.copyWith(
        stockpile: result.stockpile,
        treasury: player.treasury + result.treasuryDelta,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}
