part of 'naval_resolution.dart';

// Naval-battle victor resolution plus dossier/dialogue side effects for naval
// resolution (Refs #3290 Phase-0 file-split). Behaviour-preserving move: same
// library scope as `naval_resolution.dart`, so imports, shared helpers, and
// visibility are unchanged.

String? _navalBattleWinnerOwnerId(
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

Game _applyNavalBattleVictoryDossierAndDialogue({
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
