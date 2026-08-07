/// Applies Quick Battle results to [Game] world state.
///
/// SPEC/program/quick-battle-resolution.md; casualty removal, fort downgrade,
/// ownership transfer, army reconcile, and general medal award.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'battle_context.dart';
import 'combat_resolver_support.dart';
import 'combat_survivor_units.dart';

/// Applies QuickBattleResult to Game: remove casualties, flip province if winner is attacker.
Game applyQuickBattleResultToGame(
  Game game,
  BattleContext ctx,
  QuickBattleResult result,
) {
  final region = game.worldState.regionDataForIdOrThrow(ctx.regionId);
  final casualtySet = {
    ...result.attackerCasualties,
    ...result.defenderCasualties,
  };
  final survivingUnits = unitsExcludingCasualtyIds(
    region.units,
    casualtySet,
  ).toList();

  var provinces = region.provinces;
  if (result.fortDowngradeFromDestroyedEmplaced) {
    provinces = decrementFortLevelForProvinceIdIfPresent(
      provinces,
      ctx.provinceId,
    );
  }

  final newRegion = RegionData(provinces: provinces, units: survivingUnits);
  final newWorldState = game.worldState.updateRegionById(
    ctx.regionId,
    (_) => newRegion,
  );

  var updatedGame = game.withWorldState(newWorldState);

  if (result.provinceFlips &&
      result.winner == QuickBattleWinner.attacker &&
      ctx.attackers.isNotEmpty) {
    final attackerFactionId = ctx.attackers.first.factionId;
    final row = resolveProvinceRowForOwnershipTransfer(
      game.worldState,
      ctx.provinceId,
    );
    final oldOwnerId = row?.province.ownerId ?? ctx.defenderFactionId;
    updatedGame = applyCanonicalSingleProvinceOwnershipTransfer(
      updatedGame,
      targetProvinceId: ctx.provinceId,
      oldOwnerId: oldOwnerId,
      newOwnerId: attackerFactionId,
    );
  }

  updatedGame = updatedGame.copyWith(
    worldState: reconcileArmiesAfterUnitsChanged(
      updatedGame.worldState,
      updatedGame,
    ),
  );

  final winnerFactionId = switch (result.winner) {
    QuickBattleWinner.attacker =>
      ctx.attackers.isNotEmpty ? ctx.attackers.first.factionId : null,
    QuickBattleWinner.defender => ctx.defenderFactionId,
    QuickBattleWinner.mutualExhaustion => null,
  };
  return awardWinningGeneralMedal(updatedGame, ctx, winnerFactionId);
}
