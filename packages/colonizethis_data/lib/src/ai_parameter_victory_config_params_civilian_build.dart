/// Victory-config GA params: civilian-build planner scalars.
///
/// Previously missing from the registry (Refs #4072).
/// SPEC/ai/ai-parameter-registry.md; SPEC/ai/civilian-build-planner.md.
library;

import 'ai_parameter.dart';
import 'ai_parameter_victory_config_param_helpers.dart';
import 'ai_victory_config.dart';

/// Civilian-build planner victory-config parameters.
final List<AiParameter> victoryConfigParamsCivilianBuild = <AiParameter>[
  victoryConfigDoubleParam(
    'kCivilianBuildBaseScore',
    kCivilianBuildBaseScore,
    'Base score for a civilian build candidate before multipliers.',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildMinCapScoreBoost',
    kCivilianBuildMinCapScoreBoost,
    'Hard-floor multiplier when civilian count is below per-type minCount.',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildReplacementUrgencyFactor',
    kCivilianBuildReplacementUrgencyFactor,
    'Replacement-urgency factor while between minCount and targetCount.',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildPhaseMultiplierBase',
    kCivilianBuildPhaseMultiplierBase,
    'Neutral per-phase civilian build multiplier (no phase preference).',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildPhaseMultiplierFavored',
    kCivilianBuildPhaseMultiplierFavored,
    'Multiplier for a civilian type favored by the active phase.',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildSpyPhaseFlatMultiplier',
    kCivilianBuildSpyPhaseFlatMultiplier,
    'Phase-flat Spy build multiplier (identical across every phase).',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildSpyDemandBoost',
    kCivilianBuildSpyDemandBoost,
    'Spy intelligence/war-demand boost when at war or tech-steal posture.',
  ),
  victoryConfigIntParam(
    'kCivilianBuildMinSpies',
    kCivilianBuildMinSpies,
    'GA-tunable Spy floor mirroring minCount for Spy.',
  ),
  victoryConfigIntParam(
    'kCivilianBuildSpyTechStealDeficit',
    kCivilianBuildSpyTechStealDeficit,
    'Minimum rival unlocked-tech lead that triggers Spy tech-steal posture.',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildPoolWeight',
    kCivilianBuildPoolWeight,
    'Shared civilian-build pool-weight market-share ceiling [0.0, 1.0].',
  ),
  victoryConfigDoubleParam(
    'kCivilianBuildResearchPaperReserveShare',
    kCivilianBuildResearchPaperReserveShare,
    'Fraction of current paper reserved for research before build spend.',
  ),
];
