import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';
import 'battle_general_assignment.dart';
import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';
import 'quick_battle_emplaced_builder.dart';

/// Builds QuickBattleInput from Game and BattleContext. SPEC/program/quick-battle-resolution.
/// Uses simple auto-deploy: all units in CENTER FRONT.
/// Passes leader multipliers from Game players (SPEC/game/leader-bonuses.md).
///
/// Primary attacker medals: first entry in [BattleContext.attackers] only
/// (same faction id as [QuickBattleInput.attackerFactionId]).
QuickBattleInput buildQuickBattleInput(
  Game game,
  BattleContext ctx, {
  int seed = 0,
  BattleGeneralAssignment? battleAssignment,
}) {
  final region = game.worldState.regionDataForIdOrThrow(ctx.regionId);
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
  final attackerGeneralMedals = battleAssignment != null
      ? (battleAssignment
                .attackerByFactionId[ctx.attackers.first.factionId]
                ?.medals ??
            (ctx.attackers.isNotEmpty ? ctx.attackers.first.generalMedals : 0))
      : (ctx.attackers.isNotEmpty ? ctx.attackers.first.generalMedals : 0);
  final defenderGeneralMedals =
      battleAssignment?.defenderMedals ?? ctx.defenderGeneralMedals;
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
