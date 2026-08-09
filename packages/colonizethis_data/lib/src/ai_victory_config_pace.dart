/// Victory pace, conquer/expand/trade/defend bonuses.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

/// Old World province count required for military victory.
const int kMilitaryVictoryOldWorldProvinceThreshold = 31;

/// Provinces still needed to reach military victory from [oldWorldOwned].
int provincesToVictoryFromOldWorldOwned(int oldWorldOwned) {
  final gap = kMilitaryVictoryOldWorldProvinceThreshold - oldWorldOwned;
  return gap < 0 ? 0 : gap;
}

/// Deterministic conquer-goal bonus from victory pace (0 when at/above threshold).
int conquerScoreBonusForProvincesToVictory(int provincesToVictory) {
  if (provincesToVictory <= 0) return 0;
  return (provincesToVictory * 2).clamp(0, 40);
}

/// Extra conquer weight when within 12 provinces of military victory.
int endgameConquerScoreBonus(int provincesToVictory) {
  if (provincesToVictory <= 12) return 25;
  return 0;
}

/// Expand-goal bonus when invadable Old World targets exist.
const int kExpandBonusWhenInvadableProvinces = 15;

/// When behind victory pace by more than this many provinces, conquer score is floored.
const int kConquerScoreFloorProvincesToVictoryThreshold = 20;

/// Minimum `conquer` goal score when [provincesToVictory] exceeds
/// [kConquerScoreFloorProvincesToVictoryThreshold] (after agenda modifiers).
const int kMinimumConquerScoreWhenFarFromVictory = 35;

/// Extra build weight for regiments when behind military victory pace.
const double kBuildRegimentBonusWhenBehindVictoryPace = 1.5;

/// Provinces-to-victory threshold for [kBuildRegimentBonusWhenBehindVictoryPace].
const int kBuildRegimentVictoryPaceThreshold = 10;

/// When far from victory, reduce trade goal weight by at most this amount so
/// conquer/expand can compete for trade-focused leaders.
const int kTradeGoalPenaltyCapWhenFarFromVictory = 30;

/// When far from victory, defend goal bonus while Old World holdings are small.
const int kDefendBonusWhenFewOldWorldProvinces = 35;

/// Extra defend weight when at war and Old World holdings are at or below
/// [kFewOldWorldProvincesDefendThreshold] (trade-focused GPs avoid collapse).
const int kDefendBonusWhenAtWarAndFewHoldings = 45;

/// Old World province count at or below which [kDefendBonusWhenFewOldWorldProvinces] applies.
const int kFewOldWorldProvincesDefendThreshold = 6;

/// `trade` goal floor when the GP is broke (`treasury <= 0`) after every
/// other modifier in `evaluateStrategicGoalScores` has been applied. Sized
/// to strictly outrank the worst-case competing goal envelope (stalled-OW
/// `conquer = math.max(conquer, 120)`, victory-pace + endgame conquer
/// bonuses up to `40 + 25 = 65`, max base-trade weight `90`), so a treasury
/// of zero always selects `StrategicGoal.trade` regardless of phase, leader
/// agenda, or stalled / colonial-pressure clamps on `trade`. World Market —
/// AI treasury planner; Refs #2994 F6.
const int kEmergencyTradeGoalDominantFloor = 200;

/// Peak linear bonus added to the `trade` goal score when treasury is
/// strictly between `0` and `cheapestRegimentBuildTreasuryCost()`. Scales
/// as `boost = round((1 - treasury / threshold) * kBoostMax)`: near-zero
/// treasury gets the full `kBoostMax` (lifting a moderate-trade leader near
/// the stalled-OW conquer floor of `120` so trade competes but does not yet
/// hit the emergency floor); at-threshold treasury gets `0`. World Market —
/// AI treasury planner; Refs #2994 F6.
const int kTreasuryAcquisitionTradeBoostMax = 80;
