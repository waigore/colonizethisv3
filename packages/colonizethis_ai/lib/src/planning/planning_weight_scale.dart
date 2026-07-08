/// Soft-phase weight scaling and list-equality helpers (Refs #3941).
///
/// Canonical homes for `repo.ai_dedup_weight_scale_clamp`,
/// `repo.ai_dedup_colonial_pressure_scale`, and `repo.ai_dedup_list_equals`.
library;

/// Scales [baseConstant] by [weight] clamped to `[0.0, 1.0]`, returning the
/// rounded integer result.
///
/// Shared body of the soft-phase weight-scaling resolvers (Refs #2847 Phase 3
/// consumer wiring). Matches the prior inline idiom exactly:
///
///   - `weight <= 0.0` returns `0` (no bonus / floor applied).
///   - `weight >= 1.0` is clamped to `1.0`, returning `baseConstant` exactly.
///   - Intermediate weights return `round(baseConstant × weight)`.
///
/// The `<= 0.0` guard and `> 1.0` clamp boundaries are preserved verbatim from
/// the call sites so rounding semantics are identical.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
int scaleWeightedBonus(double weight, int baseConstant) {
  if (weight <= 0.0) {
    return 0;
  }
  final clamped = clampPhaseWeightUpperUnit(weight);
  return (baseConstant * clamped).round();
}

/// Upper-clamps a soft-phase priority [weight] to the unit ceiling `1.0`,
/// returning [weight] unchanged when it is already `<= 1.0`.
///
/// Single source of truth for the `weight > 1.0 ? 1.0 : weight` upper-clamp
/// idiom duplicated across the soft-phase weight-scaling sites (Refs #3717
/// phase weight-clamp dedup): [scaleWeightedBonus] above,
/// `conquestOldWorldArmyMoveScaledBonus` (`conquest_planner.dart`), and the
/// economy threshold-cap resolvers
/// `economyColonialPressureCivilianWorkThresholdCap` /
/// `economyColonialPressureBuildOrderThresholdCap`
/// (`phase_planner_economy_filter.dart`). Each call site already guards the
/// lower bound with its own `weight <= 0.0` early-out, so this helper only
/// caps the ceiling — byte-identical to the inline ternary it replaces. It
/// deliberately keeps the `> 1.0 ? 1.0 :` ternary rather than substituting
/// `weight.clamp(0.0, 1.0)`, which would alter results for the negative
/// inputs the callers' guards exclude.
///
/// Pure and deterministic — identical inputs always yield identical results
/// (Refs #2509 Must-have #7).
double clampPhaseWeightUpperUnit(double weight) => weight > 1.0 ? 1.0 : weight;

/// Default diplomatic candidate scoring baseline before order-type bonuses apply.
const int kDiplomaticDefaultBaseScore = 50;

/// Resolves colonial-pressure weight/scale from an optional soft-phase weight,
/// or maps [legacyColonialPressureActive] to `1.0` / `0.0` when the weight is
/// null.
///
/// When [clampToUnitInterval] is `true`, non-null weights are clamped to
/// `[0.0, 1.0]` (Refs #3822 build-pick cargo scale). When `false`, the resolved
/// weight is returned unchanged for downstream `scaleWeightedBonus` callers.
double colonialPressureScaleFromWeight({
  required double? colonialPressureWeight,
  required bool legacyColonialPressureActive,
  bool clampToUnitInterval = false,
}) {
  if (colonialPressureWeight != null) {
    return clampToUnitInterval
        ? colonialPressureWeight.clamp(0.0, 1.0).toDouble()
        : colonialPressureWeight;
  }
  return legacyColonialPressureActive ? 1.0 : 0.0;
}

/// Element-wise equality for sorted string-id lists in phase planner value types.
bool planningListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
