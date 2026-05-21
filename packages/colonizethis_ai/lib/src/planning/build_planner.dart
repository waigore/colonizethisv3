import 'dart:math' as math;

import 'goal_manager.dart';
import 'planning_imports.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Per-invocation inputs for [pickBuildOrder] (Refs #2521 planner parameter cap).
class BuildPickInput {
  const BuildPickInput({
    required this.buildCandidates,
    required this.cargoPreference,
    this.provincesToVictory = 0,
    this.oldWorldProvincesOwned = 0,
    this.colonialPressure = false,
    this.militaryRebuildCrisis = false,
  });

  final List<BuildUnitOrder> buildCandidates;
  final CargoPreference cargoPreference;
  final int provincesToVictory;
  final int oldWorldProvincesOwned;
  final bool colonialPressure;
  final bool militaryRebuildCrisis;
}

/// Scores build candidates (ships vs regiments) by cargo preference, goal, and personality.
/// Returns one build order via weighted random, or null if list empty. SPEC/ai/economy-planner.md.
BuildUnitOrder? pickBuildOrder({
  required PlannerContext ctx,
  required BuildPickInput input,
}) {
  final primaryGoal = ctx.primaryGoal;
  final config = ctx.config;
  final nationId = ctx.nationId;
  final seed = ctx.seeds.economySeed + 1;
  final buildCandidates = input.buildCandidates;
  final cargoPreference = input.cargoPreference;
  final provincesToVictory = input.provincesToVictory;
  final oldWorldProvincesOwned = input.oldWorldProvincesOwned;
  final colonialPressure = input.colonialPressure;
  final militaryRebuildCrisis = input.militaryRebuildCrisis;
  if (buildCandidates.isEmpty) return null;
  if (militaryRebuildCrisis) {
    final regimentsOnly = buildCandidates
        .where((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType))
        .toList();
    if (regimentsOnly.isNotEmpty) {
      regimentsOnly.sort((a, b) {
        final costA =
            RegimentEconomyCatalog.byId[a.unitType]!.buildTreasuryCost;
        final costB =
            RegimentEconomyCatalog.byId[b.unitType]!.buildTreasuryCost;
        final costCompare = costA.compareTo(costB);
        if (costCompare != 0) return costCompare;
        return a.unitType.compareTo(b.unitType);
      });
      return regimentsOnly.first;
    }
  }
  var candidates = buildCandidates;
  if (isObserverConquestExpansionPressure(oldWorldProvincesOwned) &&
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
        isObserverConquestExpansionPressure(oldWorldProvincesOwned)) {
      militaryBonus += kBuildRegimentBonusWhenStalledExpansion;
      if (militaryRebuildCrisis) {
        militaryBonus += kBuildRegimentBonusWhenZeroRegimentsAtWar;
      }
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
