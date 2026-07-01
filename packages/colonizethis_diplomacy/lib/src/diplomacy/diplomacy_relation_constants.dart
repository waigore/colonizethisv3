/// Relation score bounds, thresholds, and diplomacy cost constants.
/// SPEC/game/diplomacy.md; SPEC/program/diplomacy-resolution.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Overture costs per diplomacy-resolution. Consulate £500, Embassy £1000.
const int overtureConsulateCost = 500;
const int overtureEmbassyCost = 1000;

/// Join Empire cost: base + per-province. SPEC/game/diplomacy.md.
const int joinEmpireBaseCost = 5000;
const int joinEmpirePerProvinceCost = 2000;

// --- Relation score bounds and thresholds. SPEC/game/diplomacy.md. ---

/// Relation score range: min and max (inclusive).
const int relationScoreMin = 0;
const int relationScoreMax = 100;

/// Neutral relation score; per-turn decay equilibrium and default for new relations.
const int relationScoreNeutral = 50;

/// Per-turn relation decay magnitude (Refs #3753 R9.3): every non-war pair with
/// no relation-score delta event this turn drifts this much toward
/// [relationScoreNeutral], clamped so it never crosses 50 in a single turn.
/// SPEC/game/diplomacy.md § Relation Model — Per-turn relation decay.
const double relationDecayPerTurn = 4.0;

/// Base additive trade-deal relation boost (Refs #3753 R10): a faction pair
/// that completed at least one world-market trade deal (involving at least one
/// Great Power) the previous turn gains this much, applied in the Diplomacy
/// phase before per-turn decay. Volume-independent and applied once per pair
/// per turn. SPEC/game/diplomacy.md § Relation Model — Trade-deal relation boost.
const double tradeDealRelationBoostBase = 2.0;

/// Additional trade-deal relation boost when an Embassy is in effect between the
/// trading parties (Refs #3753 R10 — `+0.4`, i.e. 20% of the base). Added on top
/// of [tradeDealRelationBoostBase]. SPEC/game/diplomacy.md § Relation Model.
const double tradeDealRelationBoostEmbassyBonus = 0.4;

/// Level thresholds (inclusive max per band): Hostile ]0,25], Neutral ]25,50], Friendly ]50,75], Allied ]75,100].
const int relationScoreLevelHostileMax = 25;
const int relationScoreLevelNeutralMax = 50;
const int relationScoreLevelFriendlyMax = 75;

/// Minimum score for Friendly (and Allied). Join Empire and similar require >= this.
const int relationScoreMinFriendly = 51;

/// Minimum relation score for FTP acceptance (proposer and acceptor). SPEC/game/world-market.md.
const int relationScoreMinFtp = 65;

/// Alliance score band: when forming alliance, score is set/clamped to this range.
const int relationScoreMinAllied = 76;

// The legacy 4-band display thresholds (Hostile/Unfriendly/Cordial/Friendly)
// were retired by the 10-step relation meter (Refs #3753 R13): the player-facing
// label now derives from [relationScoreToMeterStep] + [relationMeterStepLabels].

/// Number of discrete steps in the player-facing 10-step relation meter.
/// SPEC/game/diplomacy.md § Player-facing relation display — 10-step relation meter (Refs #3753 R13).
const int relationMeterStepCount = 10;

/// Score width of each relation-meter step: the `[relationScoreMin, relationScoreMax]`
/// range divided into [relationMeterStepCount] equal half-open bands.
const int relationMeterStepWidth =
    (relationScoreMax - relationScoreMin) ~/ relationMeterStepCount;

/// Relation score change on war declaration (protest path). Clamped to [relationScoreMin, relationScoreMax].
const int relationScoreWarDelta = 10;

/// Reduced penalty when the aggressor has [kTechIdPropaganda]. SPEC/game/tech-tree-diplomacy-civilian.md.
const int relationScoreWarDeltaReducedPropaganda = 5;

/// Score penalty applied to third parties (e.g. intervention) reacting to [aggressorGpId]'s war declaration.
int warDeclarationThirdPartyPenaltyDelta(Game game, String aggressorGpId) {
  final u = game.playerById(aggressorGpId)?.techUnlocked;
  if (u?[kTechIdPropaganda] == true) {
    return relationScoreWarDeltaReducedPropaganda;
  }
  return relationScoreWarDelta;
}

/// Unified alliance-break penalty (R11): score drop applied to the breaker's
/// relation with the **broken-with ally** when any formal alliance is broken —
/// voluntarily (`breakAlliance` order) or via a call-to-arms refusal. The
/// alliance flag is also cleared for that pair. SPEC/game/diplomacy.md § Alliances.
const int allianceBreakAllyScorePenalty = 50;

/// Unified alliance-break penalty (R11): score drop applied to the breaker's
/// relation with **every other Great Power** the breaker has a relation with
/// when a formal alliance is broken (excludes the broken-with ally, and — for a
/// call-to-arms refusal — the aggressor whose declaration triggered the call).
/// SPEC/game/diplomacy.md § Alliances.
const int allianceBreakOtherGpScorePenalty = 10;

