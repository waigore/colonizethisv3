/// Victory-config GA params: colonial cargo and naval family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// colonial cargo and naval family.
final List<AiParameter> victoryConfigParamsColonialNaval = <AiParameter>[
  victoryConfigIntParam(
    'kConquestArmyMoveNwInvadableBonus',
    kConquestArmyMoveNwInvadableBonus,
    'Conquest army-move bonus for New World invadable destinations.',
  ),
  victoryConfigIntParam(
    'kColonialCargoPreferenceEconomyBoost',
    kColonialCargoPreferenceEconomyBoost,
    'Economy-domain cargo-preference boost when colonial targets exist.',
  ),
  victoryConfigIntParam(
    'kColonialCargoPreferenceNoNwColoniesBoost',
    kColonialCargoPreferenceNoNwColoniesBoost,
    'Extra cargo boost when the GP owns no New World provinces yet.',
  ),
  victoryConfigIntParam(
    'kColonialNavalWeightBonus',
    kColonialNavalWeightBonus,
    'Naval planner weight boost when NW invasion/colonization is viable.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMinWeightWhenPressure',
    kColonialNavalMinWeightWhenPressure,
    'Minimum naval planner weight under active colonial pressure.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMoveDockNewWorldPortScore',
    kColonialNavalMoveDockNewWorldPortScore,
    'Naval move score when docking at a New World port under pressure.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMovePriorityNwSeaZoneScore',
    kColonialNavalMovePriorityNwSeaZoneScore,
    'Naval move score for an NW sea zone bordering an invadable province.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMovePhasePriorityNwSeaZoneScore',
    kColonialNavalMovePhasePriorityNwSeaZoneScore,
    'Naval move score for an NW sea zone bordering a phase-priority province.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMoveNwSeaZoneScore',
    kColonialNavalMoveNwSeaZoneScore,
    'Naval move score for any other New World sea zone destination.',
  ),
  victoryConfigIntParam(
    'kColonialNavalMoveGatewaySeaZoneScore',
    kColonialNavalMoveGatewaySeaZoneScore,
    'Naval move score for an OW sea zone linked to NW seas.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialInvadableOwnerBonus',
    kDeclareWarColonialInvadableOwnerBonus,
    'Declare-war bonus when target owns a sea-reachable invadable NW province.',
  ),
];
