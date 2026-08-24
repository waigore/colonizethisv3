/// Victory-config GA params: defend when few Old World holdings family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// defend when few Old World holdings family.
final List<AiParameter> victoryConfigParamsDefendFewOw = <AiParameter>[
  victoryConfigIntParam(
    'kDefendBonusWhenFewOldWorldProvinces',
    kDefendBonusWhenFewOldWorldProvinces,
    'Defend goal bonus while OW holdings are small and far from victory.',
  ),
  victoryConfigIntParam(
    'kDefendBonusWhenAtWarAndFewHoldings',
    kDefendBonusWhenAtWarAndFewHoldings,
    'Extra defend weight when at war and OW holdings are few.',
  ),
  victoryConfigIntParam(
    'kFewOldWorldProvincesDefendThreshold',
    kFewOldWorldProvincesDefendThreshold,
    'OW province count at or below which the few-holdings defend bonus applies.',
  ),
];
