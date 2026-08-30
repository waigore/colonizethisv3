/// Victory-config GA params: observer conquest floor and COLONIAL-lite family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// observer conquest floor and COLONIAL-lite family.
final List<AiParameter> victoryConfigParamsObserverColonialLite = <AiParameter>[
  victoryConfigIntParam(
    'kObserverConquestMinOwProvincesPerGp',
    kObserverConquestMinOwProvincesPerGp,
    'Observer per-GP turn-100 conquest quota in OW provinces.',
  ),
  victoryConfigIntParam(
    'kObserverColonialLiteMinTurn',
    kObserverColonialLiteMinTurn,
    'Turn when near-quota EXPAND GPs may enter COLONIAL-lite.',
  ),
  victoryConfigIntParam(
    'kObserverColonialLiteNearQuotaOw',
    kObserverColonialLiteNearQuotaOw,
    'OW holdings at or above which COLONIAL-lite is enabled while below quota.',
  ),
];
