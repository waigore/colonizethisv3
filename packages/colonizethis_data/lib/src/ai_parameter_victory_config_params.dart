/// Victory-config tunable AI parameters (genetic-algorithm tuning surface).
///
/// One [AiParameter] per behavior-affecting numeric constant in the
/// `ai_victory_config*.dart` modules. Topic-split across military, stall/colonial,
/// work, and civilian-build libraries; this facade concatenates them in
/// canonical order.
/// SPEC/ai/ai-parameter-registry.md. Refs #3436, #3794, #4072.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_params_civilian_build.dart';
import 'ai_parameter_victory_config_params_military.dart';
import 'ai_parameter_victory_config_params_military_stall_colonial.dart';
import 'ai_parameter_victory_config_params_work.dart';

/// All victory-config tunable parameters in canonical declaration order.
final List<AiParameter> victoryConfigParams = <AiParameter>[
  ...victoryConfigParamsMilitary,
  ...victoryConfigParamsMilitaryStallColonial,
  ...victoryConfigParamsWork,
  ...victoryConfigParamsCivilianBuild,
];
