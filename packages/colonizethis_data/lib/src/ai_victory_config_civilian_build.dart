/// Civilian-build planner victory-config constants and helpers.
///
/// Extracted from the victory-config kitchen sink so topical ownership stays
/// clear (SPEC/ai/civilian-build-planner.md; Refs #4072). Public API remains
/// available via `ai_victory_config.dart` and the package barrel.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_economy.dart' show unlockingTechByCivilianId;

// ---------------------------------------------------------------------------
// Civilian build planner — scoring model (Refs #3793).
// GA-tunable parameters for the additive civilian build scoring branch in
// `pickBuildOrder` (SPEC/ai/civilian-build-planner.md § Scoring model). No
// planner magic numbers: the build planner reads only the constants/helpers
// declared here. Phase multipliers, Spy intelligence/war-demand boost, and the
// shared paper ledger are deferred to a later #3793 slice.
// ---------------------------------------------------------------------------

/// Base score for a civilian build candidate before any multiplier
/// (`base × minCapBoost × replacementUrgency`). Sized at `1.0` so a civilian at
/// or above its `targetCount` competes on the same `1.0` footing as the
/// military/naval baseline (`1.0 + bonuses`).
const double kCivilianBuildBaseScore = 1.0;

/// Hard-floor multiplier applied to a civilian build candidate whose current
/// count is strictly below its per-type `minCount` (SPEC § Scoring model — min
/// cap). Sized far above the military/naval bonus envelope (cargo/military
/// bonuses sum to well under `20`) so a below-min civilian dominates the
/// weighted build pool.
const double kCivilianBuildMinCapScoreBoost = 50.0;

/// Replacement-urgency factor: while `minCount <= currentCount < targetCount`,
/// a civilian candidate score is multiplied by
/// `1 + kCivilianBuildReplacementUrgencyFactor × (targetCount − currentCount)`
/// (SPEC § Scoring model — replacement urgency). `0.5` lifts a single-unit
/// deficit by `+50%` without reaching the hard-floor boost.
const double kCivilianBuildReplacementUrgencyFactor = 0.5;

/// Per-type hard minimum count (GA-tunable floor). Below this count the
/// candidate receives [kCivilianBuildMinCapScoreBoost]. Types absent from the
/// map default to `0` (no floor).
const Map<String, int> kCivilianBuildMinCountByType = {
  kUnitTypeBuilder: 2,
  kUnitTypeExplorer: 1,
  kUnitTypeEngineer: 1,
  kUnitTypeSpy: 0,
  kUnitTypeMerchant: 0,
  kUnitTypeRailBuilder: 0,
};

/// Per-type soft target count (GA-tunable). While at or above `minCount` but
/// below `targetCount`, replacement urgency applies. Starting types seed their
/// starting allotment (Explorer 2, Builder 2, Engineer 1); other types default
/// to their `minCount`.
const Map<String, int> kCivilianBuildTargetCountByType = {
  kUnitTypeBuilder: 2,
  kUnitTypeExplorer: 2,
  kUnitTypeEngineer: 1,
  kUnitTypeSpy: 0,
  kUnitTypeMerchant: 0,
  kUnitTypeRailBuilder: 0,
};

/// Per-type hard maximum count (GA-tunable ceiling). A candidate at or above
/// this count is excluded from the build pool (SPEC § Scoring model — max cap)
/// so civilian over-building cannot starve military/naval production. Types
/// absent from the map have no ceiling.
const Map<String, int> kCivilianBuildMaxCountByType = {
  kUnitTypeBuilder: 6,
  kUnitTypeExplorer: 4,
  kUnitTypeEngineer: 4,
  kUnitTypeMerchant: 4,
  kUnitTypeRailBuilder: 4,
};

/// Per-type hard minimum count for [unitType] (defaults to `0`).
int civilianBuildMinCount(String unitType) =>
    kCivilianBuildMinCountByType[unitType] ?? 0;

