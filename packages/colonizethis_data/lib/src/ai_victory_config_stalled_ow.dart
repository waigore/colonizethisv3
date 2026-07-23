/// Stalled Old World expansion constants and army-move weights.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

/// Old World holdings at or below this count are treated as stalled expansion
/// (observer default start is 7 provinces per GP; 9 includes seed-42 gp6 plateau).
const int kStalledOldWorldProvinceThreshold = 9;

/// True when [oldWorldProvincesOwned] matches the observer start-size stall band.
bool isStalledOldWorldExpansion(int oldWorldProvincesOwned) =>
    oldWorldProvincesOwned > 0 &&
    oldWorldProvincesOwned <= kStalledOldWorldProvinceThreshold;

/// Goal penalties while Old World holdings remain at the observer start size.
const int kStalledDiplomacyGoalPenalty = 55;

/// Trade goal penalty paired with [kStalledDiplomacyGoalPenalty].
const int kStalledTradeGoalPenalty = 40;

/// Extra conquer goal weight while Old World expansion is stalled.
const int kStalledConquerGoalBonus = 30;

/// Extra conquer / reduced defend while critically weak but invadable OW minors
/// remain (recover after survival peace; Refs #2509).
const int kWeakGpRecoveryConquerBonus = 90;

const int kWeakGpRecoveryDefendPenalty = 30;

/// Minimum diplomacy domain weight for the declare-war pass when stalled.
const int kDiplomacyDeclareWarMinWeightWhenStalled = 50;

/// Extra regiment build weight when OW holdings are stalled (any primary goal).
const double kBuildRegimentBonusWhenStalledExpansion = 4.0;

/// Extra regiment build weight when at war with no regiments in any army.
const double kBuildRegimentBonusWhenZeroRegimentsAtWar = 12.0;

/// Conquest army-move passes per turn while Old World holdings are stalled
/// (one order per pass so each field army can march toward the frontier).
const int kStalledConquestArmyMovePasses = 22;

/// Max field armies created from Home Army splits when Old World expansion is
/// stalled (parallel marches toward invasion frontiers; Refs #2509).
const int kStalledConquestFieldArmySplitCap = 12;

/// While stalled and at war, build regiments until at least this many exist in
/// all armies (Home + field) so splits and invasions can proceed (Refs #2509).
const int kStalledMinRegimentCountWhenAtWar = 10;

/// Higher floor when fighting the sole GP that owns the invadable OW frontier.
const int kStalledMinRegimentCountWhenGpBlockerAtWar = 22;

/// Regiment build floor when critically weak with minor wars only (Refs #2509).
const int kStalledMinRegimentCountWhenCriticallyWeakNoGpWar = 12;

/// When stalled and below the regiment floor, prioritize regiment builds only if
/// current count is at or below this cap (avoids starving mid-tier GPs; #2509).
const int kStalledMilitaryRebuildCrisisRegimentCap = 4;

/// Extra regiment build floor per Old World province the frontier blocker leads by.
const int kStalledMinRegimentCountPerProvinceDeficitVsBlocker = 2;

/// Below this many standing regiments, a below-quota GP at peace with all
/// other Great Powers and an invadable Old World frontier is treated as
/// "insufficient to declare war" and forced to rebuild regiments via the
/// economy build pass (seed-42 gp3 turn-100 trap; Refs #2509). Sized just
/// below the at-war regiment floor so GPs that have exited a war with low
/// armies rebuild before EXPAND declare-war scoring picks a new target.
const int kBelowQuotaPeaceMinRegimentsBeforeDeclareWar = 6;

/// Economy-weight boost for [CargoPreference] when a below-quota GP at peace
/// cannot afford the cheapest regiment build even after pending riches treasury
/// (Refs #2509 EXPAND treasury-recovery).
const int kBelowQuotaPeaceTreasuryRecoveryCargoBoost = 50;

/// Regiment build floor when critically weak, below the observer quota, and at war.
const int kStalledMinRegimentCountWhenCriticallyWeakBelowQuota = 12;

/// Conquest army-move bonus for New World invadable destinations.
const int kConquestArmyMoveNwInvadableBonus = 35;

/// Minimum conquest army-move pass weight when Old World expansion is stalled.
const int kConquestArmyMoveMinWeightWhenStalled = 75;

/// Army-move weight floor when critically weak and not at war with any GP.
const int kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar = 100;

/// Army-move score bonus for invadable provinces owned by the same-turn
/// declare-war target while Old World expansion is stalled.
const double kConquestArmyMoveStalledDeclaredTargetInvadableBonus = 800;

/// Army-move score bonus for any province owned by the same-turn declare-war
/// target while Old World expansion is stalled.
const double kConquestArmyMoveStalledDeclaredTargetBonus = 250;

/// Army-move score bonus when the destination is topologically adjacent to an
/// invadable Old World province (march toward the invasion frontier).
const double kConquestArmyMoveAdjacentInvadableBonus = 450;

/// Army-move score bonus for invadable provinces owned by a Great Power the
/// attacker is already at war with (seed-42 gp3/gp5 blockers; Refs #2509).
const double kConquestArmyMoveStalledGpInvadableBlockerBonus = 1900;

/// Extra army-move score per OW province the invadable-blocker GP leads by.
const double kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince = 300;

/// Army-move score bonus for own provinces bordering a faction already at war
/// (march to frontier when invadable tiles are not yet visible).
const double kConquestArmyMoveAdjacentAtWarFrontierBonus = 650;
