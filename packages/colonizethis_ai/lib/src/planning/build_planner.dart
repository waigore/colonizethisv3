import 'dart:math' as math;

import 'goal_manager.dart';
import 'planning_imports.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Per-invocation inputs for [pickBuildOrder] (Refs #2521 planner parameter cap).
///
/// Soft-phase NW acquisition wiring (Refs #2847 Phase 3): when
/// [colonialPressureWeight] is non-null the build-pipeline cargo bonus
/// derives its activation gate from `colonialPressureWeight > 0.0`
/// (legacy hard-suppress preserved at `<= 0.0`) and scales the cargo
/// bonus magnitude (the `+2.5` cargo nudge applied to cargo-capable
/// ships in [pickBuildOrder]) by `colonialPressureWeight` clamped to
/// `[0.0, 1.0]`. The weight path is identity-equal to the legacy
/// hard-phase `colonialPressure == true` behaviour at
/// `colonialPressureWeight == 1.0` and identity-equal to
/// `colonialPressure == false` at `colonialPressureWeight == 0.0`,
/// preserving the production build-pipeline contract at the
/// EXPAND→COLONIAL boundary while allowing the curve values from
/// `phase_priority_weights.dart` to ramp the colonial cargo bias
/// continuously across OW counts on the dispatch path.
///
/// When [colonialPressureWeight] is null the legacy boolean resolution
/// runs unchanged: [colonialPressure] alone drives the cargo bonus gate
/// and scale (`true -> 1.0`, `false -> 0.0`).
class BuildPickInput {
  const BuildPickInput({
    required this.buildCandidates,
    required this.cargoPreference,
    this.provincesToVictory = 0,
    this.oldWorldProvincesOwned = 0,
    this.colonialPressure = false,
    this.colonialPressureWeight,
    this.militaryRebuildCrisis = false,
  });

  final List<BuildUnitOrder> buildCandidates;
  final CargoPreference cargoPreference;
  final int provincesToVictory;
  final int oldWorldProvincesOwned;
  final bool colonialPressure;

  /// Optional soft-phase NW acquisition weight in `[0.0, 1.0]` (Refs
  /// #2847 Phase 3 economy build-pick wiring). When supplied this
  /// value takes precedence over [colonialPressure] for both the
  /// cargo-bonus activation gate (`weight > 0.0`) and the bonus
  /// magnitude (cargo bonus scales linearly with the weight). When
  /// `null` the legacy boolean path keyed off [colonialPressure]
  /// runs unchanged.
  final double? colonialPressureWeight;
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
  final colonialPressureWeight = input.colonialPressureWeight;
  // Refs #2847 Phase 3 economy build-pick wiring: derive a single
  // `[0.0, 1.0]` cargo-bonus scale from the optional soft-phase NW
  // acquisition weight. The weight takes precedence over the legacy
  // boolean (`true -> 1.0`, `false -> 0.0`) when supplied so the
  // production dispatch path can ramp the colonial cargo bias
  // continuously across the OW priority curve, while callers that
  // omit the weight (tests, legacy entry points) keep the legacy
  // boolean activation/scale exactly.
  final colonialPressureScale = colonialPressureWeight != null
      ? colonialPressureWeight.clamp(0.0, 1.0).toDouble()
      : (input.colonialPressure ? 1.0 : 0.0);
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
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
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
