/// Victory-config GA params: colonial pressure leftover and establish-overture family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// colonial pressure leftover and establish-overture family.
final List<AiParameter> victoryConfigParamsColonialOverture = <AiParameter>[
  victoryConfigIntParam(
    'kColonialExpandBonusWhenInvadableNw',
    kColonialExpandBonusWhenInvadableNw,
    'Expand-goal bonus when invadable New World provinces exist.',
  ),
  victoryConfigIntParam(
    'kColonialConquerBonusWhenInvadableNw',
    kColonialConquerBonusWhenInvadableNw,
    'Conquer-goal bonus for colonial pressure below OW victory floors.',
  ),
  victoryConfigIntParam(
    'kDeclareWarColonialAdjacentTribeBonus',
    kDeclareWarColonialAdjacentTribeBonus,
    'Declare-war bonus toward a tribe/minor owning adjacent NW provinces.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureColonialTribeBonus',
    kEstablishOvertureColonialTribeBonus,
    'Establish-overture bonus toward a preferred colonial tribe target.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureColonialInvadableOwnerBonus',
    kEstablishOvertureColonialInvadableOwnerBonus,
    'Establish-overture bonus toward a sea-reachable NW province owner.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureDecayCreditMax',
    kEstablishOvertureDecayCreditMax,
    'Max improve-relations reduction credited to natural relation decay.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureFtpCompetitionBonus',
    kEstablishOvertureFtpCompetitionBonus,
    'Overture incentive when not the favoured trading partner for a '
        'Minor/Tribe target.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureEmbassyKickbackBonusMax',
    kEstablishOvertureEmbassyKickbackBonusMax,
    'Max improve-relations desire bonus from embassy commodity kickbacks.',
  ),
  victoryConfigIntParam(
    'kEstablishOvertureEmbassyKickbackVolumeFull',
    kEstablishOvertureEmbassyKickbackVolumeFull,
    'Seller resource-tile count at which embassy kickback bonus saturates.',
  ),
];
