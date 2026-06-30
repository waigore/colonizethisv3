import 'dart:math' as math;

import 'goal_manager.dart';
import 'planning_imports.dart';
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Live-economy enablement flag for the civilian build planner (Refs #3793
/// live-wiring slice, SPEC/ai/civilian-build-planner.md § Live economy wiring).
///
/// Now defaults `true`: the production economy build pass emits and scores
/// civilian `BuildUnitOrder` candidates so the AI replaces and expands its
/// civilian workforce (the original #3793 requirement). The civilian branch is
/// bounded by per-candidate affordability, per-type `maxCount` exclusion, and
/// the `kCivilianBuildPoolWeight` market-share ceiling, and stays deterministic.
/// Tests can still pin the pre-#3793 military+naval path by threading
/// `civilianBuildPlannerEnabled: false` through [runDomainPlannersWithOutcome] /
/// [PlannerContext].
const bool kCivilianBuildPlannerEnabled = true;

/// Builds the per-turn [CivilianBuildScoringInput] for the live economy build
/// pass (Refs #3793 live-wiring slice).
///
/// Returns `null` when [PlannerContext.civilianBuildPlannerEnabled] is `false`,
/// keeping `pickBuildOrder` inert (the civilian branch is skipped and
/// military/naval scoring is byte-identical to the pre-wiring path). When
/// enabled it tallies the active player's owned civilian units per type from
/// [PlannerContext.view] (`ownUnitsById`, filtered to [CivilianEconomyCatalog]
/// types; types with zero owned units are absent from the map) and carries the
/// active [phaseName] and the Spy [spyDemand] signal so the additive civilian
/// scoring branch can apply the min-cap floor, replacement urgency, phase
/// multiplier, and Spy demand boost.
/// The optional [phaseProgress] is the dispatch's continuous
/// `PhasePriorityWeights.newWorldCivilian` weight in `[0,1]` (Refs #3793 slice
/// 8): when supplied it enables the smooth (hysteresis) phase-multiplier ramp
/// in [civilianBuildCandidateScore]; when `null` the discrete per-phase
/// multiplier is used (byte-identical to the pre-slice-8 path).
CivilianBuildScoringInput? buildCivilianBuildScoringInput({
  required PlannerContext ctx,
  required String phaseName,
  required bool spyDemand,
  double? phaseProgress,
}) {
  if (!ctx.civilianBuildPlannerEnabled) return null;
  final counts = <String, int>{};
  for (final unit in ctx.view.ownUnitsById.values) {
    if (CivilianEconomyCatalog.byId.containsKey(unit.type)) {
      counts[unit.type] = (counts[unit.type] ?? 0) + 1;
    }
  }
  return CivilianBuildScoringInput(
    currentCountByType: counts,
    phaseName: phaseName,
    spyDemand: spyDemand,
    phaseProgress: phaseProgress,
  );
}

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
/// Civilian build scoring input for [pickBuildOrder] (Refs #3793,
/// SPEC/ai/civilian-build-planner.md § Scoring model).
///
/// Carries the active player's current count per civilian unit type so the
/// additive civilian scoring branch can apply the GA-tunable min-cap hard
/// floor, replacement-urgency soft pull, and max-cap exclusion. When this
/// input is absent from [BuildPickInput] the civilian branch is inert: civilian
/// candidates (if any are present) keep the neutral base score and
/// military/naval scores are identical to the pre-#3793 implementation
/// (SPEC AC10 — no regression).
class CivilianBuildScoringInput {
  const CivilianBuildScoringInput({
    required this.currentCountByType,
    this.phaseName,
    this.spyDemand = false,
    this.phaseProgress,
  });

  /// Current owned count per civilian unit type id (e.g. `'Builder' → 2`).
  /// Types absent from the map are treated as count `0`.
  final Map<String, int> currentCountByType;

  /// Active observer goal phase as an `ObserverGoalPhase.name` (Refs #3793
  /// slice 3, SPEC § Scoring model — phase multiplier). When `null` the phase
  /// multiplier is neutral (base) for every type, so the scoring branch is
  /// phase-agnostic. EXPAND favors Builder; COLONIAL favors Explorer +
  /// Merchant; DEVELOP favors Engineer + Rail Builder; Spy is phase-flat.
  final String? phaseName;

  /// Spy intelligence/war-demand flag (decision #10): when `true` (the GP is at
  /// war or pursuing a tech-steal posture) the Spy candidate receives the
  /// GA-tunable `kCivilianBuildSpyDemandBoost` on top of its phase-flat
  /// baseline. Has no effect on non-Spy civilians.
  final bool spyDemand;

  /// Optional continuous phase-progress signal in `[0,1]` (Refs #3793 slice 8,
  /// decision #13 — smooth phase weighting / hysteresis). When supplied (the
  /// dispatch's `PhasePriorityWeights.newWorldCivilian`), the phase multiplier
  /// ramps smoothly toward the next phase's profile via
  /// [civilianBuildPhaseMultiplierSmooth] instead of hard-switching at the phase
  /// boundary. When `null` the discrete per-phase multiplier is used
  /// (byte-identical to the pre-slice-8 path).
  final double? phaseProgress;

  /// Current owned count for [unitType] (absent → `0`).
  int countFor(String unitType) => currentCountByType[unitType] ?? 0;
}

class BuildPickInput {
  const BuildPickInput({
    required this.buildCandidates,
    required this.cargoPreference,
    this.provincesToVictory = 0,
    this.oldWorldProvincesOwned = 0,
    this.colonialPressure = false,
    this.colonialPressureWeight,
    this.militaryRebuildCrisis = false,
    this.civilianScoring,
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

  /// Optional civilian build scoring input (Refs #3793). When `null` the
  /// civilian scoring branch is inert and behaviour is identical to the
  /// pre-#3793 implementation. When supplied, civilian candidates are scored
  /// via [civilianBuildCandidateScore] and candidates at or above their
  /// `maxCount` are excluded from the pool.
  final CivilianBuildScoringInput? civilianScoring;
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
