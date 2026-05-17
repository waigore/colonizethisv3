import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Scores build candidates (ships vs regiments) by cargo preference, goal, and personality.
/// Returns one build order via weighted random, or null if list empty. SPEC/ai/economy-planner.md.
BuildUnitOrder? pickBuildOrder({
  required List<BuildUnitOrder> buildCandidates,
  required CargoPreference cargoPreference,
  required StrategicGoal primaryGoal,
  required AIConfig config,
  required int seed,
  required String nationId,
  int provincesToVictory = 0,
  int oldWorldProvincesOwned = 0,
}) {
  if (buildCandidates.isEmpty) return null;
  var candidates = buildCandidates;
  if (oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold &&
      provincesToVictory > kBuildRegimentVictoryPaceThreshold &&
      cargoPreference == CargoPreference.none &&
      (primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend)) {
    final regimentsOnly = candidates
        .where((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType))
        .toList();
    if (regimentsOnly.isNotEmpty) {
      candidates = regimentsOnly;
    }
  }
  final thresholds = getThresholdsForLeader(config.personalityId);
  final scores = candidates.map((o) {
    final unitType = o.unitType;
    final isShip = ShipEconomyCatalog.byId.containsKey(unitType);
    final cargoHold = isShip ? NavalStatsCatalog.get(unitType).cargoHold : 0;
    final isRegiment = RegimentEconomyCatalog.byId.containsKey(unitType);

    double cargoBonus = 0.0;
    if (isShip && cargoHold > 0) {
      switch (cargoPreference) {
        case CargoPreference.strongCargo:
          cargoBonus = 2.0;
          break;
        case CargoPreference.preferCargo:
          cargoBonus = 1.0;
          break;
        case CargoPreference.none:
          break;
      }
    }

    double militaryBonus = 0.0;
    if (isRegiment &&
        oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold) {
      militaryBonus += kBuildRegimentBonusWhenStalledExpansion;
    }
    if (primaryGoal == StrategicGoal.conquer ||
        primaryGoal == StrategicGoal.defend) {
      if (isRegiment) {
        militaryBonus = math.max(militaryBonus, 1.0);
        if (provincesToVictory > kBuildRegimentVictoryPaceThreshold) {
          militaryBonus += kBuildRegimentBonusWhenBehindVictoryPace;
        }
      } else if (isShip && cargoHold == 0) {
        militaryBonus = 1.0;
      }
    }

    double personalityBonus = 0.0;
    if (isShip) {
      personalityBonus = thresholds.researchNaval / 100.0;
    } else if (isRegiment) {
      personalityBonus = thresholds.researchMilitary / 100.0;
    }

    return 1.0 + cargoBonus + militaryBonus + personalityBonus;
  }).toList();

  _log.d(
    'build scores nationId=$nationId '
    'candidateCount=${buildCandidates.length} '
    'scores=$scores',
  );

  final idx = pickWeightedIndex(scores, seed);
  if (idx == null) return candidates.first;
  return candidates[idx];
}