/// Per-type soft target count for [unitType] (defaults to its `minCount`).
int civilianBuildTargetCount(String unitType) =>
    kCivilianBuildTargetCountByType[unitType] ??
    civilianBuildMinCount(unitType);

/// Per-type hard maximum count for [unitType]; `null` means no ceiling.
int? civilianBuildMaxCount(String unitType) =>
    kCivilianBuildMaxCountByType[unitType];

/// True when [currentCount] of [unitType] is at or above its GA-tunable
/// `maxCount` ceiling, so the candidate is excluded from the build pool
/// (SPEC/ai/civilian-build-planner.md § Scoring model — max cap). Types with no
/// ceiling are never excluded.
bool isCivilianBuildAtOrAboveMaxCount(String unitType, int currentCount) {
  final max = civilianBuildMaxCount(unitType);
  if (max == null) return false;
  return currentCount >= max;
}

// ---------------------------------------------------------------------------
// Civilian build planner — phase priority + Spy demand (Refs #3793 slice 3).
// GA-tunable per-phase, per-type build priority multipliers and the Spy
// intelligence/war-demand boost (SPEC/ai/civilian-build-planner.md § Scoring
// model — phase multiplier / Spy demand). The build planner reads only the
// constants/helpers declared here (no planner magic numbers).
// ---------------------------------------------------------------------------

/// Phase keys for [kCivilianBuildPhaseMultiplierByPhaseType]. These MUST match
/// `ObserverGoalPhase.<value>.name` in `colonizethis_ai`; the AI build planner
/// passes `phase.name`. The contract is locked by an `colonizethis_ai` test
/// (`ObserverGoalPhase.expand.name == kCivilianBuildPhaseExpand`, etc.) so a
/// rename in either package is caught. `colonizethis_data` cannot depend on
/// `colonizethis_ai`, so the key is the stable enum name string.
const String kCivilianBuildPhaseExpand = 'expand';
const String kCivilianBuildPhaseColonialLite = 'colonialLite';
const String kCivilianBuildPhaseColonial = 'colonial';
const String kCivilianBuildPhaseDevelop = 'develop';

/// Neutral per-phase multiplier (no phase preference for the type).
const double kCivilianBuildPhaseMultiplierBase = 1.0;

/// Multiplier for a civilian type favored by the active phase
/// (SPEC § Scoring model — phase multiplier). Sized above
/// [kCivilianBuildPhaseMultiplierBase] so a phase-favored civilian outscores
/// a same-count, non-favored civilian, while remaining well below the min-cap
/// hard floor so phase preference never overrides a below-min replacement.
const double kCivilianBuildPhaseMultiplierFavored = 2.0;

/// Per-phase, per-type civilian build priority multiplier
/// (SPEC § Scoring model — phase multiplier): EXPAND favors Builder; COLONIAL
/// favors Explorer + Merchant; DEVELOP favors Engineer + Rail Builder.
/// COLONIAL-lite mirrors EXPAND (still OW-expansion biased). Spy is intentionally
/// absent — it is phase-flat ([kCivilianBuildSpyPhaseFlatMultiplier], decision
/// #10). Phases/types absent from the map default to
/// [kCivilianBuildPhaseMultiplierBase].
const Map<String, Map<String, double>>
kCivilianBuildPhaseMultiplierByPhaseType = {
  kCivilianBuildPhaseExpand: {
    kUnitTypeBuilder: kCivilianBuildPhaseMultiplierFavored,
  },
  kCivilianBuildPhaseColonialLite: {
    kUnitTypeBuilder: kCivilianBuildPhaseMultiplierFavored,
  },
  kCivilianBuildPhaseColonial: {
    kUnitTypeExplorer: kCivilianBuildPhaseMultiplierFavored,
    kUnitTypeMerchant: kCivilianBuildPhaseMultiplierFavored,
  },
  kCivilianBuildPhaseDevelop: {
    kUnitTypeEngineer: kCivilianBuildPhaseMultiplierFavored,
    kUnitTypeRailBuilder: kCivilianBuildPhaseMultiplierFavored,
  },
};

