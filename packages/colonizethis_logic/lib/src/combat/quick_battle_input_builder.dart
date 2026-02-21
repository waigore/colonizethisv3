import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'conflict_detection.dart';

/// Leader combat bonus for a faction. GPs use Player.leaderKey; minors/tribes get 1.0.
double _leaderBonusForFaction(Game game, String factionId) {
  final player = game.playerById(factionId);
  return leaderCombatBonusMultiplier(player?.leaderKey);
}

/// Builds QuickBattleInput from Game and BattleContext. SPEC/program/quick-battle-resolution.
/// Uses simple auto-deploy: all units in CENTER FRONT.
/// Passes leader multipliers from Game players (SPEC/game/leader-bonuses.md).
QuickBattleInput buildQuickBattleInput(
  Game game,
  BattleContext ctx, {
  int seed = 0,
}) {
  final region = ctx.regionId == kRegionOldWorld
      ? game.worldState.oldWorld
      : game.worldState.newWorld;
  final unitsById = {for (final u in region.units) u.id: u};

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
    allAttackerIds.addAll(
      att.unitIds.where((id) => unitsById.containsKey(id)),
    );
  }
  final attGroups = [
    QuickBattleGroup(
      lane: QuickBattleLane.center,
      line: QuickBattleLine.front,
      unitIds: allAttackerIds,
      cohesion: quickBattleMaxCohesion,
    ),
  ];

  final attackerLeaderMult = _leaderBonusForFaction(game, ctx.attackers.first.factionId);
  final defenderLeaderMult = _leaderBonusForFaction(game, ctx.defenderFactionId);

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
    provinceTerrain: ctx.terrain,
    seed: seed,
    maxRounds: quickBattleMaxRounds,
    attackerLeaderMultiplier: attackerLeaderMult,
    defenderLeaderMultiplier: defenderLeaderMult,
  );
}
