import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'battle_general_assignment.dart';
import 'combat_resolver_multi_attacker_loop.dart';
import 'combat_resolver_post_battle.dart';
import 'conflict_detection.dart';

export 'combat_constants.dart';
export 'combat_engagement.dart' show resolveEngagement;
export 'combat_resolver_support.dart'
    show awardWinningGeneralMedal, winningGeneralIdForBattle;
export 'combat_types.dart';

/// Resolves one battle context and returns updated Game state.
/// SPEC/program/combat-resolution.md.
Game resolveBattleContext(
  Game game,
  BattleContext ctx, {
  Map<String, double> feedingCoverageByPlayerId = const {},
  CombatPhaseGeneralLedger? combatGeneralLedger,
}) {
  final ledger = combatGeneralLedger ?? CombatPhaseGeneralLedger();
  final region = game.worldState.regionDataForIdOrThrow(ctx.regionId);

  final unitsById = unitsByIdFromRegion(region);
  final provinceOwnerAtBattleStart =
      provinceOwnerIdAtBattleStart(game, ctx) ?? ctx.defenderFactionId;

  final loop = runLandBattleMultiAttackerLoop(
    game: game,
    ctx: ctx,
    unitsById: unitsById,
    provinceOwnerAtBattleStart: provinceOwnerAtBattleStart,
    feedingCoverageByPlayerId: feedingCoverageByPlayerId,
  );

  final post = buildPostBattleRegion(
    region: region,
    ctx: ctx,
    allCasualties: loop.allCasualties,
    unitsById: unitsById,
    defenderFactionId: ctx.defenderFactionId,
    survivingAttackerFactionId: loop.survivingAttackerFactionId,
    defenderUnitIds: loop.defenderUnitIds,
  );

  final resolved = buildResolvedBattleGame(
    game: game,
    ctx: ctx,
    post: post,
    survivingAttackerFactionId: loop.survivingAttackerFactionId,
    generalsById: loop.generalsById,
    ledger: ledger,
    provinceOwnerAtBattleStart: provinceOwnerAtBattleStart,
  );

  var ownerAfter = '';
  final row = resolveProvinceRowForOwnershipTransfer(
    resolved.worldState,
    ctx.provinceId,
  );
  if (row != null) {
    final regionState = resolved.worldState.regionDataForIdOrThrow(
      ctx.regionId,
    );
    for (final p in regionState.provinces) {
      if (p.id == row.canonicalProvinceId) {
        ownerAfter = p.ownerId ?? '';
        break;
      }
    }
  }
  combatLog.i(
    'combat battle_apply regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
    'mode=autoResolve provinceFlipped=${post.provinceChangedOwner} '
    'casualtiesApplied=${loop.allCasualties.length} ownerAfter=$ownerAfter',
  );

  return resolved;
}
