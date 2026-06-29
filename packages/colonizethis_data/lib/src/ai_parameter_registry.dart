/// Machine-readable registry of tunable AI-behavior parameters.
///
/// Declares one [AiParameter] per numeric constant in
/// `ai_personality_config.dart` and `ai_victory_config.dart` that affects AI
/// behavior, with canonical key, category, integer flag, bounds, default, and
/// description. Foundational data layer for genetic-algorithm tuning.
/// SPEC/ai/ai-parameter-registry.md. Refs #3436.
library;

import 'dart:math' as math;

import 'ai_personality_config.dart';
import 'ai_victory_config.dart';

/// Parameter categories. Metadata only — never part of the canonical key.
abstract final class AiParameterCategory {
  static const String personalityDomain = 'personality_domain';
  static const String personalityGoal = 'personality_goal';
  static const String personalityThreshold = 'personality_threshold';
  static const String victoryConfig = 'victory_config';
}

/// A single tunable AI parameter declaration.
class AiParameter {
  const AiParameter({
    required this.name,
    required this.category,
    required this.isInteger,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.description,
  });

  /// Canonical key. Personality params: `<sourceMapName>.<fieldName>`.
  /// Victory-config params: the flat Dart constant identifier.
  final String name;

  /// One of [AiParameterCategory]; metadata only, not part of [name].
  final String category;

  /// True for `int`-typed source constants, false for `double`.
  final bool isInteger;

  /// Inclusive lower bound used when clamping profile values.
  final num minValue;

  /// Inclusive upper bound used when clamping profile values.
  final num maxValue;

  /// Current hardcoded value of the source constant.
  final num defaultValue;

  /// Human-readable summary of what this parameter controls.
  final String description;
}

/// Registry of all tunable AI parameters. SPEC/ai/ai-parameter-registry.md.
abstract final class AiParameterRegistry {
  /// Complete, deterministically ordered parameter list.
  static final List<AiParameter> allParams = List<AiParameter>.unmodifiable([
    ..._personalityParams,
    ..._victoryConfigParams,
  ]);

  /// Name → default value for profile initialization.
  static final Map<String, num> defaults = Map<String, num>.unmodifiable({
    for (final p in allParams) p.name: p.defaultValue,
  });

  static final Map<String, AiParameter> _byName =
      Map<String, AiParameter>.unmodifiable({
        for (final p in allParams) p.name: p,
      });

  /// Params filtered to one [AiParameterCategory].
  static List<AiParameter> byCategory(String category) =>
      allParams.where((p) => p.category == category).toList(growable: false);

  /// Single-parameter lookup by canonical key, or null when unknown.
  static AiParameter? byName(String name) => _byName[name];
}

AiParameter _personality(
  String category,
  String name,
  num defaultValue,
  String description,
) => AiParameter(
  name: name,
  category: category,
  isInteger: true,
  minValue: 0,
  maxValue: 100,
  defaultValue: defaultValue,
  description: description,
);

/// Victory-config `int` parameter: bounds [0, max(2000, 4 × default)].
AiParameter _vcInt(String name, int defaultValue, String description) =>
    AiParameter(
      name: name,
      category: AiParameterCategory.victoryConfig,
      isInteger: true,
      minValue: 0,
      maxValue: math.max(2000, 4 * defaultValue),
      defaultValue: defaultValue,
      description: description,
    );

/// Victory-config `double` parameter: bounds [0.0, 4 × default].
AiParameter _vcDouble(String name, double defaultValue, String description) =>
    AiParameter(
      name: name,
      category: AiParameterCategory.victoryConfig,
      isInteger: false,
      minValue: 0.0,
      maxValue: 4 * defaultValue,
      defaultValue: defaultValue,
      description: description,
    );

final List<AiParameter> _personalityParams = <AiParameter>[
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.economy',
    defaultDomainWeights.economy,
    'Domain weight for economy planning.',
  ),
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.military',
    defaultDomainWeights.military,
    'Domain weight for military planning.',
  ),
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.diplomacy',
    defaultDomainWeights.diplomacy,
    'Domain weight for diplomacy planning.',
  ),
  _personality(
    AiParameterCategory.personalityDomain,
    'personalityDomainWeights.research',
    defaultDomainWeights.research,
    'Domain weight for research planning.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.defend',
    defaultGoalWeights.defend,
    'Goal weight for the defend strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.expand',
    defaultGoalWeights.expand,
    'Goal weight for the expand strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.conquer',
    defaultGoalWeights.conquer,
    'Goal weight for the conquer strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.trade',
    defaultGoalWeights.trade,
    'Goal weight for the trade strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.tech',
    defaultGoalWeights.tech,
    'Goal weight for the tech strategy.',
  ),
  _personality(
    AiParameterCategory.personalityGoal,
    'personalityGoalWeights.diplomacy',
    defaultGoalWeights.diplomacy,
    'Goal weight for the diplomacy strategy.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.warLikelihood',
    defaultThresholds.warLikelihood,
    'Tendency to declare war.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.peaceTendency',
    defaultThresholds.peaceTendency,
    'Tendency to accept or offer peace.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.allianceTendency',
    defaultThresholds.allianceTendency,
    'Tendency to seek alliances.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchNaval',
    defaultThresholds.researchNaval,
    'Research preference weight for naval techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchMilitary',
    defaultThresholds.researchMilitary,
    'Research preference weight for military techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchEconomic',
    defaultThresholds.researchEconomic,
    'Research preference weight for economic techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchExploration',
    defaultThresholds.researchExploration,
    'Research preference weight for exploration techs.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchFundingAggression',
    defaultThresholds.researchFundingAggression,
    'Scales the Full-AI target uniform research funding tier.',
  ),
  _personality(
    AiParameterCategory.personalityThreshold,
    'personalityThresholds.researchSlotFillAggression',
    defaultThresholds.researchSlotFillAggression,
    'Target fraction of empty research slots Full AI fills each turn.',
  ),
];