/// Phase-flat Spy build multiplier (decision #10): identical across every
/// phase. Spy build priority does not follow the economic phase model; it is
/// driven by [kCivilianBuildSpyDemandBoost] instead.
const double kCivilianBuildSpyPhaseFlatMultiplier = 1.0;

/// Spy intelligence/war-demand boost (decision #10): applied on top of the
/// phase-flat baseline when the GP is at war or pursuing a tech-steal posture.
const double kCivilianBuildSpyDemandBoost = 2.0;

/// GA-tunable Spy floor (decision #10, default `0`): mirrors
/// `kCivilianBuildMinCountByType[kUnitTypeSpy]`. Below this count the Spy gets
/// the standard min-cap hard floor; the demand boost applies independently.
const int kCivilianBuildMinSpies = 0;

/// GA-tunable minimum unlocked-tech lead a rival Great Power must hold over the
/// active Great Power for the active GP to be considered "pursuing a tech-steal
/// posture" (decision #10, SPEC/ai/civilian-build-planner.md § Live economy
/// wiring). When the most-advanced rival GP's unlocked-tech count exceeds the
/// active GP's by at least this many techs, the Spy demand boost
/// ([kCivilianBuildSpyDemandBoost]) applies even at peace (passive RP posture).
/// Default `1` (any tech deficit qualifies); a higher value restricts the
/// posture to GPs that are further behind.
const int kCivilianBuildSpyTechStealDeficit = 1;

/// Whether the active Great Power is "pursuing a tech-steal posture"
/// (decision #10) given its own unlocked-tech count [ownUnlockedTechCount] and
/// the maximum unlocked-tech count among rival Great Powers
/// [maxRivalUnlockedTechCount].
///
/// Returns `true` when
/// `maxRivalUnlockedTechCount - ownUnlockedTechCount >= deficit` (default
/// [kCivilianBuildSpyTechStealDeficit]). Pure and deterministic: a fixed pair of
/// counts always yields the same result. The caller computes the counts from
/// `Player.techUnlocked` (the AI planner derives them via
/// `isPursuingTechStealPosture`).
bool isCivilianBuildSpyTechStealPosture({
  required int ownUnlockedTechCount,
  required int maxRivalUnlockedTechCount,
  int deficit = kCivilianBuildSpyTechStealDeficit,
}) => maxRivalUnlockedTechCount - ownUnlockedTechCount >= deficit;

/// Per-phase, per-type civilian build priority multiplier for [unitType] in the
/// phase identified by [phaseName] (an `ObserverGoalPhase.name`). Spy is always
/// phase-flat ([kCivilianBuildSpyPhaseFlatMultiplier]); for other types a null
/// or unknown [phaseName], or a type the phase does not favor, yields
/// [kCivilianBuildPhaseMultiplierBase].
double civilianBuildPhaseMultiplier(String unitType, String? phaseName) {
  if (unitType == kUnitTypeSpy) return kCivilianBuildSpyPhaseFlatMultiplier;
  if (phaseName == null) return kCivilianBuildPhaseMultiplierBase;
  final byType = kCivilianBuildPhaseMultiplierByPhaseType[phaseName];
  if (byType == null) return kCivilianBuildPhaseMultiplierBase;
  return byType[unitType] ?? kCivilianBuildPhaseMultiplierBase;
}

