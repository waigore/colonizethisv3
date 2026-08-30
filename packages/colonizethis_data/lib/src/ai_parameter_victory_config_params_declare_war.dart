/// Victory-config GA params: declare-war families.
///
/// Wave-7 Slice C concatenator (Refs #4626). Preserves original element order.
/// SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_params_declare_war_gp.dart';
import 'ai_parameter_victory_config_params_declare_war_minor.dart';

/// declare-war families.
final List<AiParameter> victoryConfigParamsDeclareWar = <AiParameter>[
  ...victoryConfigParamsDeclareWarGp,
  ...victoryConfigParamsDeclareWarMinor,
];
