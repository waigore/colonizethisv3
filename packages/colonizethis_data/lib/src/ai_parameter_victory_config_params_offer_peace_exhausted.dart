/// Victory-config GA params: develop, consolidate, exhausted, and remaining offer-peace family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// develop, consolidate, exhausted, and remaining offer-peace family.
final List<AiParameter> victoryConfigParamsOfferPeaceExhausted = <AiParameter>[
  victoryConfigIntParam(
    'kDevelopCivilianWorkThresholdCap',
    kDevelopCivilianWorkThresholdCap,
    'Civilian work threshold cap in the DEVELOP phase.',
  ),
  victoryConfigIntParam(
    'kConsolidateGainsSoleGpProvinceLead',
    kConsolidateGainsSoleGpProvinceLead,
    'OW province lead over sole GP enemy to consolidate gains via peace.',
  ),
  victoryConfigIntParam(
    'kObserverConquestConsolidateMinOwProvinces',
    kObserverConquestConsolidateMinOwProvinces,
    'Minimum OW holdings before consolidate-gains sole-GP peace may fire.',
  ),
  victoryConfigIntParam(
    'kUnwinnableSoleGpMinProvinceDeficit',
    kUnwinnableSoleGpMinProvinceDeficit,
    'OW province deficit for the unwinnable sole-GP frontier peace.',
  ),
  victoryConfigIntParam(
    'kDeclareWarBelowObserverQuotaMinorBonus',
    kDeclareWarBelowObserverQuotaMinorBonus,
    'Declare-war bonus on adjacent invadable OW minors while below quota.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceStalledZeroRegimentGpWarBonus',
    kOfferPeaceStalledZeroRegimentGpWarBonus,
    'Offer-peace bonus toward any at-war GP when stalled with zero regiments.',
  ),
  victoryConfigIntParam(
    'kMutualExhaustedGpStalemateMinOw',
    kMutualExhaustedGpStalemateMinOw,
    'OW floor for the mutual-exhausted GP stalemate peace check.',
  ),
  victoryConfigIntParam(
    'kMutualExhaustedGpRegimentMax',
    kMutualExhaustedGpRegimentMax,
    'Regiment ceiling under which a GP is treated as militarily exhausted.',
  ),
  victoryConfigIntParam(
    'kMutualExhaustedGpTreasuryMax',
    kMutualExhaustedGpTreasuryMax,
    'Treasury ceiling under which a GP is treated as economically exhausted.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceMutualExhaustedGpStalemateBonus',
    kOfferPeaceMutualExhaustedGpStalemateBonus,
    'Offer-peace bonus for a mutually-exhausted sole-GP stalemate.',
  ),
  victoryConfigIntParam(
    'kStalledMinRegimentCountWhenCriticallyWeakBelowQuota',
    kStalledMinRegimentCountWhenCriticallyWeakBelowQuota,
    'Regiment floor when critically weak, below quota, and at war.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceUnwinnableSoleGpWarBonus',
    kOfferPeaceUnwinnableSoleGpWarBonus,
    'Offer-peace bonus for the unwinnable sole-GP frontier peace target.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceConsolidateGainsSoleGpWarBonus',
    kOfferPeaceConsolidateGainsSoleGpWarBonus,
    'Offer-peace bonus for the consolidate-gains sole-GP peace target.',
  ),
];
