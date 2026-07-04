// Shared Quick Battle input builders for table-driven scenarios (Refs #3865).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Center-front lane deployment used across resolver and siege scenario suites.
QuickBattleDeployment centerFrontQuickBattleDeployment({
  required List<String> unitIds,
  int cohesion = 3,
  QuickBattleLaneTerrain laneTerrain = QuickBattleLaneTerrain.open,
}) {
  return QuickBattleDeployment(
    groups: [
      QuickBattleGroup(
        lane: QuickBattleLane.center,
        line: QuickBattleLine.front,
        unitIds: unitIds,
        cohesion: cohesion,
      ),
    ],
    laneTerrain: {'center_front': laneTerrain},
  );
}

/// Standard center-front [QuickBattleInput] with tunable regiment counts or ids.
QuickBattleInput centerFrontQuickBattleInput({
  required List<String> attackerUnitIds,
  required List<String> defenderUnitIds,
  required int seed,
  int attackerCohesion = 3,
  int defenderCohesion = 3,
  QuickBattleLaneTerrain attackerLaneTerrain = QuickBattleLaneTerrain.open,
  QuickBattleLaneTerrain defenderLaneTerrain = QuickBattleLaneTerrain.open,
  String attackerFactionId = 'att',
  String defenderFactionId = 'def',
  String provinceId = 'p1',
  String regionId = 'oldWorld',
  int maxRounds = 3,
  int fortLevel = 0,
  String provinceTerrain = 'plains',
  double attackerCavalryShare = 0.0,
  double defenderCavalryShare = 0.0,
  QuickBattleDeployment? attackerDeployment,
  QuickBattleDeployment? defenderDeployment,
}) {
  return QuickBattleInput(
    attackerFactionId: attackerFactionId,
    defenderFactionId: defenderFactionId,
    provinceId: provinceId,
    regionId: regionId,
    fortLevel: fortLevel,
    provinceTerrain: provinceTerrain,
    attackerCavalryShare: attackerCavalryShare,
    defenderCavalryShare: defenderCavalryShare,
    attackerDeployment: attackerDeployment ??
        centerFrontQuickBattleDeployment(
          unitIds: attackerUnitIds,
          cohesion: attackerCohesion,
          laneTerrain: attackerLaneTerrain,
        ),
    defenderDeployment: defenderDeployment ??
        centerFrontQuickBattleDeployment(
          unitIds: defenderUnitIds,
          cohesion: defenderCohesion,
          laneTerrain: defenderLaneTerrain,
        ),
    seed: seed,
    maxRounds: maxRounds,
  );
}

/// Generates sequential unit ids (`prefix0`, `prefix1`, …).
List<String> quickBattleUnitIds(String prefix, int count) =>
    List.generate(count, (i) => '$prefix$i');
