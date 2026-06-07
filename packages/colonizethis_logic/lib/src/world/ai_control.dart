import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// Leaf-layer player-control query.
///
/// Relocated from `lib/src/ai/ai_control.dart` into the `world/` domain so that
/// `diplomacy` (and any other domain) can consume it without a wrong-direction
/// `diplomacy -> ai` import edge. Keeping it in `ai/` would, after the Phase 4
/// `colonizethis_ai_contracts` extraction, create the package cycle
/// `ai_contracts -> orders -> diplomacy -> ai_contracts`.
/// SPEC/program/logic-package-split-phase0.md § `diplomacy ↔ ai`.

/// Returns true if [gpId] is AI-controlled. Uses [Game.aiControlByGpId] when
/// present, otherwise !player.isHuman.
bool isAiControlled(Game game, String gpId) {
  final explicit = game.aiControlByGpId[gpId];
  if (explicit != null) return explicit;
  final player = game.playerById(gpId);
  return player != null && !player.isHuman;
}
