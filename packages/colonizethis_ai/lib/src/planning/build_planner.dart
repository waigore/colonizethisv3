import 'dart:math' as math;

import 'goal_manager.dart';
import 'planning_helpers.dart' show colonialPressureScaleFromWeight;
import 'planning_imports.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

import 'build_planner_input.dart';

export 'build_planner_input.dart';

final _log = packageLogger();

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
  final colonialPressureWeight = input.colonialPressureWeight;
  // Refs #2847 Phase 3 economy build-pick wiring: derive a single
  // `[0.0, 1.0]` cargo-bonus scale from the optional soft-phase NW
  // acquisition weight. The weight takes precedence over the legacy
  // boolean (`true -> 1.0`, `false -> 0.0`) when supplied so the
  // production dispatch path can ramp the colonial cargo bias
  // continuously across the OW priority curve, while callers that
  // omit the weight (tests, legacy entry points) keep the legacy
  // boolean activation/scale exactly.
  final colonialPressureScale = colonialPressureScaleFromWeight(
    colonialPressureWeight: colonialPressureWeight,
    legacyColonialPressureActive: input.colonialPressure,
    clampToUnitInterval: true,
  );
  final colonialPressureActive = colonialPressureScale > 0.0;
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
  // Refs #3793: when civilian scoring is supplied, exclude civilian candidates
  // at or above their GA-tunable per-type `maxCount` ceiling from the build
  // pool so over-building cannot starve military/naval production
  // (SPEC/ai/civilian-build-planner.md § Scoring model — max cap). Military and
  // naval candidates are never filtered here.
  final civilianScoring = input.civilianScoring;
  if (civilianScoring != null) {
    candidates = candidates
        .where(
          (o) =>
              !CivilianEconomyCatalog.byId.containsKey(o.unitType) ||
              !isCivilianBuildAtOrAboveMaxCount(
                o.unitType,
                civilianScoring.countFor(o.unitType),
              ),
        )
        .toList();
    if (candidates.isEmpty) return null;
  }
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  final scores = candidates.map((o) {
    final unitType = o.unitType;
    // Refs #3793: civilian candidates are scored by the additive civilian
    // branch (min-cap hard floor, replacement-urgency soft pull) and never
    // touch the military/naval scoring below, so military/naval scores are
    // unchanged for identical inputs (SPEC AC10). When no civilian scoring
    // input is supplied, civilian candidates fall through to the neutral base
    // score of `1.0`.
    if (CivilianEconomyCatalog.byId.containsKey(unitType)) {
      if (civilianScoring == null) return 1.0;
      // Refs #3793 pool-weight slice: the GA-tunable market-share ceiling
      // (kCivilianBuildPoolWeight, default 1.0) dampens the civilian share of
      // the weighted pool so over-building cannot starve military/naval. The
      // default 1.0 keeps scores byte-identical to the pre-pool-weight path
      // (SPEC/ai/civilian-build-planner.md § Scoring model — pool weight).
      return civilianBuildPooledScore(
        unitType,
        civilianScoring.countFor(unitType),
        phaseName: civilianScoring.phaseName,
        spyDemand: civilianScoring.spyDemand,
        phaseProgress: civilianScoring.phaseProgress,
      );
    }
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
      if (colonialPressureActive && cargoHold > 0) {
        cargoBonus += 2.5 * colonialPressureScale;
      }
    } else if (isRegiment) {
      personalityBonus = thresholds.researchMilitary / 100.0;
    }

    return 1.0 + cargoBonus + militaryBonus + personalityBonus;
  }).toList();

  if (_log.debugEnabled) {
    _log.d(
      'build scores nationId=$nationId '
      'candidateCount=${buildCandidates.length} '
      'scores=$scores',
    );
  }

  return selectWeightedCandidate(
        candidates: candidates,
        scores: scores,
        seed: seed,
      ) ??
      candidates.first;
}