final List<AiParameter> _victoryConfigParams = <AiParameter>[
  _vcInt(
    'kMilitaryVictoryOldWorldProvinceThreshold',
    kMilitaryVictoryOldWorldProvinceThreshold,
    'Old World province count required for military victory.',
  ),
  _vcInt(
    'kExpandBonusWhenInvadableProvinces',
    kExpandBonusWhenInvadableProvinces,
    'Expand-goal bonus when invadable Old World targets exist.',
  ),
  _vcInt(
    'kConquerScoreFloorProvincesToVictoryThreshold',
    kConquerScoreFloorProvincesToVictoryThreshold,
    'Provinces-to-victory threshold above which conquer score is floored.',
  ),
  _vcInt(
    'kMinimumConquerScoreWhenFarFromVictory',
    kMinimumConquerScoreWhenFarFromVictory,
    'Minimum conquer goal score when far from victory.',
  ),
  _vcInt(
    'kDeclareWarMinorMaxRelationWhenFarFromVictory',
    kDeclareWarMinorMaxRelationWhenFarFromVictory,
    'Declare-war relation cap for minor/tribe targets when far from victory.',
  ),
  _vcInt(
    'kDeclareWarGpWeakNeighborBonus',
    kDeclareWarGpWeakNeighborBonus,
    'Declare-war bonus toward a weak-neighbor Great Power.',
  ),
  _vcInt(
    'kDeclareWarGpWeakNeighborMinWarDesire',
    kDeclareWarGpWeakNeighborMinWarDesire,
    'Minimum war-desire for the weak-neighbor GP declare-war bonus.',
  ),
  _vcDouble(
    'kBuildRegimentBonusWhenBehindVictoryPace',
    kBuildRegimentBonusWhenBehindVictoryPace,
    'Extra build weight for regiments when behind military victory pace.',
  ),
  _vcInt(
    'kBuildRegimentVictoryPaceThreshold',
    kBuildRegimentVictoryPaceThreshold,
    'Provinces-to-victory threshold for the behind-pace regiment bonus.',
  ),
  _vcInt(
    'kDeclareWarGpMaxRelationWhenFarFromVictory',
    kDeclareWarGpMaxRelationWhenFarFromVictory,
    'Declare-war relation cap for adjacent GP targets when far from victory.',
  ),
  _vcInt(
    'kDeclareWarAdjacentOwnerBonus',
    kDeclareWarAdjacentOwnerBonus,
    'Declare-war bonus toward an adjacent Old World province owner.',
  ),
  _vcInt(
    'kDeclareWarLowWarLikelihoodAdjacentBonus',
    kDeclareWarLowWarLikelihoodAdjacentBonus,
    'Extra declare-war bonus for low-warLikelihood personalities.',
  ),
  _vcInt(
    'kDeclareWarLowWarLikelihoodThreshold',
    kDeclareWarLowWarLikelihoodThreshold,
    'warLikelihood at or below which the low-warLikelihood bonus applies.',
  ),
  _vcInt(
    'kTradeGoalPenaltyCapWhenFarFromVictory',
    kTradeGoalPenaltyCapWhenFarFromVictory,
    'Cap on trade goal penalty when far from victory.',
  ),
  _vcInt(
    'kDeclareWarNonAdjacentSuppressedScore',
    kDeclareWarNonAdjacentSuppressedScore,
    'Declare-war score for suppressed non-adjacent targets.',
  ),
  _vcInt(
    'kDeclareWarAdjacentGpBonusWhenFarFromVictory',
    kDeclareWarAdjacentGpBonusWhenFarFromVictory,
    'Declare-war bonus toward an adjacent GP when far from victory.',
  ),
  _vcInt(
    'kDeclareWarAdjacentMinorBonusWhenFarFromVictory',
    kDeclareWarAdjacentMinorBonusWhenFarFromVictory,
    'Declare-war bonus toward an adjacent minor/tribe when far from victory.',
  ),
  _vcInt(
    'kSuppressGpDeclareWarMinProvincesToVictory',
    kSuppressGpDeclareWarMinProvincesToVictory,
    'Provinces-to-victory above which GP declare-war is suppressed.',
  ),
  _vcInt(
    'kObserverDefaultStartOldWorldProvincesPerGp',
    kObserverDefaultStartOldWorldProvincesPerGp,
    'Observer default start Old World provinces per GP.',
  ),
  _vcInt(
    'kStalledOldWorldProvinceThreshold',
    kStalledOldWorldProvinceThreshold,
    'OW holdings at or below this count are treated as stalled expansion.',
  ),
  _vcInt(
    'kStalledDiplomacyGoalPenalty',
    kStalledDiplomacyGoalPenalty,
    'Diplomacy goal penalty while OW expansion is stalled.',
  ),
  _vcInt(
    'kStalledTradeGoalPenalty',
    kStalledTradeGoalPenalty,
    'Trade goal penalty while OW expansion is stalled.',
  ),
  _vcInt(
    'kStalledConquerGoalBonus',
    kStalledConquerGoalBonus,
    'Extra conquer goal weight while OW expansion is stalled.',
  ),
  _vcInt(
    'kWeakGpRecoveryConquerBonus',
    kWeakGpRecoveryConquerBonus,
    'Extra conquer weight while critically weak with invadable OW minors.',
  ),
  _vcInt(
    'kWeakGpRecoveryDefendPenalty',
    kWeakGpRecoveryDefendPenalty,
    'Reduced defend weight while critically weak with invadable OW minors.',
  ),
  _vcInt(
    'kDeclareWarStalledExpansionMinorBonus',
    kDeclareWarStalledExpansionMinorBonus,
    'Extra declare-war weight toward adjacent minors when stalled.',
  ),
  _vcInt(
    'kDeclareWarStalledOwMinorPriorityBonus',
    kDeclareWarStalledOwMinorPriorityBonus,
    'Priority declare-war weight toward OW minors over distant tribes.',
  ),
  _vcInt(
    'kDeclareWarWeakGpOwMinorRecoveryBonus',
    kDeclareWarWeakGpOwMinorRecoveryBonus,
    'Extra declare-war weight toward OW minors while critically low.',
  ),
  _vcInt(
    'kDeclareWarBelowQuotaOwMinorRecoveryBonus',
    kDeclareWarBelowQuotaOwMinorRecoveryBonus,
    'Extra declare-war weight toward OW minors while below observer quota.',
  ),
  _vcInt(
    'kDeclareWarPlateauOwMinorBonus',
    kDeclareWarPlateauOwMinorBonus,
    'Extra declare-war toward invadable OW minors at the 8-9 OW plateau.',
  ),
  _vcInt(
    'kDeclareWarNearObserverQuotaMinorBonus',
    kDeclareWarNearObserverQuotaMinorBonus,
    'Extra declare-war toward invadable minors near the observer quota.',
  ),
  _vcInt(
    'kDeclareWarStalledExpansionTribePenalty',
    kDeclareWarStalledExpansionTribePenalty,
    'Penalize tribe declare-war while stalled and OW minors remain.',
  ),
  _vcInt(
    'kDeclareWarEarlyExpansionMinorBonus',
    kDeclareWarEarlyExpansionMinorBonus,
    'Extra declare-war weight on adjacent OW minors in the early window.',
  ),
  _vcInt(
    'kDeclareWarEarlyExpansionTribePenalty',
    kDeclareWarEarlyExpansionTribePenalty,
    'Penalize tribe declare-war in the early window while OW minors remain.',
  ),
  _vcInt(
    'kDeclareWarEarlyExpansionMaxTurn',
    kDeclareWarEarlyExpansionMaxTurn,
    'Last turn for the early-expansion minor bonus.',
  ),
  _vcInt(
    'kDeclareWarEarlyAntiDogpileMaxTurn',
    kDeclareWarEarlyAntiDogpileMaxTurn,
    'Last turn quota-meeting GPs avoid opening wars on weaker neighbors.',
  ),
  _vcInt(
    'kDeclareWarSatedExpansionMinorPenalty',
    kDeclareWarSatedExpansionMinorPenalty,
    'Penalty on adjacent minor declare-war when holding many OW provinces.',
  ),
  _vcInt(
    'kDeclareWarSatedExpansionMinorThreshold',
    kDeclareWarSatedExpansionMinorThreshold,
    'OW holdings at or above which the sated-expansion penalty triggers.',
  ),
  _vcInt(
    'kDiplomacyDeclareWarMinWeightWhenStalled',
    kDiplomacyDeclareWarMinWeightWhenStalled,
    'Minimum diplomacy declare-war pass weight when stalled.',
  ),
  _vcDouble(
    'kBuildRegimentBonusWhenStalledExpansion',
    kBuildRegimentBonusWhenStalledExpansion,
    'Extra regiment build weight when OW holdings are stalled.',
  ),
  _vcDouble(
    'kBuildRegimentBonusWhenZeroRegimentsAtWar',
    kBuildRegimentBonusWhenZeroRegimentsAtWar,
    'Extra regiment build weight when at war with zero regiments.',
  ),
  _vcInt(
    'kDeclareWarMinorWithInvadableProvinceBonus',
    kDeclareWarMinorWithInvadableProvinceBonus,
    'Declare-war bonus when target owns an adjacent invadable province.',
  ),
  _vcInt(
    'kStalledConquestArmyMovePasses',
    kStalledConquestArmyMovePasses,
    'Conquest army-move passes per turn while OW holdings are stalled.',
  ),
  _vcInt(
    'kStalledConquestFieldArmySplitCap',
    kStalledConquestFieldArmySplitCap,
    'Max field armies from Home Army splits while OW expansion is stalled.',
  ),
  _vcInt(
    'kStalledMinRegimentCountWhenAtWar',
    kStalledMinRegimentCountWhenAtWar,
    'Regiment floor while stalled and at war.',
  ),
  _vcInt(
    'kStalledMinRegimentCountWhenGpBlockerAtWar',
    kStalledMinRegimentCountWhenGpBlockerAtWar,
    'Higher regiment floor when fighting the sole frontier-blocker GP.',
  ),
  _vcInt(
    'kStalledMinRegimentCountWhenCriticallyWeakNoGpWar',
    kStalledMinRegimentCountWhenCriticallyWeakNoGpWar,
    'Regiment floor when critically weak with minor wars only.',
  ),
  _vcInt(
    'kStalledMilitaryRebuildCrisisRegimentCap',
    kStalledMilitaryRebuildCrisisRegimentCap,
    'Regiment count cap below which stalled rebuilds are prioritized.',
  ),
  _vcInt(
    'kStalledMinRegimentCountPerProvinceDeficitVsBlocker',
    kStalledMinRegimentCountPerProvinceDeficitVsBlocker,
    'Extra regiment floor per OW province the frontier blocker leads by.',
  ),
  _vcInt(
    'kBelowQuotaPeaceMinRegimentsBeforeDeclareWar',
    kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
    'Regiment floor below which a below-quota peaceful GP rebuilds first.',
  ),
  _vcInt(
    'kBelowQuotaPeaceTreasuryRecoveryCargoBoost',
    kBelowQuotaPeaceTreasuryRecoveryCargoBoost,
    'Cargo economy boost when a below-quota GP cannot afford a regiment.',
  ),
  _vcInt(
    'kOfferPeaceFutileMinorWarBonus',
    kOfferPeaceFutileMinorWarBonus,
    'Offer-peace bonus toward a minor/tribe with no invadable land left.',
  ),
  _vcInt(
    'kOfferPeaceBelowQuotaActiveMinorWarPenalty',
    kOfferPeaceBelowQuotaActiveMinorWarPenalty,
    'Penalty for offering peace to a minor still holding invadable OW land.',
  ),
  _vcInt(
    'kOfferPeaceStalledStrongerGpBlockerBonus',
    kOfferPeaceStalledStrongerGpBlockerBonus,
    'Offer-peace bonus toward a stronger adjacent GP blocking the frontier.',
  ),
  _vcInt(
    'kOfferPeaceStalledFutileGpWarBonus',
    kOfferPeaceStalledFutileGpWarBonus,
    'Offer-peace bonus toward a GP owning none of this GP\'s invadable land.',
  ),
  _vcInt(
    'kObserverConquestMinOwProvincesPerGp',
    kObserverConquestMinOwProvincesPerGp,
    'Observer per-GP turn-100 conquest quota in OW provinces.',
  ),
  _vcInt(
    'kObserverColonialLiteMinTurn',
    kObserverColonialLiteMinTurn,
    'Turn when near-quota EXPAND GPs may enter COLONIAL-lite.',
  ),
  _vcInt(
    'kObserverColonialLiteNearQuotaOw',
    kObserverColonialLiteNearQuotaOw,
    'OW holdings at or above which COLONIAL-lite is enabled while below quota.',
  ),
  _vcInt(
    'kDevelopCivilianWorkThresholdCap',
    kDevelopCivilianWorkThresholdCap,
    'Civilian work threshold cap in the DEVELOP phase.',
  ),
  _vcInt(
    'kConsolidateGainsSoleGpProvinceLead',
    kConsolidateGainsSoleGpProvinceLead,
    'OW province lead over sole GP enemy to consolidate gains via peace.',
  ),
  _vcInt(
    'kObserverConquestConsolidateMinOwProvinces',
    kObserverConquestConsolidateMinOwProvinces,
    'Minimum OW holdings before consolidate-gains sole-GP peace may fire.',
  ),
  _vcInt(
    'kUnwinnableSoleGpMinProvinceDeficit',
    kUnwinnableSoleGpMinProvinceDeficit,
    'OW province deficit for the unwinnable sole-GP frontier peace.',
  ),
  _vcInt(
    'kDeclareWarBelowObserverQuotaMinorBonus',
    kDeclareWarBelowObserverQuotaMinorBonus,
    'Declare-war bonus on adjacent invadable OW minors while below quota.',
  ),
  _vcInt(
    'kOfferPeaceStalledZeroRegimentGpWarBonus',
    kOfferPeaceStalledZeroRegimentGpWarBonus,
    'Offer-peace bonus toward any at-war GP when stalled with zero regiments.',
  ),
  _vcInt(
    'kMutualExhaustedGpStalemateMinOw',
    kMutualExhaustedGpStalemateMinOw,
    'OW floor for the mutual-exhausted GP stalemate peace check.',
  ),
  _vcInt(
    'kMutualExhaustedGpRegimentMax',
    kMutualExhaustedGpRegimentMax,
    'Regiment ceiling under which a GP is treated as militarily exhausted.',
  ),
  _vcInt(
    'kMutualExhaustedGpTreasuryMax',
    kMutualExhaustedGpTreasuryMax,
    'Treasury ceiling under which a GP is treated as economically exhausted.',
  ),
  _vcInt(
    'kOfferPeaceMutualExhaustedGpStalemateBonus',
    kOfferPeaceMutualExhaustedGpStalemateBonus,
    'Offer-peace bonus for a mutually-exhausted sole-GP stalemate.',
  ),
  _vcInt(
    'kStalledMinRegimentCountWhenCriticallyWeakBelowQuota',
    kStalledMinRegimentCountWhenCriticallyWeakBelowQuota,
    'Regiment floor when critically weak, below quota, and at war.',
  ),
  _vcInt(
    'kOfferPeaceUnwinnableSoleGpWarBonus',
    kOfferPeaceUnwinnableSoleGpWarBonus,
    'Offer-peace bonus for the unwinnable sole-GP frontier peace target.',
  ),
  _vcInt(
    'kOfferPeaceConsolidateGainsSoleGpWarBonus',
    kOfferPeaceConsolidateGainsSoleGpWarBonus,
    'Offer-peace bonus for the consolidate-gains sole-GP peace target.',
  ),
  _vcInt(
    'kDefendBonusWhenFewOldWorldProvinces',
    kDefendBonusWhenFewOldWorldProvinces,
    'Defend goal bonus while OW holdings are small and far from victory.',
  ),
  _vcInt(
    'kDefendBonusWhenAtWarAndFewHoldings',
    kDefendBonusWhenAtWarAndFewHoldings,
    'Extra defend weight when at war and OW holdings are few.',
  ),
  _vcInt(
    'kFewOldWorldProvincesDefendThreshold',
    kFewOldWorldProvincesDefendThreshold,
    'OW province count at or below which the few-holdings defend bonus applies.',
  ),
  _vcInt(
    'kColonialExpandBonusWhenInvadableNw',
    kColonialExpandBonusWhenInvadableNw,
    'Expand-goal bonus when invadable New World provinces exist.',
  ),
  _vcInt(
    'kColonialConquerBonusWhenInvadableNw',
    kColonialConquerBonusWhenInvadableNw,
    'Conquer-goal bonus for colonial pressure below OW victory floors.',
  ),
  _vcInt(
    'kDeclareWarColonialAdjacentTribeBonus',
    kDeclareWarColonialAdjacentTribeBonus,
    'Declare-war bonus toward a tribe/minor owning adjacent NW provinces.',
  ),
  _vcInt(
    'kEstablishOvertureColonialTribeBonus',
    kEstablishOvertureColonialTribeBonus,
    'Establish-overture bonus toward a preferred colonial tribe target.',
  ),
  _vcInt(
    'kEstablishOvertureColonialInvadableOwnerBonus',
    kEstablishOvertureColonialInvadableOwnerBonus,
    'Establish-overture bonus toward a sea-reachable NW province owner.',
  ),
  _vcInt(
    'kEstablishOvertureDecayCreditMax',
    kEstablishOvertureDecayCreditMax,
    'Max improve-relations reduction credited to natural relation decay.',
  ),
  _vcInt(
    'kEstablishOvertureFtpCompetitionBonus',
    kEstablishOvertureFtpCompetitionBonus,
    'Overture incentive when not the favoured trading partner for a '
        'Minor/Tribe target.',
  ),
  _vcInt(
    'kConquestArmyMoveNwInvadableBonus',
    kConquestArmyMoveNwInvadableBonus,
    'Conquest army-move bonus for New World invadable destinations.',
  ),
  _vcInt(
    'kColonialCargoPreferenceEconomyBoost',
    kColonialCargoPreferenceEconomyBoost,
    'Economy-domain cargo-preference boost when colonial targets exist.',
  ),
  _vcInt(
    'kColonialCargoPreferenceNoNwColoniesBoost',
    kColonialCargoPreferenceNoNwColoniesBoost,
    'Extra cargo boost when the GP owns no New World provinces yet.',
  ),
  _vcInt(
    'kColonialNavalWeightBonus',
    kColonialNavalWeightBonus,
    'Naval planner weight boost when NW invasion/colonization is viable.',
  ),
  _vcInt(
    'kColonialNavalMinWeightWhenPressure',
    kColonialNavalMinWeightWhenPressure,
    'Minimum naval planner weight under active colonial pressure.',
  ),
  _vcInt(
    'kColonialNavalMoveDockNewWorldPortScore',
    kColonialNavalMoveDockNewWorldPortScore,
    'Naval move score when docking at a New World port under pressure.',
  ),
  _vcInt(
    'kColonialNavalMovePriorityNwSeaZoneScore',
    kColonialNavalMovePriorityNwSeaZoneScore,
    'Naval move score for an NW sea zone bordering an invadable province.',
  ),
  _vcInt(
    'kColonialNavalMovePhasePriorityNwSeaZoneScore',
    kColonialNavalMovePhasePriorityNwSeaZoneScore,
    'Naval move score for an NW sea zone bordering a phase-priority province.',
  ),
  _vcInt(
    'kColonialNavalMoveNwSeaZoneScore',
    kColonialNavalMoveNwSeaZoneScore,
    'Naval move score for any other New World sea zone destination.',
  ),
  _vcInt(
    'kColonialNavalMoveGatewaySeaZoneScore',
    kColonialNavalMoveGatewaySeaZoneScore,
    'Naval move score for an OW sea zone linked to NW seas.',
  ),
  _vcInt(
    'kDeclareWarColonialInvadableOwnerBonus',
    kDeclareWarColonialInvadableOwnerBonus,
    'Declare-war bonus when target owns a sea-reachable invadable NW province.',
  ),
  _vcInt(
    'kColonialFewNwProvincesThreshold',
    kColonialFewNwProvincesThreshold,
    'NW holdings below which colonial goal bonuses apply.',
  ),
  _vcInt(
    'kColonialConquerBonusWhenFewNwProvinces',
    kColonialConquerBonusWhenFewNwProvinces,
    'Extra conquer weight while below the few-NW-provinces threshold.',
  ),
  _vcInt(
    'kColonialDiplomacyGoalPenaltyWhenPressure',
    kColonialDiplomacyGoalPenaltyWhenPressure,
    'Diplomacy goal penalty while sea-reachable NW targets exist.',
  ),
  _vcInt(
    'kColonialTradeGoalPenaltyWhenPressure',
    kColonialTradeGoalPenaltyWhenPressure,
    'Trade goal penalty under colonial pressure.',
  ),
  _vcInt(
    'kEmergencyTradeGoalDominantFloor',
    kEmergencyTradeGoalDominantFloor,
    'Trade goal floor when the GP treasury is broke.',
  ),
  _vcInt(
    'kTreasuryAcquisitionTradeBoostMax',
    kTreasuryAcquisitionTradeBoostMax,
    'Peak trade goal boost when treasury is below a regiment build cost.',
  ),
  _vcInt(
    'kMinimumColonialExpandScoreWhenPressure',
    kMinimumColonialExpandScoreWhenPressure,
    'Expand floor under colonial pressure.',
  ),
  _vcInt(
    'kMinimumColonialConquerScoreWhenPressure',
    kMinimumColonialConquerScoreWhenPressure,
    'Conquer floor under colonial pressure.',
  ),
  _vcInt(
    'kDiplomacyDeclareWarMinWeightWhenColonialPressure',
    kDiplomacyDeclareWarMinWeightWhenColonialPressure,
    'Minimum declare-war diplomacy pass weight under colonial pressure.',
  ),
  _vcInt(
    'kConquestArmyMoveMinWeightWhenColonialPressure',
    kConquestArmyMoveMinWeightWhenColonialPressure,
    'Minimum conquest army-move pass weight under colonial pressure.',
  ),
  _vcInt(
    'kExploreWorkScoreBonusNewWorld',
    kExploreWorkScoreBonusNewWorld,
    'Explore-work score bonus when the target tile is in the New World.',
  ),
  _vcInt(
    'kBuildImprovementExtractableResourceScore',
    kBuildImprovementExtractableResourceScore,
    'Build-improvement score for an unimproved extractable resource tile.',
  ),
  _vcInt(
    'kBuildImprovementNewWorldResourceBonus',
    kBuildImprovementNewWorldResourceBonus,
    'Extra build-improvement score on unimproved NW extractable tiles.',
  ),
  _vcInt(
    'kBuildImprovementOwnedNewWorldResourceBonus',
    kBuildImprovementOwnedNewWorldResourceBonus,
    'Extra build-improvement score on owned NW extractable tiles.',
  ),
  _vcInt(
    'kPurchaseLandNewWorldTribeWorkScore',
    kPurchaseLandNewWorldTribeWorkScore,
    'Merchant purchase_land score for NW tribe/minor tiles.',
  ),
  _vcInt(
    'kPurchaseLandNewWorldOtherWorkScore',
    kPurchaseLandNewWorldOtherWorkScore,
    'Merchant purchase_land score for other NW tiles.',
  ),
  _vcInt(
    'kColonialCivilianWorkThresholdCap',
    kColonialCivilianWorkThresholdCap,
    'Civilian work economy threshold cap when colonial targets are visible.',
  ),
  _vcInt(
    'kColonialBuildOrderThresholdWhenOwnedNwUnderPressure',
    kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
    'Build-order economy threshold cap under COLONIAL acquisition pressure.',
  ),
  _vcInt(
    'kColonialNavalMissionNwPortScore',
    kColonialNavalMissionNwPortScore,
    'Naval mission score when the target port is a New World port.',
  ),
  _vcInt(
    'kColonialNavalMissionPhasePriorityNwPortScore',
    kColonialNavalMissionPhasePriorityNwPortScore,
    'Naval mission score for a phase-priority New World port.',
  ),
  _vcInt(
    'kColonialNavalMissionNwProvinceScore',
    kColonialNavalMissionNwProvinceScore,
    'Naval mission score when the target province is in the New World.',
  ),
  _vcInt(
    'kColonialNavalMissionPhasePriorityNwProvinceScore',
    kColonialNavalMissionPhasePriorityNwProvinceScore,
    'Naval mission score for a phase-priority New World province.',
  ),
  _vcInt(
    'kColonialNavalMissionBeachheadScore',
    kColonialNavalMissionBeachheadScore,
    'Naval mission score for beachhead missions under colonial pressure.',
  ),
  _vcInt(
    'kDeclareWarColonialNwTribeDominanceBonus',
    kDeclareWarColonialNwTribeDominanceBonus,
    'Extra declare-war weight for tribes owning sea-reachable NW provinces.',
  ),
  _vcInt(
    'kDeclareWarColonialNwTribePriorityOverOwMinorBonus',
    kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
    'Tribe declare-war weight to beat OW minor bonuses under colonial pressure.',
  ),
  _vcInt(
    'kDeclareWarStalledLowWarLikelihoodMinorBonus',
    kDeclareWarStalledLowWarLikelihoodMinorBonus,
    'Declare-war bonus for low-warLikelihood leaders toward stalled minors.',
  ),
  _vcInt(
    'kDeclareWarStalledLowWarLikelihoodMinorFloor',
    kDeclareWarStalledLowWarLikelihoodMinorFloor,
    'Declare-war floor for low-warLikelihood leaders toward stalled minors.',
  ),
  _vcInt(
    'kDeclareWarStalledLowWarLikelihoodTribeCap',
    kDeclareWarStalledLowWarLikelihoodTribeCap,
    'Cap NW tribe declare-war for low-warLikelihood leaders while OW minors remain.',
  ),
  _vcInt(
    'kDeclareWarStalledAdjacentInvadableMinorFloor',
    kDeclareWarStalledAdjacentInvadableMinorFloor,
    'Declare-war floor toward adjacent invadable minors while stalled.',
  ),
  _vcInt(
    'kDeclareWarWeakGpAdjacentInvadableMinorFloor',
    kDeclareWarWeakGpAdjacentInvadableMinorFloor,
    'Higher declare-war floor for critically weak GPs toward OW minors.',
  ),
  _vcInt(
    'kDeclareWarCriticalWeakNoGpWarMinorBonus',
    kDeclareWarCriticalWeakNoGpWarMinorBonus,
    'Declare-war bonus toward OW minors when critically weak with no GP war.',
  ),
  _vcInt(
    'kDeclareWarStalledGpWhenMinorsRemainPenalty',
    kDeclareWarStalledGpWhenMinorsRemainPenalty,
    'Declare-war penalty toward adjacent GPs while invadable minors remain.',
  ),
  _vcInt(
    'kDeclareWarOnStalledWeakerNeighborPenalty',
    kDeclareWarOnStalledWeakerNeighborPenalty,
    'Declare-war penalty toward a stalled weaker neighbor GP.',
  ),
  _vcInt(
    'kDeclareWarAggressorSuppressWeakGpLeadThreshold',
    kDeclareWarAggressorSuppressWeakGpLeadThreshold,
    'OW lead over a weak GP above which declare-war is suppressed.',
  ),
  _vcInt(
    'kOfferPeaceWeakVsInvadableBlockerBonus',
    kOfferPeaceWeakVsInvadableBlockerBonus,
    'Offer-peace bonus toward an invadable frontier GP while critically low.',
  ),
  _vcInt(
    'kDeclareWarStalledTribeWhenOwMinorCap',
    kDeclareWarStalledTribeWhenOwMinorCap,
    'Cap NW tribe declare-war scores while invadable OW minors remain.',
  ),
  _vcInt(
    'kDeclareWarColonialPressureOwMinorPenalty',
    kDeclareWarColonialPressureOwMinorPenalty,
    'Declare-war penalty toward OW minors with no NW provinces under pressure.',
  ),
  _vcInt(
    'kDeclareWarStalledWeakerMinorBonus',
    kDeclareWarStalledWeakerMinorBonus,
    'Declare-war bonus for non-adjacent minors weaker than a stalled GP.',
  ),
  _vcInt(
    'kDeclareWarStalledActiveOwMinorBonus',
    kDeclareWarStalledActiveOwMinorBonus,
    'Declare-war weight toward any OW-holding minor while at start size.',
  ),
  _vcInt(
    'kConquestArmyMoveMinWeightWhenStalled',
    kConquestArmyMoveMinWeightWhenStalled,
    'Minimum conquest army-move pass weight when OW expansion is stalled.',
  ),
  _vcInt(
    'kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar',
    kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar,
    'Army-move weight floor when critically weak with no GP war.',
  ),
  _vcDouble(
    'kConquestArmyMoveStalledDeclaredTargetInvadableBonus',
    kConquestArmyMoveStalledDeclaredTargetInvadableBonus,
    'Army-move bonus for invadable provinces of the declared target when stalled.',
  ),
  _vcDouble(
    'kConquestArmyMoveStalledDeclaredTargetBonus',
    kConquestArmyMoveStalledDeclaredTargetBonus,
    'Army-move bonus for any province of the declared target when stalled.',
  ),
  _vcDouble(
    'kConquestArmyMoveAdjacentInvadableBonus',
    kConquestArmyMoveAdjacentInvadableBonus,
    'Army-move bonus when destination is adjacent to an invadable OW province.',
  ),
  _vcDouble(
    'kConquestArmyMoveStalledGpInvadableBlockerBonus',
    kConquestArmyMoveStalledGpInvadableBlockerBonus,
    'Army-move bonus for invadable provinces of an at-war blocker GP.',
  ),
  _vcDouble(
    'kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince',
    kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince,
    'Extra army-move bonus per OW province the invadable blocker GP leads by.',
  ),
  _vcInt(
    'kOfferPeaceBelowQuotaInvadableBlockerPenalty',
    kOfferPeaceBelowQuotaInvadableBlockerPenalty,
    'Offer-peace penalty toward the frontier blocker GP while below quota.',
  ),
  _vcInt(
    'kOfferPeaceBelowQuotaStartSizeGpWarPenalty',
    kOfferPeaceBelowQuotaStartSizeGpWarPenalty,
    'Offer-peace penalty toward any GP while at start size and below quota.',
  ),
  _vcDouble(
    'kConquestArmyMoveAdjacentAtWarFrontierBonus',
    kConquestArmyMoveAdjacentAtWarFrontierBonus,
    'Army-move bonus for own provinces bordering an at-war faction.',
  ),
  _vcInt(
    'kDeclareWarStalledWeakestInvadableGpBonus',
    kDeclareWarStalledWeakestInvadableGpBonus,
    'Declare-war bonus when the weakest invadable-border GP blocks expansion.',
  ),
  _vcInt(
    'kDeclareWarStalledInvadableGpBlockerBonus',
    kDeclareWarStalledInvadableGpBlockerBonus,
    'Declare-war bonus toward a weaker adjacent GP owning invadable OW land.',
  ),
  _vcInt(
    'kDeclareWarStalledGpInvadableBlockerFloor',
    kDeclareWarStalledGpInvadableBlockerFloor,
    'Declare-war floor toward the GP owning invadable OW frontier.',
  ),
  _vcInt(
    'kDeclareWarStalledGpBlockerDistantMinorBonus',
    kDeclareWarStalledGpBlockerDistantMinorBonus,
    'Declare-war bonus toward a distant minor while OW land is GP-blocked.',
  ),
  _vcInt(
    'kDeclareWarDefaultStartOwMinorBonus',
    kDeclareWarDefaultStartOwMinorBonus,
    'Declare-war bonus on any OW minor while at default observer start size.',
  ),
  _vcInt(
    'kDeclareWarStalledAnyOwMinorBonus',
    kDeclareWarStalledAnyOwMinorBonus,
    'Declare-war bonus toward any OW-holding minor while stalled.',
  ),
];
