import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'combat_phase_land_battle_outcome.dart';
import 'turn_event_sink.dart';

/// Outcome of applying one land battle resolution path (quick or auto-resolve).
typedef LandBattleApplyOutcome = ({
  Game state,
  String outcomeName,
  int attackerCasualtyCount,
  int defenderCasualtyCount,
  String? winnerId,
});

LandBattleApplyOutcome applyQuickBattleLandBattle(
  Game state,
  BattleContext ctx,
  int turn,
  int battleIndex,
  int seed,
  CombatPhaseGeneralLedger combatGeneralLedger, {
  required TurnEventSink sink,
}) {
  final input = buildQuickBattleInput(
    state,
    ctx,
    seed: state.worldState.turnState.turnNumber,
  );
  final qbResult = resolveQuickBattle(input);
  state = applyQuickBattleResultToGame(state, ctx, qbResult);
  recordAttackCommandersForResolvedBattle(ctx, null, combatGeneralLedger);
  final qbFlipped =
      qbResult.provinceFlips &&
      qbResult.winner == QuickBattleWinner.attacker &&
      ctx.attackers.isNotEmpty;
  turnLog.i(
    'combat battle_apply regionId=${ctx.regionId} provinceId=${ctx.provinceId} '
    'mode=quickBattle winner=${qbResult.winner.name} provinceFlipped=$qbFlipped '
    'attCasualties=${qbResult.attackerCasualties.length} '
    'defCasualties=${qbResult.defenderCasualties.length}',
  );

  final summary = landBattleSummaryFromQuickBattle(ctx: ctx, qbResult: qbResult);
  final winnerId = summary.winnerFactionId;

  if (qbResult.winner == QuickBattleWinner.attacker &&
      qbResult.provinceFlips &&
      ctx.attackers.isNotEmpty) {
    final victorId = ctx.attackers.first.factionId;
    state = appendLandBattleVictoryEvidence(
      state,
      victorId,
      ctx.defenderFactionId,
      turn,
    );
    emitLandBattleDialogue(
      state,
      victorId,
      ctx.defenderFactionId,
      ctx.provinceId,
      turn,
      battleIndex,
      seed,
      sink,
    );
  } else {
    final victorId = qbResult.winner == QuickBattleWinner.defender
        ? ctx.defenderFactionId
        : (qbResult.provinceFlips && ctx.attackers.isNotEmpty
              ? ctx.attackers.first.factionId
              : null);
    final loserId = victorId == ctx.defenderFactionId && ctx.attackers.isNotEmpty
        ? ctx.attackers.first.factionId
        : (victorId != null ? ctx.defenderFactionId : null);
    if (victorId != null && loserId != null) {
      emitLandBattleDialogue(
        state,
        victorId,
        loserId,
        ctx.provinceId,
        turn,
        battleIndex,
        seed,
        sink,
      );
    }
  }

  return (
    state: state,
    outcomeName: summary.outcomeName,
    attackerCasualtyCount: summary.attackerCasualtyCount,
    defenderCasualtyCount: summary.defenderCasualtyCount,
    winnerId: winnerId,
  );
}

LandBattleApplyOutcome applyAutoResolveLandBattle(
  Game state,
  BattleContext ctx,
  Map<String, double> feedingCoverageByPlayerId,
  int turn,
  int battleIndex,
  int seed,
  CombatPhaseGeneralLedger combatGeneralLedger, {
  required TurnEventSink sink,
}) {
  final resolved = resolveBattleContextWithSummary(
    state,
    ctx,
    feedingCoverageByPlayerId: feedingCoverageByPlayerId,
    combatGeneralLedger: combatGeneralLedger,
  );
  state = resolved.game;
  final summary = resolved.summary;
  final winnerId = summary.winnerFactionId;
  final victorId = winnerId;

  if (victorId != null && victorId != ctx.defenderFactionId) {
    state = appendLandBattleVictoryEvidence(
      state,
      victorId,
      ctx.defenderFactionId,
      turn,
    );
  }
  final effectiveVictorId = victorId ?? ctx.defenderFactionId;
  final effectiveLoserId = victorId == ctx.defenderFactionId && ctx.attackers.isNotEmpty
      ? ctx.attackers.first.factionId
      : ctx.defenderFactionId;
  emitLandBattleDialogue(
    state,
    effectiveVictorId,
    effectiveLoserId,
    ctx.provinceId,
    turn,
    battleIndex,
    seed,
    sink,
  );

  return (
    state: state,
    outcomeName: summary.outcomeName,
    attackerCasualtyCount: summary.attackerCasualtyCount,
    defenderCasualtyCount: summary.defenderCasualtyCount,
    winnerId: winnerId,
  );
}
