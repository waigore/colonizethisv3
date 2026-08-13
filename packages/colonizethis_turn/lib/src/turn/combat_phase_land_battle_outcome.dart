import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'turn_event_sink.dart';
import 'turn_resolution_seeds.dart';

/// Appends dossier evidence when [victorId] wins a land battle against [loserId].
Game appendLandBattleVictoryEvidence(
  Game state,
  String victorId,
  String loserId,
  int turn,
) {
  final evidence = evidenceForLandBattleVictory(
    state,
    victorId,
    loserId,
    turn,
  );
  if (evidence.isEmpty) return state;
  return state.copyWith(
    dossierEvidenceEntries: [
      ...state.dossierEvidenceEntries,
      ...evidence,
    ],
  );
}

void emitLandBattleDialogue(
  Game state,
  String victorId,
  String loserId,
  String provinceId,
  int turn,
  int battleIndex,
  int seed,
  TurnEventSink sink,
) {
  if (!sink.hasDialogue) return;
  final dialogueSeed =
      (seed ^ (battleIndex * kTurnResolutionSeedMix)) & kTurnResolutionLcgMask;
  final events = dialogueEventsForLandBattleResult(
    state,
    victorId,
    loserId,
    provinceId,
    turn,
    dialogueSeed,
  );
  if (events.isEmpty) return;
  for (final e in events) {
    sink.dialogue(e);
  }
}
