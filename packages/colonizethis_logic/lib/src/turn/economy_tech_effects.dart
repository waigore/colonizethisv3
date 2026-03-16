import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_rules.dart';

/// Central helpers for economy and labour tech effects that touch turn
/// resolution state (e.g. research slot count).
///
/// SPEC/game/tech-tree-labour-economy.md
/// SPEC/program/research-resolution.md

/// Compute the effective number of research slots for a player given the
/// currently unlocked techs.
///
/// The base number of slots comes from `defaultResearchSlots`; labour/economy
/// techs such as `university` may add additional slots.
int researchSlotsForUnlockedTechs(
  Player player,
  Map<String, bool> unlocked,
) {
  final baseSlots = player.researchSlots ?? defaultResearchSlots;
  if (unlocked['university'] == true) {
    // University: fourth research slot (SPEC/game/tech-tree-labour-economy.md).
    return baseSlots < 4 ? 4 : baseSlots;
  }
  return baseSlots;
}