// ---------------------------------------------------------------------------
// Civilian build planner — smooth phase weighting / hysteresis (Refs #3793
// slice 8, design decision #13). SPEC/ai/civilian-build-planner.md § Scoring
// model — phase multiplier. The discrete per-phase multipliers above hard-
// switch a type from favored (2.0) to base (1.0) at a phase boundary, which can
// oscillate when the dispatched phase flips back and forth across a boundary.
// The smooth variant instead ramps continuously between the active phase's
// discrete multiplier and the next phase's discrete multiplier using a runtime
// `phaseProgress` signal in `[0,1]` (the dispatch's
// `PhasePriorityWeights.newWorldCivilian`, itself a continuous ramp across the
// Old World province count). The ramp is opt-in: callers that pass a `null`
// `phaseProgress` keep the discrete multiplier exactly (byte-identical), so a
// caller can pin the discrete-multiplier path even though the live wiring
// (`kCivilianBuildPlannerEnabled`) is enabled by default.
// ---------------------------------------------------------------------------

/// Canonical "next" civilian-build phase for the smooth phase-multiplier ramp
/// (Refs #3793 slice 8). The civilian phase progression toward which each phase
/// ramps is: EXPAND → COLONIAL, COLONIAL-lite → COLONIAL, COLONIAL → DEVELOP,
/// DEVELOP → DEVELOP (terminal). EXPAND and COLONIAL-lite share the same
/// Builder-favored discrete profile, so both ramp toward COLONIAL (the next
/// distinct-favored phase). An unknown phase name is treated as terminal
/// (returns itself), so its ramp is a no-op and the discrete base applies.
String nextCivilianBuildPhaseName(String phaseName) {
  switch (phaseName) {
    case kCivilianBuildPhaseExpand:
    case kCivilianBuildPhaseColonialLite:
      return kCivilianBuildPhaseColonial;
    case kCivilianBuildPhaseColonial:
      return kCivilianBuildPhaseDevelop;
    case kCivilianBuildPhaseDevelop:
      return kCivilianBuildPhaseDevelop;
    default:
      return phaseName;
  }
}

/// Smooth (hysteresis) per-phase, per-type civilian build multiplier for
/// [unitType] in [phaseName], linearly interpolated toward the
/// [nextCivilianBuildPhaseName] profile by [phaseProgress] (clamped to
/// `[0,1]`; Refs #3793 slice 8, SPEC § Scoring model — phase multiplier).
///
/// Returns `current + (next − current) × clamp(phaseProgress, 0, 1)` where
/// `current = civilianBuildPhaseMultiplier(unitType, phaseName)` and
/// `next = civilianBuildPhaseMultiplier(unitType, nextCivilianBuildPhaseName(
/// phaseName))`. At `phaseProgress == 0.0` the result equals the discrete
/// current-phase multiplier (no ramp); as `phaseProgress` rises toward `1.0`
/// the multiplier blends toward the next phase's favored/base profile, so a
/// type favored only in the next phase grows in and a type favored only in the
/// current phase fades out continuously across the boundary.
///
/// Spy is always phase-flat ([kCivilianBuildSpyPhaseFlatMultiplier]) — the ramp
/// never moves it (current == next == flat). A `null` [phaseName] yields the
/// neutral base for every non-Spy type (no phase context to ramp from).
double civilianBuildPhaseMultiplierSmooth(
  String unitType,
  String? phaseName,
  double phaseProgress,
) {
  if (unitType == kUnitTypeSpy) return kCivilianBuildSpyPhaseFlatMultiplier;
  if (phaseName == null) return kCivilianBuildPhaseMultiplierBase;
  final p = phaseProgress.clamp(0.0, 1.0).toDouble();
  final current = civilianBuildPhaseMultiplier(unitType, phaseName);
  final next = civilianBuildPhaseMultiplier(
    unitType,
    nextCivilianBuildPhaseName(phaseName),
  );
  return current + (next - current) * p;
}

