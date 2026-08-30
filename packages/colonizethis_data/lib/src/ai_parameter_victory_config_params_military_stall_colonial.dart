/// Victory-config GA params: stall, quota/peace, COLONIAL-lite, overture, and colonial families.
///
/// Wave-7 Slice C concatenator (Refs #4626). Preserves original element order.
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_params_military_stall.dart';
import 'ai_parameter_victory_config_params_quota_offer_peace.dart';
import 'ai_parameter_victory_config_params_observer_colonial_lite.dart';
import 'ai_parameter_victory_config_params_offer_peace_exhausted.dart';
import 'ai_parameter_victory_config_params_defend_few_ow.dart';
import 'ai_parameter_victory_config_params_colonial_overture.dart';
import 'ai_parameter_victory_config_params_colonial.dart';

/// stall, quota/peace, COLONIAL-lite, overture, and colonial families.
final List<AiParameter> victoryConfigParamsMilitaryStallColonial =
    <AiParameter>[
      ...victoryConfigParamsMilitaryStall,
      ...victoryConfigParamsQuotaOfferPeace,
      ...victoryConfigParamsObserverColonialLite,
      ...victoryConfigParamsOfferPeaceExhausted,
      ...victoryConfigParamsDefendFewOw,
      ...victoryConfigParamsColonialOverture,
      ...victoryConfigParamsColonial,
    ];
