import 'dart:math' as math;

import 'goal_manager.dart';
import 'planning_imports.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Scores build candidates (ships vs regiments) by cargo preference, goal, and personality.
/// Returns one build order via weighted random, or null if list empty. SPEC/ai/economy-planner.md.
BuildUnitOrder? pickBuildOrder({
  required PlannerContext ctx,
  required List<BuildUnitOrder> buildCandidates,
  required CargoPreference cargoPreference,
  int provincesToVictory = 0,
  int oldWorldProvincesOwned = 0,
  bool colonialPressure = false,
  int? seedOverride,
}) {
  final primaryGoal = ctx.primaryGoal;
  final config = ctx.config;
  final nationId = ctx.nationId;
  final seed = seedOverride ?? ctx.seeds.economySeed;
  if (buildCandidates.isEmpty) return null;
  var candidates = buildCandidates;
  if (oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold &&
      provincesToVictory > kBuildRegimentVictoryPaceThreshold &&
      cargoPreference == CargoPreference.none) {
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
      if (colonialPressure && cargoHold > 0) {
        cargoBonus += 2.5;
      }
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

  return selectWeightedCandidate(
        candidates: candidates,
        scores: scores,
        seed: seed,
      ) ??
      candidates.first;
}
