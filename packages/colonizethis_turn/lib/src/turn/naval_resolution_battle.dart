import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_resolution_seeds.dart';

// Naval-battle victor resolution plus dossier/dialogue side effects for naval
// resolution (Refs #3290 Phase-0 file-split, #3416 part-of -> explicit
// library). This is a proper library imported by `naval_resolution.dart`; the
// public helpers below stay unexported from the package barrel, so the public
// API is unchanged.

String? navalBattleWinnerOwnerId(
  NavalBattleOutcome outcome,
  BattleContextSea battle,
) {
  switch (outcome) {
    case NavalBattleOutcome.side1Victory:
      return battle.side1.ownerId;
    case NavalBattleOutcome.side2Victory:
      return battle.side2.ownerId;
    case NavalBattleOutcome.stalemate:
    case NavalBattleOutcome.mutualDestruction:
      return null;
  }
}

Game applyNavalBattleVictoryDossierAndDialogue({
  required Game state,
  required BattleContextSea battle,
  required NavalBattleResult result,
  required int turn,
  required int battleIndex,
  required int seedAfterBattle,
  void Function(DialogueEvent)? onDialogue,
}) {
  String? victorId;
  String? loserId;
  if (result.survivingShipsSide1.isEmpty &&
      result.survivingShipsSide2.isNotEmpty) {
    victorId = battle.side2.ownerId;
    loserId = battle.side1.ownerId;
  } else if (result.survivingShipsSide2.isEmpty &&
      result.survivingShipsSide1.isNotEmpty) {
    victorId = battle.side1.ownerId;
    loserId = battle.side2.ownerId;
  }
  if (victorId == null || loserId == null) return state;

  var next = state;
  final evidence = evidenceForNavalBattleVictory(next, victorId, loserId, turn);
  if (evidence.isNotEmpty) {
    next = next.copyWith(
      dossierEvidenceEntries: [...next.dossierEvidenceEntries, ...evidence],
    );
  }
  final dialogueSeed =
      (seedAfterBattle ^ (battleIndex * kTurnResolutionSeedMix)) &
      kTurnResolutionLcgMask;
  final events = dialogueEventsForNavalBattleResult(
    next,
    victorId,
    loserId,
    turn,
    dialogueSeed,
  );
  if (onDialogue != null && events.isNotEmpty) {
    for (final e in events) {
      onDialogue(e);
    }
  }
  return next;
}
