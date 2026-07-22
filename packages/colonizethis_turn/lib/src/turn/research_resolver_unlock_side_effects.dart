import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

/// Applies per-tech unlock side-effects (human category tracking, AI envy
/// evidence) after research completion. SPEC/program/research-resolution.md.
({Game state, Player updated}) applyResearchUnlockSideEffects({
  required Game state,
  required Player player,
  required List<String> toUnlock,
  required int turn,
  required List<DossierEvidenceEntry> extraEvidence,
}) {
  var nextState = state;
  for (final techId in toUnlock) {
    final techMeta = techById(techId);
    final cat = techMeta?.category;
    if (cat != null && cat.isNotEmpty && player.isHuman) {
      nextState = nextState.copyWith(
        lastHumanCompletedResearchCategory: cat,
        lastHumanResearchCategoryCompletionTurn: turn,
      );
    }
  }
  for (final techId in toUnlock) {
    final techMeta = techById(techId);
    final cat = techMeta?.category;
    if (cat != null &&
        cat.isNotEmpty &&
        !player.isHuman &&
        isAiControlledForEvidence(nextState, player.id)) {
      extraEvidence.addAll(
        evidenceForEnvyResearchMirror(
          nextState,
          player.id,
          cat,
          turn,
          extraEvidence,
        ),
      );
    }
  }
  return (state: nextState, updated: player);
}