/// Additive civilian build candidate score for [unitType] given [currentCount]
/// owned (SPEC/ai/civilian-build-planner.md § Scoring model). Returns
/// `effectiveBase × minCapBoost × replacementUrgency`, where
/// `effectiveBase = base × phaseMultiplier[type] × demandBoost`:
///
/// - **Phase multiplier:** [civilianBuildPhaseMultiplier] for [phaseName]
///   (Spy is phase-flat). When [phaseName] is `null` the multiplier is the
///   neutral base, so legacy callers are unaffected. When [phaseProgress] is
///   non-null the smooth (hysteresis) ramp
///   [civilianBuildPhaseMultiplierSmooth] is used instead (Refs #3793 slice 8):
///   the multiplier blends continuously toward the next phase's profile by
///   `phaseProgress ∈ [0,1]`. A `null` [phaseProgress] keeps the discrete
///   multiplier exactly (byte-identical to the pre-slice-8 path).
/// - **Spy demand boost:** when [unitType] is Spy and [spyDemand] is `true`
///   (GP at war or pursuing a tech-steal posture), multiply by
///   [kCivilianBuildSpyDemandBoost]; otherwise `1.0`.
/// - **Min cap (hard floor):** when `currentCount < minCount`, multiply by
///   [kCivilianBuildMinCapScoreBoost].
/// - **Replacement urgency (soft pull):** while
///   `minCount <= currentCount < targetCount`, multiply by
///   `1 + kCivilianBuildReplacementUrgencyFactor × (targetCount − currentCount)`.
/// - At or above `targetCount`, the multiplier is `1.0` (effective base only).
///
/// The caller is responsible for excluding candidates at or above `maxCount`
/// via [isCivilianBuildAtOrAboveMaxCount].
double civilianBuildCandidateScore(
  String unitType,
  int currentCount, {
  String? phaseName,
  bool spyDemand = false,
  double? phaseProgress,
}) {
  final phaseMultiplier = phaseProgress == null
      ? civilianBuildPhaseMultiplier(unitType, phaseName)
      : civilianBuildPhaseMultiplierSmooth(unitType, phaseName, phaseProgress);
  final demandBoost = (unitType == kUnitTypeSpy && spyDemand)
      ? kCivilianBuildSpyDemandBoost
      : 1.0;
  final effectiveBase = kCivilianBuildBaseScore * phaseMultiplier * demandBoost;
  final minCount = civilianBuildMinCount(unitType);
  if (currentCount < minCount) {
    return effectiveBase * kCivilianBuildMinCapScoreBoost;
  }
  final targetCount = civilianBuildTargetCount(unitType);
  if (currentCount < targetCount) {
    final deficit = targetCount - currentCount;
    return effectiveBase *
        (1.0 + kCivilianBuildReplacementUrgencyFactor * deficit);
  }
  return effectiveBase;
}

/// Civilian-build pool weight (market-share ceiling), GA-tunable in the
/// inclusive range `[0.0, 1.0]` (SPEC/ai/civilian-build-planner.md § Scoring
/// model — pool weight, design decision #8).
///
/// A single shared scalar applied to every civilian candidate's pooled build
/// score. Because the same scalar dampens all civilian types equally it lowers
/// the civilian share of the weighted `pickBuildOrder` pool relative to the
/// untouched military/naval scores — so civilian over-building cannot starve
/// military/naval production — without changing the relative ordering among
/// civilian candidates. Default `1.0` keeps civilian scores byte-identical to
/// the pre-pool-weight path (no live change; the live civilian build pass is
/// itself gated by `kCivilianBuildPlannerEnabled`).
const double kCivilianBuildPoolWeight = 1.0;

/// Civilian build candidate score after the GA-tunable pool-weight market-share
/// ceiling [poolWeight] (defaults to [kCivilianBuildPoolWeight]).
///
/// Returns `civilianBuildCandidateScore(...) × poolWeight`. The pool weight is
/// a single shared scalar across all civilian types, so it dampens the civilian
/// share of the weighted build pool without reordering civilian candidates
/// relative to one another. `pickBuildOrder` applies this only on the civilian
/// branch, so military/naval scores are never multiplied by the pool weight
/// (SPEC § Scoring model — pool weight; AC10 no-regression at `poolWeight = 1.0`).
double civilianBuildPooledScore(
  String unitType,
  int currentCount, {
  String? phaseName,
  bool spyDemand = false,
  double poolWeight = kCivilianBuildPoolWeight,
  double? phaseProgress,
}) =>
    civilianBuildCandidateScore(
      unitType,
      currentCount,
      phaseName: phaseName,
      spyDemand: spyDemand,
      phaseProgress: phaseProgress,
    ) *
    poolWeight;