/// AI ally joins the war if B–A relation score is at least this (inclusive). SPEC/game/diplomacy.md.
const int callToArmsAiAcceptMinRelationScore = 50;

/// AI intervention probability by relation level (0–1). SPEC/game/diplomacy.md § Intervention.
/// Relation score 0–25 (Hostile) → 0%, 26–50 (Neutral) → 25%, 51–75 (Friendly) → 50%, 76–100 (Allied) → 80%.
const double kInterventionProbabilityNeutral = 0.25;
const double kInterventionProbabilityFriendly = 0.5;
const double kInterventionProbabilityAllied = 0.8;

/// Default Grant Aid amount (UI + suggestions). Positive multiples of [grantAidAmountStep].
const int grantAidDefaultAmount = 1000;

/// Grant Aid step and multiple (pounds). Validation and UI stepper.
const int grantAidAmountStep = 1000;

/// Additional trade-deal relation boost **per subsidy percentage point** in
/// effect between the trading parties (Refs #3753 R10 — `+0.2` per point, so a
/// 10% subsidy adds `+2.0`). Added on top of [tradeDealRelationBoostBase] (and
/// the embassy bonus). SPEC/game/diplomacy.md § Relation Model.
const double tradeDealRelationBoostPerSubsidyPercent = 0.2;

/// Relation score thresholds for level. 0–25 Hostile, 26–50 Neutral, 51–75 Friendly, 76–100 Allied.
/// Operates on the raw decimal [score] (SPEC/game/diplomacy.md § Relation Model).
RelationLevel scoreToLevel(num score) {
  if (score <= relationScoreLevelHostileMax) return RelationLevel.hostile;
  if (score <= relationScoreLevelNeutralMax) return RelationLevel.neutral;
  if (score <= relationScoreLevelFriendlyMax) return RelationLevel.friendly;
  return RelationLevel.allied;
}

/// 10-word player-facing relation label ladder, indexed by 1-based meter step
/// (`relationScoreToMeterStep`). Step 1 is the most hostile band `[0, 10)` and
/// step 10 is the most friendly band `[90, 100]`. The words are distinct and
/// ordered red → green, replacing the legacy 4-word band set so the hidden
/// decimal score reads as a 10-step gradient.
/// SPEC/game/diplomacy.md § Player-facing relation display — 10-step relation
/// meter (Refs #3753 R13).
const List<String> relationMeterStepLabels = <String>[
  'Hostile', // step 1  [0, 10)
  'Antagonistic', // step 2  [10, 20)
  'Distrustful', // step 3  [20, 30)
  'Unfriendly', // step 4  [30, 40)
  'Wary', // step 5  [40, 50)
  'Neutral', // step 6  [50, 60)
  'Cordial', // step 7  [60, 70)
  'Amicable', // step 8  [70, 80)
  'Friendly', // step 9  [80, 90)
  'Devoted', // step 10 [90, 100]
];

/// One of [relationMeterStepLabels] for the given 1-based [step]. The step is
/// clamped to `[1, relationMeterStepCount]` so out-of-range callers degrade to
/// the nearest end word.
/// SPEC/game/diplomacy.md § Player-facing relation display (Refs #3753 R13.4).
String relationMeterStepLabel(int step) {
  final int clamped = step.clamp(1, relationMeterStepCount);
  return relationMeterStepLabels[clamped - 1];
}

/// One-word relation state for UI display. SPEC/game/diplomacy.md § Player-facing
/// relation display. The score is hidden; the UI shows this label, now drawn
/// from the decimal-aware 10-step ladder ([relationMeterStepLabels]) keyed by
/// [relationScoreToMeterStep] (Refs #3753 R13.6), superseding the legacy 4-word
/// band set. Operates on the raw decimal [score] with no intermediate rounding
/// (SPEC/game/diplomacy.md § Relation Model).
String relationScoreToDisplayLabel(num score) =>
    relationMeterStepLabel(relationScoreToMeterStep(score));

/// Maps a relation [score] to a 1-based step in `[1, relationMeterStepCount]`
/// for the player-facing 10-step relation meter.
/// SPEC/game/diplomacy.md § Player-facing relation display — 10-step relation meter (Refs #3753 R13).
///
/// Bands are half-open `[low, high)`, so each boundary value maps to the higher
/// step (e.g. `10` → step 2); the final band `[90, 100]` is fully closed so the
/// maximum score `100` maps to step 10. The score is clamped to
/// `[relationScoreMin, relationScoreMax]` first, so values below `0` map to
/// step 1 and values above `100` map to step 10. Operates on the raw decimal
/// score with no intermediate rounding (SPEC/game/diplomacy.md § Relation Model).
int relationScoreToMeterStep(num score) {
  final clamped = score.clamp(relationScoreMin, relationScoreMax);
  final step = (clamped / relationMeterStepWidth).floor() + 1;
  return step > relationMeterStepCount ? relationMeterStepCount : step;
}
