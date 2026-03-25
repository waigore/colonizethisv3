import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/unit_lookup.dart';
import 'battle_general_assignment.dart';
import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';
import 'quick_battle_emplaced_builder.dart';

/// Builds QuickBattleInput from Game and BattleContext. SPEC/program/quick-battle-resolution.
/// Uses simple auto-deploy: all units in CENTER FRONT.
/// Passes leader multipliers from Game players (SPEC/game/leader-bonuses.md).
///
/// When [battleAssignment] is null, assignment is computed with an empty
/// [CombatPhaseGeneralLedger] (isolated battle). Callers in the Combat phase
/// should pass the result of [assignGeneralsForBattleContext] with the phase ledger.
///
/// Primary attacker medals: first entry in [BattleContext.attackers] only
/// (same faction id as [QuickBattleInput.attackerFactionId]).
QuickBattleInput buildQuickBattleInput(
  Game game,
  BattleContext ctx, {
  int seed = 0,
  BattleGeneralAssignment? battleAssignment,
}) {
  final assignment = battleAssignment ??
      assignGeneralsForBattleContext(
        game: game,
        ctx: ctx,
        rng: battleAssignmentRng(game, ctx),
        ledger: CombatPhaseGeneralLedger(),
      );
  final region = ctx.regionId == kRegionOldWorld
      ? game.worldState.oldWorld
      : game.worldState.newWorld;
  final unitsById = unitsByIdFromRegion(region);

  final defGroups = [
    QuickBattleGroup(
      lane: QuickBattleLane.center,
      line: QuickBattleLine.front,
      unitIds: ctx.defenderUnitIds
          .where((id) => unitsById.containsKey(id))
          .toList(),
      cohesion: quickBattleMaxCohesion,
    ),
  ];

  final allAttackerIds = <String>[];
  for (final att in ctx.attackers) {
    allAttackerIds.addAll(att.unitIds.where((id) => unitsById.containsKey(id)));
  }
  final primaryFactionId = ctx.attackers.first.factionId;
  final primaryAssigned =
      assignment.attackerByFactionId[primaryFactionId] ??
          const AssignedGeneralForBattle(generalId: null, medals: 0);
  final attackerGeneralMedals = primaryAssigned.medals;
  final defenderGeneralMedals = assignment.defenderMedals;
  final attGroups = [
    QuickBattleGroup(
      lane: QuickBattleLane.center,
      line: QuickBattleLine.front,
      unitIds: allAttackerIds,
      cohesion: quickBattleMaxCohesion,
    ),
  ];

  final attackerLeaderMult = leaderBonusForFaction(
    game,
    ctx.attackers.first.factionId,
  );
  final defenderLeaderMult = leaderBonusForFaction(game, ctx.defenderFactionId);
  final emplacedGuns = buildQuickBattleEmplacedGuns(game, ctx);
  final attackerCavalryShare = _cavalryShare(allAttackerIds, unitsById);
  final defenderCavalryShare = _cavalryShare(ctx.defenderUnitIds, unitsById);

  return QuickBattleInput(
    attackerFactionId: ctx.attackers.first.factionId,
    defenderFactionId: ctx.defenderFactionId,
    provinceId: ctx.provinceId,
    regionId: ctx.regionId,
    attackerDeployment: QuickBattleDeployment(
      groups: attGroups,
      laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
    ),
    defenderDeployment: QuickBattleDeployment(
      groups: defGroups,
      laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
    ),
    fortLevel: ctx.fortLevel,
    emplacedGuns: emplacedGuns,
    provinceTerrain: ctx.terrain,
    seed: seed,
    maxRounds: quickBattleMaxRounds,
    attackerLeaderMultiplier: attackerLeaderMult,
    defenderLeaderMultiplier: defenderLeaderMult,
    attackerCavalryShare: attackerCavalryShare,
    defenderCavalryShare: defenderCavalryShare,
    attackerGeneralMedals: attackerGeneralMedals,
    defenderGeneralMedals: defenderGeneralMedals,
  );
}

double _cavalryShare(List<String> unitIds, Map<String, Unit> unitsById) {
  if (unitIds.isEmpty) return 0.0;
  var cavalry = 0;
  for (final id in unitIds) {
    final unit = unitsById[id];
    if (unit == null) continue;
    final stats = regimentStatsById(unit.type);
    if (stats != null && stats.isCavalry) cavalry++;
  }
  return cavalry / unitIds.length;
}