// ---------------------------------------------------------------------------
// Civilian build planner — shared paper budget ledger (Refs #3793 AC7,
// design decision #11). SPEC/ai/civilian-build-planner.md § Paper budget.
// Paper is shared across research, worker training, and civilian builds. The
// recruitment planner reserves research paper up to
// [kCivilianBuildResearchPaperReserveShare] of the GP's current paper, then
// allocates the remainder via its phase emit order against a running ledger,
// dropping paper-costing candidates that would push the remaining budget below
// 0. No planner magic numbers (the share + reserve math live here).
// ---------------------------------------------------------------------------

/// Fraction of the Great Power's current paper held back for research before
/// the recruitment planner allocates paper to worker-training and civilian
/// build candidates (Refs #3793 AC7, design decision #11). GA-tunable in the
/// inclusive range `[0.0, 1.0]`. Default `0.5` keeps half of the paper
/// available for the tech tree so a full build/training pass cannot starve
/// civilian-gating research (and conversely cannot be fully consumed by it).
const double kCivilianBuildResearchPaperReserveShare = 0.5;

/// Paper reserved for research given [currentPaper], computed as the
/// deterministic integer floor `currentPaper ×
/// kCivilianBuildResearchPaperReserveShare`, clamped to `[0, currentPaper]`.
///
/// Returns `0` when [currentPaper] is `0` or negative. The reserved amount is
/// subtracted from the paper budget the recruitment planner's ledger allocates
/// to worker-training and civilian-build candidates (Refs #3793 AC7).
int researchReservedPaper(int currentPaper) {
  if (currentPaper <= 0) return 0;
  final reserved = (currentPaper * kCivilianBuildResearchPaperReserveShare)
      .floor();
  if (reserved < 0) return 0;
  if (reserved > currentPaper) return currentPaper;
  return reserved;
}

// ---------------------------------------------------------------------------
// Civilian build planner — research prioritization of civilian-gating techs
// (Refs #3793 AC6). SPEC/ai/civilian-build-planner.md § Tech prioritization.
// The research planner front-loads slot selection toward the techs that unlock
// civilian unit types (Merchant ⇐ `merchant_companies`,
// Rail Builder ⇐ `early_steam_engine`) when the owning GP has not unlocked them,
// so the AI researches toward the gates that expand the civilian build pool.
// The bias only reorders selection within the existing per-turn research slot
// target — it never adds a slot or spends extra funding — so it can never
// exceed the `researchPaperReserveShare` paper reservation. No planner magic
// numbers: the gating-tech set is derived from the canonical
// [unlockingTechByCivilianId] map (single source of truth).
// ---------------------------------------------------------------------------

/// Civilian-gating tech ids the research bias prioritizes: the distinct
/// unlocking-tech values of [unlockingTechByCivilianId], in stable insertion
/// order (deterministic). Currently `merchant_companies` (Merchant) and
/// `early_steam_engine` (Rail Builder).
final List<String> kCivilianGatingTechIds = List<String>.unmodifiable(<String>{
  ...unlockingTechByCivilianId.values,
});

/// True when [techId] gates a civilian unit type (i.e. it is in
/// [kCivilianGatingTechIds]). Used by the research planner to prioritize
/// researching toward civilian-build gates (Refs #3793 AC6).
bool isCivilianGatingTech(String techId) =>
    kCivilianGatingTechIds.contains(techId);
