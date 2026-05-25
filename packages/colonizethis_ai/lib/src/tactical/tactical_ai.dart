import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Tactical (Quick Battle) decisions for full AI. SPEC/ai/ai-architecture.md,
/// SPEC/program/ai-systems-impl.md.
///
/// Returns CP-based actions for one round for the AI side. Deterministic given
/// [input] and [tacticalSeed]. Uses input state (our vs enemy strength, terrain,
/// cohesion) to choose actions per spec: Volley Fire/Defend when outmatched or
/// holding key lanes; Maneuver/Fall Back when damaged; Assault/Charge when
/// enemy disrupted and terrain favorable.
QuickBattleRoundActions decideQuickBattleActions({
  required QuickBattleInput input,
  required String nationId,
  required AIConfig config,
  required int tacticalSeed,
}) {
  final rng = math.Random(tacticalSeed);
  final ourDeploy = nationId == input.attackerFactionId
      ? input.attackerDeployment
      : input.defenderDeployment;
  final enemyDeploy = nationId == input.attackerFactionId
      ? input.defenderDeployment
      : input.attackerDeployment;
  final ourMult = nationId == input.attackerFactionId
      ? input.attackerLeaderMultiplier
      : input.defenderLeaderMultiplier;
  final enemyMult = nationId == input.attackerFactionId
      ? input.defenderLeaderMultiplier
      : input.attackerLeaderMultiplier;

  final ourStrength =
      _effectiveStrength(ourDeploy.groups, ourDeploy.laneTerrain) * ourMult;
  final enemyStrength =
      _effectiveStrength(enemyDeploy.groups, enemyDeploy.laneTerrain) *
      enemyMult;
  final outmatched = ourStrength > 0 && enemyStrength >= ourStrength * 1.15;
  final holdingCenter = _hasGroupInLane(
    ourDeploy.groups,
    QuickBattleLane.center,
  );
  final weHaveDamaged = _hasDamagedGroups(ourDeploy.groups);
  final enemyDisrupted =
      enemyStrength <= ourStrength * 0.7 ||
      _hasDamagedGroups(enemyDeploy.groups);
  final terrainFavorable = _terrainFavorableForUs(ourDeploy, enemyDeploy);

  // SPEC: Maneuver / Fall Back to rotate damaged units (prioritize over holding).
  if (weHaveDamaged) {
    final options = [
      [QuickBattleAction.maneuver],
      [QuickBattleAction.fallBackRefuseFlank],
      [QuickBattleAction.volleyFire, QuickBattleAction.maneuver],
    ];
    return QuickBattleRoundActions(
      actions: options[rng.nextInt(options.length)],
    );
  }

  // SPEC: Assault / Charge when enemy lane is disrupted and terrain is favorable.
  if (enemyDisrupted && terrainFavorable) {
    final options = [
      [QuickBattleAction.assaultCharge],
      [QuickBattleAction.volleyFire, QuickBattleAction.assaultCharge],
    ];
    return QuickBattleRoundActions(
      actions: options[rng.nextInt(options.length)],
    );
  }

  // SPEC: Volley Fire / Defend when outmatched or holding key lanes (especially center).
  if (outmatched || holdingCenter) {
    final options = [
      [QuickBattleAction.volleyFire],
      [QuickBattleAction.defendEntrench],
      [QuickBattleAction.volleyFire, QuickBattleAction.defendEntrench],
    ];
    return QuickBattleRoundActions(
      actions: options[rng.nextInt(options.length)],
    );
  }

  // Default: mix of volley/defend/maneuver/assault by seed.
  final strategies = [
    [QuickBattleAction.volleyFire],
    [QuickBattleAction.defendEntrench],
    [QuickBattleAction.volleyFire, QuickBattleAction.maneuver],
    [QuickBattleAction.assaultCharge],
  ];
  final idx = rng.nextInt(strategies.length);
  return QuickBattleRoundActions(actions: strategies[idx]);
}

/// Effective strength for groups; mirrors resolver formula for consistency.
double _effectiveStrength(
  List<QuickBattleGroup> groups,
  Map<String, QuickBattleLaneTerrain> laneTerrain,
) {
  var total = 0.0;
  for (final g in groups) {
    if (g.unitIds.isEmpty || g.cohesion <= 0) continue;
    final cohesionScale = g.cohesion / quickBattleMaxCohesion;
    final terrainKey = '${g.lane.name}_${g.line.name}';
    final terr = laneTerrain[terrainKey] ?? QuickBattleLaneTerrain.open;
    var mod = 1.0;
    switch (terr) {
      case QuickBattleLaneTerrain.hill:
      case QuickBattleLaneTerrain.town:
        mod = 1.1;
        break;
      case QuickBattleLaneTerrain.woods:
        mod = 0.95;
        break;
      case QuickBattleLaneTerrain.swamp:
        mod = 0.8;
        break;
      case QuickBattleLaneTerrain.open:
        break;
    }
    total += g.unitIds.length * cohesionScale * mod;
  }
  return total;
}

bool _hasGroupInLane(List<QuickBattleGroup> groups, QuickBattleLane lane) {
  return groups.any((g) => g.lane == lane && g.unitIds.isNotEmpty);
}

bool _hasDamagedGroups(List<QuickBattleGroup> groups) {
  return groups.any(
    (g) => g.unitIds.isNotEmpty && g.cohesion < quickBattleMaxCohesion,
  );
}

/// True if our deployment has better terrain (good lanes) than enemy or we hold good terrain.
bool _terrainFavorableForUs(
  QuickBattleDeployment ourDeploy,
  QuickBattleDeployment enemyDeploy,
) {
  final ourGood = _countGoodTerrainLanes(ourDeploy.laneTerrain);
  final ourSwamp = _countSwampLanes(ourDeploy.laneTerrain);
  final enemyGood = _countGoodTerrainLanes(enemyDeploy.laneTerrain);
  final enemySwamp = _countSwampLanes(enemyDeploy.laneTerrain);
  if (ourSwamp > 0 && ourGood == 0) return false;
  return ourGood >= enemyGood || enemySwamp > ourSwamp;
}

int _countGoodTerrainLanes(Map<String, QuickBattleLaneTerrain> laneTerrain) {
  var n = 0;
  for (final t in laneTerrain.values) {
    if (t == QuickBattleLaneTerrain.hill ||
        t == QuickBattleLaneTerrain.town ||
        t == QuickBattleLaneTerrain.woods) {
      n++;
    }
  }
  return n;
}

int _countSwampLanes(Map<String, QuickBattleLaneTerrain> laneTerrain) {
  return laneTerrain.values
      .where((t) => t == QuickBattleLaneTerrain.swamp)
      .length;
}
