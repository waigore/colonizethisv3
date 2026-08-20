import 'package:colonizethis_models/colonizethis_models.dart';

import 'battle_context.dart';
import 'combat_types.dart';

/// Aggregated land-battle outcome for event emission (Refs #4548).
typedef LandBattleResolutionSummary = ({
  String outcomeName,
  int attackerCasualtyCount,
  int defenderCasualtyCount,
  String? winnerFactionId,
});

/// Derives the four handbook land-battle outcomes from post-resolution state.
String deriveLandBattleOutcomeName({
  required BattleContext ctx,
  required Set<String> allCasualties,
  required List<String> defenderUnitIdsAfterLoop,
  required bool provinceChangedOwner,
}) {
  final attackerUnitIds = ctx.attackers.expand((a) => a.unitIds);
  final attackerSurvivors = attackerUnitIds
      .where((id) => !allCasualties.contains(id))
      .length;
  final defenderSurvivors = defenderUnitIdsAfterLoop
      .where((id) => !allCasualties.contains(id))
      .length;

  if (attackerSurvivors == 0 && defenderSurvivors == 0) {
    return EngagementResult.mutualAnnihilation.name;
  }
  if (attackerSurvivors == 0) {
    return EngagementResult.defenderVictory.name;
  }
  if (defenderSurvivors == 0 || provinceChangedOwner) {
    return EngagementResult.attackerVictory.name;
  }
  return EngagementResult.stalemate.name;
}

String? winnerFactionIdForLandBattleOutcome({
  required String outcomeName,
  required BattleContext ctx,
  required String? survivingAttackerFactionId,
}) {
  return switch (outcomeName) {
    'attackerVictory' =>
      survivingAttackerFactionId ??
          (ctx.attackers.isNotEmpty ? ctx.attackers.first.factionId : null),
    'defenderVictory' => ctx.defenderFactionId,
    _ => null,
  };
}

LandBattleResolutionSummary landBattleSummaryFromAutoResolve({
  required BattleContext ctx,
  required Set<String> allCasualties,
  required int attackerCasualtyCount,
  required int defenderCasualtyCount,
  required List<String> defenderUnitIdsAfterLoop,
  required String? survivingAttackerFactionId,
  required bool provinceChangedOwner,
}) {
  final outcomeName = deriveLandBattleOutcomeName(
    ctx: ctx,
    allCasualties: allCasualties,
    defenderUnitIdsAfterLoop: defenderUnitIdsAfterLoop,
    provinceChangedOwner: provinceChangedOwner,
  );
  return (
    outcomeName: outcomeName,
    attackerCasualtyCount: attackerCasualtyCount,
    defenderCasualtyCount: defenderCasualtyCount,
    winnerFactionId: winnerFactionIdForLandBattleOutcome(
      outcomeName: outcomeName,
      ctx: ctx,
      survivingAttackerFactionId: survivingAttackerFactionId,
    ),
  );
}

LandBattleResolutionSummary landBattleSummaryFromQuickBattle({
  required BattleContext ctx,
  required QuickBattleResult qbResult,
}) {
  final attackerCasualtyCount = qbResult.attackerCasualties.length;
  final defenderCasualtyCount = qbResult.defenderCasualties.length;
  final attackerInitial = ctx.attackers.fold<int>(
    0,
    (sum, side) => sum + side.unitIds.length,
  );
  final defenderInitial = ctx.defenderUnitIds.length;
  final attackerRemaining = attackerInitial - attackerCasualtyCount;
  final defenderRemaining = defenderInitial - defenderCasualtyCount;

  final String outcomeName;
  final String? winnerFactionId;
  switch (qbResult.winner) {
    case QuickBattleWinner.attacker:
      outcomeName = EngagementResult.attackerVictory.name;
      winnerFactionId = ctx.attackers.isNotEmpty
          ? ctx.attackers.first.factionId
          : null;
    case QuickBattleWinner.defender:
      outcomeName = EngagementResult.defenderVictory.name;
      winnerFactionId = ctx.defenderFactionId;
    case QuickBattleWinner.mutualExhaustion:
      if (attackerRemaining <= 0 && defenderRemaining <= 0) {
        outcomeName = EngagementResult.mutualAnnihilation.name;
      } else {
        outcomeName = EngagementResult.stalemate.name;
      }
      winnerFactionId = null;
  }

  return (
    outcomeName: outcomeName,
    attackerCasualtyCount: attackerCasualtyCount,
    defenderCasualtyCount: defenderCasualtyCount,
    winnerFactionId: winnerFactionId,
  );
}
