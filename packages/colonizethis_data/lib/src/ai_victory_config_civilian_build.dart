/// Civilian-build planner victory-config constants and helpers.
///
/// Extracted from the victory-config kitchen sink so topical ownership stays
/// clear (SPEC/ai/civilian-build-planner.md; Refs #4072). Public API remains
/// available via `ai_victory_config.dart` and the package barrel.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'civilian_economy.dart' show unlockingTechByCivilianId;

export 'ai_victory_config_civilian_build_scoring.dart';

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
