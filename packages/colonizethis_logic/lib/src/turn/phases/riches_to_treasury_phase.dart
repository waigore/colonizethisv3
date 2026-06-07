import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../economy/economy_riches_to_treasury.dart';
import '../../economy/world_market/purchased_tile_index.dart';
import '../../economy/world_market/purchased_tile_riches.dart';
import 'package:colonizethis_world/src/world/player_state_pipeline.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

Game runRichesToTreasuryPhase(Game game) {
  final multiplier = game.richesCashMultiplier;

  return game.mapPlayers((player) {
    final result = resolveRichesToTreasury(
      stockpile: player.stockpile,
      richesCashMultiplier: multiplier,
    );
    return player.copyWith(
      stockpile: result.stockpile,
      treasury: player.treasury + result.treasuryDelta,
    );
  });
}

/// Applies purchased-tile riches handoff credits on top of [game] (which is
/// expected to be the post-stockpile-cash-in `Game` returned by
/// [runRichesToTreasuryPhase]). Per `SPEC/game/world-market.md` § First right
/// of refusal § Riches handoff and `SPEC/program/turn-resolution-phase-details.md`
/// § Riches to treasury, this credits the owning Great Power's treasury for
/// every Minor or Tribe tile it has purchased whose tile resource is in the
/// riches set.
///
/// When [tileMapByRegion] is `null` or empty (legacy callers, scripted-test
/// fast paths), the helper is a no-op and [game] is returned unchanged so the
/// existing direct-handler test surface stays byte-stable.
Game applyPurchasedTileRichesHandoff(
  Game game, {
  required Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (tileMapByRegion == null || tileMapByRegion.isEmpty) {
    return game;
  }
  final purchasedTileIndex = PurchasedTileIndex.fromGame(game);
  if (purchasedTileIndex.isEmpty) {
    return game;
  }
  final result = computePurchasedTileRichesCredits(
    game: game,
    tileMapByRegion: tileMapByRegion,
    purchasedTileIndex: purchasedTileIndex,
    richesCashMultiplier: game.richesCashMultiplier,
  );
  if (result.isEmpty || result.treasuryCreditByGpId.isEmpty) {
    return game;
  }
  return game.mapPlayers((player) {
    final delta = result.treasuryCreditByGpId[player.id] ?? 0;
    if (delta <= 0) return player;
    return player.copyWith(treasury: player.treasury + delta);
  });
}

TurnPhaseStepOutcome richesToTreasuryTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final afterStockpile = runRichesToTreasuryPhase(acc.game);
  final afterPurchasedTiles = applyPurchasedTileRichesHandoff(
    afterStockpile,
    tileMapByRegion: config.tileMapByRegion,
  );
  return TurnPhaseStepContinue(acc.copyWith(game: afterPurchasedTiles));
}
