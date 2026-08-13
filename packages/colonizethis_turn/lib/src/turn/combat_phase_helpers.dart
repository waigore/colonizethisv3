import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'combat_medal_gain_events.dart';
import 'combat_phase_land_battle_apply.dart';
import 'turn_event_sink.dart';

/// Runs one land battle: applies result (quick battle or auto-resolve), evidence, and dialogue.
Game runOneLandBattle(
  Game state,
  BattleContext ctx,
  CombatMode mode,
  Map<String, double> feedingCoverageByPlayerId,
  int turn,
  int battleIndex,
  int seed,
  CombatPhaseGeneralLedger combatGeneralLedger, {
  TurnEventSink sink = const TurnEventSink(),
}) {
  final gameBeforeBattle = state;
  state = applyLandBattleAttackTreasuryCosts(state, ctx);

  final attackerUnitsTotal = ctx.attackers.fold<int>(
    0,
    (s, a) => s + a.unitIds.length,
  );
  turnLog.i(
    'combat battle_start turn=$turn battleIndex=$battleIndex '
    'regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
    'defenderFactionId=${ctx.defenderFactionId} attackerSides=${ctx.attackers.length} '
    'attackerUnitsTotal=$attackerUnitsTotal mode=${mode.name}',
  );

  final LandBattleApplyOutcome outcome;
  if (mode == CombatMode.quickBattle) {
    outcome = applyQuickBattleLandBattle(
      state,
      ctx,
      turn,
      battleIndex,
      seed,
      combatGeneralLedger,
      sink: sink,
    );
  } else {
    outcome = applyAutoResolveLandBattle(
      state,
      ctx,
      feedingCoverageByPlayerId,
      turn,
      battleIndex,
      seed,
      combatGeneralLedger,
      sink: sink,
    );
  }
  state = outcome.state;
  final winnerId = outcome.winnerId;
  final casualties = outcome.casualties;

  if (sink.hasGameEvent && winnerId != null && ctx.attackers.isNotEmpty) {
    sink.emit(
      CombatResultEvent(
        provinceId: ctx.provinceId,
        attackerId: ctx.attackers.first.factionId,
        defenderId: ctx.defenderFactionId,
        winnerId: winnerId,
        turnNumber: turn,
        casualties: casualties,
      ),
    );
  }
  emitGeneralMedalGainedIfAny(
    gameBefore: gameBeforeBattle,
    gameAfter: state,
    ctx: ctx,
    winnerId: winnerId,
    turn: turn,
    sink: sink,
  );

  return state;
}
