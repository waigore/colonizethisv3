/// Victory-config GA params: declare-war Great Power and adjacency family.
///
/// Wave-7 Slice C topic split (Refs #4626). SPEC/ai/ai-parameter-registry.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// declare-war Great Power and adjacency family.
final List<AiParameter> victoryConfigParamsDeclareWarGp = <AiParameter>[
  victoryConfigIntParam(
    'kDeclareWarMinorMaxRelationWhenFarFromVictory',
    kDeclareWarMinorMaxRelationWhenFarFromVictory,
    'Declare-war relation cap for minor/tribe targets when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarGpWeakNeighborBonus',
    kDeclareWarGpWeakNeighborBonus,
    'Declare-war bonus toward a weak-neighbor Great Power.',
  ),
  victoryConfigIntParam(
    'kDeclareWarGpWeakNeighborMinWarDesire',
    kDeclareWarGpWeakNeighborMinWarDesire,
    'Minimum war-desire for the weak-neighbor GP declare-war bonus.',
  ),
  victoryConfigIntParam(
    'kDeclareWarGpMaxRelationWhenFarFromVictory',
    kDeclareWarGpMaxRelationWhenFarFromVictory,
    'Declare-war relation cap for adjacent GP targets when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAdjacentOwnerBonus',
    kDeclareWarAdjacentOwnerBonus,
    'Declare-war bonus toward an adjacent Old World province owner.',
  ),
  victoryConfigIntParam(
    'kDeclareWarLowWarLikelihoodAdjacentBonus',
    kDeclareWarLowWarLikelihoodAdjacentBonus,
    'Extra declare-war bonus for low-warLikelihood personalities.',
  ),
  victoryConfigIntParam(
    'kDeclareWarLowWarLikelihoodThreshold',
    kDeclareWarLowWarLikelihoodThreshold,
    'warLikelihood at or below which the low-warLikelihood bonus applies.',
  ),
  victoryConfigIntParam(
    'kDeclareWarNonAdjacentSuppressedScore',
    kDeclareWarNonAdjacentSuppressedScore,
    'Declare-war score for suppressed non-adjacent targets.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAdjacentGpBonusWhenFarFromVictory',
    kDeclareWarAdjacentGpBonusWhenFarFromVictory,
    'Declare-war bonus toward an adjacent GP when far from victory.',
  ),
  victoryConfigIntParam(
    'kDeclareWarAdjacentMinorBonusWhenFarFromVictory',
    kDeclareWarAdjacentMinorBonusWhenFarFromVictory,
    'Declare-war bonus toward an adjacent minor/tribe when far from victory.',
  ),
  victoryConfigIntParam(
    'kSuppressGpDeclareWarMinProvincesToVictory',
    kSuppressGpDeclareWarMinProvincesToVictory,
    'Provinces-to-victory above which GP declare-war is suppressed.',
  ),
];
