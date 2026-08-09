/// Declare-war scoring and relation-cap constants.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

/// Declare-war relation cap for minor/tribe targets when far from military victory
/// (peacemaker agenda caps do not block minor conquest).
const int kDeclareWarMinorMaxRelationWhenFarFromVictory = 100;

/// Bonus to declare-war scoring toward a weak-neighbor Great Power when war desire is high.
const int kDeclareWarGpWeakNeighborBonus = 12;

/// Minimum war-desire score (0..100) for [kDeclareWarGpWeakNeighborBonus].
const int kDeclareWarGpWeakNeighborMinWarDesire = 55;

/// Declare-war relation cap for **Great Power** targets that own provinces
/// topologically adjacent to the attacker when far from military victory.
const int kDeclareWarGpMaxRelationWhenFarFromVictory = 85;

/// Score bonus for `declareWar` toward a faction that owns an adjacent Old
/// World province (topology), so AI does not declare on distant minors only.
const int kDeclareWarAdjacentOwnerBonus = 28;

/// Extra declare-war bonus for low-[warLikelihood] personalities when far from
/// victory and the target owns adjacent Old World provinces.
const int kDeclareWarLowWarLikelihoodAdjacentBonus = 20;

/// Personality [warLikelihood] at or below this uses
/// [kDeclareWarLowWarLikelihoodAdjacentBonus].
const int kDeclareWarLowWarLikelihoodThreshold = 35;

/// When far from victory, suppress declare-war on factions that do not own a
/// topologically adjacent Old World province (distant minors are useless).
const int kDeclareWarNonAdjacentSuppressedScore = 0;

/// Declare-war bonus toward an adjacent **Great Power** when far from victory.
const int kDeclareWarAdjacentGpBonusWhenFarFromVictory = 35;

/// Extra declare-war bonus toward an adjacent **minor/tribe** when far from victory.
const int kDeclareWarAdjacentMinorBonusWhenFarFromVictory = 55;

/// While `provincesToVictory` is **greater than** this value, declare-war on other
/// Great Powers is suppressed so each GP expands from minors/tribes first (observer
/// per-GP conquest AC; only 18 non-GP Old World provinces at default setup).
const int kSuppressGpDeclareWarMinProvincesToVictory = 12;

/// Extra declare-war weight toward adjacent minors when stalled.
const int kDeclareWarStalledExpansionMinorBonus = 75;

/// When OW expansion is stalled but invadable OW minors exist, prioritize
/// declaring on those minors over distant tribe wars (observer turn-100 gate).
const int kDeclareWarStalledOwMinorPriorityBonus = 280;

/// Extra declare-war weight toward OW minors while holdings are critically low.
const int kDeclareWarWeakGpOwMinorRecoveryBonus = 220;

/// Extra declare-war weight toward OW minors while below the observer quota
/// (7–9 OW holdings; Refs #2509).
const int kDeclareWarBelowQuotaOwMinorRecoveryBonus = 380;

/// Extra declare-war toward adjacent invadable OW minors at 8–9 OW with no GP war
/// (observer seed-42 gp5/gp6 plateau; Refs #2509).
const int kDeclareWarPlateauOwMinorBonus = 1050;

/// Extra declare-war weight toward invadable minors when 8–9 OW (one province
/// short of the turn-100 observer gate from default start; Refs #2509).
const int kDeclareWarNearObserverQuotaMinorBonus = 340;

/// Penalize tribe declare-war while OW holdings are stalled and invadable OW
/// minors remain (tribes without sea-reachable NW provinces for this GP).
const int kDeclareWarStalledExpansionTribePenalty = 100;

/// Extra declare-war weight on adjacent OW minors while minors still exist on
/// the map and the campaign is in the early expansion window (turn ≤ 30).
const int kDeclareWarEarlyExpansionMinorBonus = 260;

/// Penalize tribe declare-war in that early window while any OW minor remains.
const int kDeclareWarEarlyExpansionTribePenalty = 160;

/// Last turn (inclusive) for [kDeclareWarEarlyExpansionMinorBonus].
const int kDeclareWarEarlyExpansionMaxTurn = 100;

/// Through this turn, quota-meeting GPs must not open new wars on weaker
/// below-quota neighbors when the target is not already in a GP war (Refs #2509).
/// Pile-ons on below-quota victims already at war are suppressed at all turns.
const int kDeclareWarEarlyAntiDogpileMaxTurn = 50;

/// Penalty on adjacent minor declare-war when the GP already holds many OW provinces.
const int kDeclareWarSatedExpansionMinorPenalty = 100;

/// OW holdings at or above this count trigger [kDeclareWarSatedExpansionMinorPenalty].
const int kDeclareWarSatedExpansionMinorThreshold = 9;

/// Declare-war bonus when the target still owns an adjacent invadable province.
const int kDeclareWarMinorWithInvadableProvinceBonus = 45;

