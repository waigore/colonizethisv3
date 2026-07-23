/// Offer-peace and mutual-exhaustion stalemate constants.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

import 'ai_victory_config_observer.dart';

/// Offer-peace bonus toward a minor/tribe at war that no longer owns invadable land.
const int kOfferPeaceFutileMinorWarBonus = 80;

/// Penalty for offering peace to a minor that still owns invadable OW land while
/// below the observer quota at default start size (seed-42 gp4; Refs #2509).
const int kOfferPeaceBelowQuotaActiveMinorWarPenalty = 500;

/// Offer-peace bonus toward a stronger adjacent GP while Old World expansion is
/// stalled and that GP owns the invadable frontier (exit unwinnable wars; #2509).
const int kOfferPeaceStalledStrongerGpBlockerBonus = 240;

/// Offer-peace bonus toward a Great Power at war that owns none of this GP's
/// invadable Old World provinces while minors still hold invadable land
/// (exit distracting GP wars; observer seed-42 gp4/gp6; Refs #2509).
const int kOfferPeaceStalledFutileGpWarBonus = 230;

/// Offer-peace toward the sole GP enemy when this GP meets the observer quota and
/// leads that enemy by at least this many OW provinces (lock gains; Refs #2509).
const int kConsolidateGainsSoleGpProvinceLead = 3;

/// Enemy must lead by at least this many OW provinces for
/// [unwinnableSoleGpFrontierPeaceTarget] (avoid premature sole-GP peace).
const int kUnwinnableSoleGpMinProvinceDeficit = 2;

/// Offer-peace bonus toward any at-war Great Power when stalled with zero regiments
/// (exit unwinnable GP wars before elimination; observer seed-42 gp3; Refs #2509).
const int kOfferPeaceStalledZeroRegimentGpWarBonus = 270;

/// OW province floor for `mutualExhaustedBelowQuotaGpStalematePeaceTargets`
/// (Refs #2509). Excludes early-game / collapsed-survival GPs whose stalemate
/// is already handled by [criticalWeakGpSurvivalPeaceTargets]; targets the
/// late-stalled "8-9 plateau" band specifically.
const int kMutualExhaustedGpStalemateMinOw =
    kObserverDefaultStartOldWorldProvincesPerGp + 1;

/// Regiment ceiling under which a Great Power is treated as militarily exhausted
/// for the mutual-stalemate peace check (Refs #2509; observer seed-42 gp3/gp4
/// 3-regiment plateau). Above this threshold, the GP can still field meaningful
/// force and the war is not considered terminally exhausted.
const int kMutualExhaustedGpRegimentMax = 4;

/// Treasury ceiling (pounds) under which a Great Power is treated as economically
/// exhausted for the mutual-stalemate peace check (Refs #2509). Combined with the
/// regiment ceiling, this targets GPs that cannot rebuild offensive force while
/// the war continues.
/// Includes seed-42 gp3 plateau treasury (~50) so mutual-exhausted peace can
/// fire alongside gp4 (0 treasury) and end the sole GP-blocker war (Refs #2509).
const int kMutualExhaustedGpTreasuryMax = 55;

/// Offer-peace bonus toward the sole at-war Great Power when both sides are
/// mutual-plateau peers below the observer quota AND both are exhausted in
/// regiments and treasury (Refs #2509; observer seed-42 gp3/gp4 stalemate). Sized
/// above [kOfferPeaceStalledZeroRegimentGpWarBonus] so a mutually-exhausted
/// stalemate outranks single-side zero-regiment exits but stays below the strong
/// blocker survival bonus.
const int kOfferPeaceMutualExhaustedGpStalemateBonus = 280;

/// Offer-peace bonus for [unwinnableSoleGpFrontierPeaceTarget] (Refs #2509).
const int kOfferPeaceUnwinnableSoleGpWarBonus = 250;

/// Offer-peace bonus for [consolidateGainsSoleGpPeaceTarget] (Refs #2509).
const int kOfferPeaceConsolidateGainsSoleGpWarBonus = 260;

/// Offer-peace bonus toward the invadable OW frontier GP while holdings are
/// critically low and that GP leads by
/// [kDeclareWarAggressorSuppressWeakGpLeadThreshold] or more (Refs #2509).
const int kOfferPeaceWeakVsInvadableBlockerBonus = 260;

/// Penalize offer-peace toward the invadable OW frontier GP while still below
/// the turn-100 observer quota (avoid premature blocker peace; Refs #2509).
const int kOfferPeaceBelowQuotaInvadableBlockerPenalty = 420;

/// Penalize offer-peace toward any Great Power while at default start OW size
/// and below the observer quota (avoid net OW loss; seed-42 gp3; Refs #2509).
const int kOfferPeaceBelowQuotaStartSizeGpWarPenalty = 420;
