import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// AI control helpers: which GPs are AI-controlled, seeds, and config wiring.
/// SPEC/program/ai-planner.md, SPEC/ai/economy-planner.md.

/// Returns true if [gpId] is AI-controlled. Uses [Game.aiControlByGpId] when
/// present, otherwise !player.isHuman.
bool isAiControlled(Game game, String gpId) {
  final explicit = game.aiControlByGpId[gpId];
  if (explicit != null) return explicit;
  final player = game.playerById(gpId);
  return player != null && !player.isHuman;
}

