/// Victory-config GA params: colonial families.
///
/// Wave-7 Slice C concatenator (Refs #4626). Preserves original element order.
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_params_colonial_naval.dart';
import 'ai_parameter_victory_config_params_colonial_pressure.dart';
import 'ai_parameter_victory_config_params_colonial_conquest.dart';

/// colonial families.
final List<AiParameter> victoryConfigParamsColonial = <AiParameter>[
  ...victoryConfigParamsColonialNaval,
  ...victoryConfigParamsColonialPressure,
  ...victoryConfigParamsColonialConquest,
];
