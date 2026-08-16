// Maps current Game spy presence to GAME40001 slot-preview inputs (Refs #4457).
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show spyResearchBoostRivalIdsForTech;

/// Qualifying rival count and display names for one assigned tech.
({int count, List<String> names}) spyInsightForResearchPreview({
  required Game game,
  required String playerId,
  required String techId,
}) {
  final ids = spyResearchBoostRivalIdsForTech(
    game: game,
    playerId: playerId,
    techId: techId,
  );
  final byId = <String, Player>{for (final p in game.players) p.id: p};
  final names = <String>[for (final id in ids) byId[id]?.displayName ?? id];
  return (count: ids.length, names: names);
}
