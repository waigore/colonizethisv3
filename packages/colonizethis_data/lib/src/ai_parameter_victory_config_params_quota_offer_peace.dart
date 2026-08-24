/// Victory-config GA params: below-quota and early offer-peace family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// below-quota and early offer-peace family.
final List<AiParameter> victoryConfigParamsQuotaOfferPeace = <AiParameter>[
  victoryConfigIntParam(
    'kBelowQuotaPeaceMinRegimentsBeforeDeclareWar',
    kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
    'Regiment floor below which a below-quota peaceful GP rebuilds first.',
  ),
  victoryConfigIntParam(
    'kBelowQuotaPeaceTreasuryRecoveryCargoBoost',
    kBelowQuotaPeaceTreasuryRecoveryCargoBoost,
    'Cargo economy boost when a below-quota GP cannot afford a regiment.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceFutileMinorWarBonus',
    kOfferPeaceFutileMinorWarBonus,
    'Offer-peace bonus toward a minor/tribe with no invadable land left.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceBelowQuotaActiveMinorWarPenalty',
    kOfferPeaceBelowQuotaActiveMinorWarPenalty,
    'Penalty for offering peace to a minor still holding invadable OW land.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceStalledStrongerGpBlockerBonus',
    kOfferPeaceStalledStrongerGpBlockerBonus,
    'Offer-peace bonus toward a stronger adjacent GP blocking the frontier.',
  ),
  victoryConfigIntParam(
    'kOfferPeaceStalledFutileGpWarBonus',
    kOfferPeaceStalledFutileGpWarBonus,
    'Offer-peace bonus toward a GP owning none of this GP\'s invadable land.',
  ),
];