/// Declare-war bonus on adjacent invadable OW minors while below the observer quota.
const int kDeclareWarBelowObserverQuotaMinorBonus = 480;

/// Declare-war bonus toward a tribe/minor that owns adjacent New World provinces.
const int kDeclareWarColonialAdjacentTribeBonus = 70;

/// Declare-war bonus when the target owns a sea-reachable invadable NW province.
const int kDeclareWarColonialInvadableOwnerBonus = 110;

/// Extra declare-war weight for **tribes** owning sea-reachable NW provinces so
/// they outrank adjacent Old World minor targets under colonial pressure.
const int kDeclareWarColonialNwTribeDominanceBonus = 100;

/// Additional tribe declare-war weight when colonial pressure is active and
/// Old World expansion is stalled, so NW targets beat stacked OW minor bonuses.
const int kDeclareWarColonialNwTribePriorityOverOwMinorBonus = 360;

/// Extra declare-war weight for low-[warLikelihood] leaders toward adjacent
/// invadable minors while Old World expansion is stalled.
const int kDeclareWarStalledLowWarLikelihoodMinorBonus = 180;

/// Minimum declare-war score for low-[warLikelihood] leaders toward adjacent
/// invadable minors while Old World expansion is stalled (henry / Portugal).
const int kDeclareWarStalledLowWarLikelihoodMinorFloor = 620;

/// Cap declare-war score toward NW tribes for low-[warLikelihood] leaders when
/// invadable Old World minors remain (henry clears OW minors before tribes).
const int kDeclareWarStalledLowWarLikelihoodTribeCap = 150;

/// Minimum declare-war score for any leader toward adjacent invadable minors
/// while Old World expansion is stalled and far from military victory.
const int kDeclareWarStalledAdjacentInvadableMinorFloor = 400;

/// Higher floor for critically weak GPs toward adjacent invadable OW minors.
const int kDeclareWarWeakGpAdjacentInvadableMinorFloor = 580;

/// Declare-war bonus toward OW minors when critically weak, invadable land
/// remains, and the GP is not at war with any other Great Power (Refs #2509).
const int kDeclareWarCriticalWeakNoGpWarMinorBonus = 220;

/// Declare-war penalty toward adjacent GPs while invadable Old World minors
/// remain and expansion is stalled (reduces GP dogpiles on seed-42).
const int kDeclareWarStalledGpWhenMinorsRemainPenalty = 280;

/// Declare-war penalty toward a stalled weaker neighbor GP (mid-map deadlocks).
const int kDeclareWarOnStalledWeakerNeighborPenalty = 200;

/// Suppress declare-war on adjacent GPs at or below
/// [kFewOldWorldProvincesDefendThreshold] when the attacker leads by at least
/// this many Old World provinces (observer seed-42 gp3/gp6; Refs #2509).
const int kDeclareWarAggressorSuppressWeakGpLeadThreshold = 4;

/// Cap NW tribe declare-war scores while invadable Old World minors remain.
const int kDeclareWarStalledTribeWhenOwMinorCap = 250;

/// Declare-war penalty toward Old World minors with no sea-reachable NW
/// provinces while colonial pressure is active.
const int kDeclareWarColonialPressureOwMinorPenalty = 50;

/// Declare-war bonus for non-adjacent minors with fewer provinces than a stalled GP.
const int kDeclareWarStalledWeakerMinorBonus = 80;

/// Extra declare-war weight toward any minor that still holds Old World provinces
/// while the GP remains at the observer start OW size.
const int kDeclareWarStalledActiveOwMinorBonus = 200;

/// Declare-war bonus when the weakest invadable-border GP blocks expansion.
const int kDeclareWarStalledWeakestInvadableGpBonus = 75;

/// Declare-war bonus toward a weaker adjacent GP that owns invadable OW land
/// while expansion is stalled and far from victory (Refs #2509).
const int kDeclareWarStalledInvadableGpBlockerBonus = 220;

/// Minimum declare-war score toward the GP that owns invadable OW frontier when
/// no minors hold invadable land (seed-42 mid-map blockers; Refs #2509).
const int kDeclareWarStalledGpInvadableBlockerFloor = 500;

/// Declare-war bonus toward a non-adjacent minor while invadable OW land is
/// blocked by Great Powers (seed-42 mid-map geography; Refs #2509).
const int kDeclareWarStalledGpBlockerDistantMinorBonus = 160;

/// Declare-war bonus on any OW minor while still at default observer start size.
const int kDeclareWarDefaultStartOwMinorBonus = 240;

/// Declare-war bonus toward any minor that still holds OW provinces when this
/// GP is stalled, far from victory, and frontier invadable land is GP-owned.
const int kDeclareWarStalledAnyOwMinorBonus = 140;
