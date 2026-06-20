import 'package:colonizethis_models/colonizethis_models.dart';

/// Applies the canonical Full-AI observer handoff to [game] for integration
/// tests (Refs #2924).
///
/// Sets every player `isHuman: false` and enables AI control for all Great
/// Powers. Mirrors `ObserveSessionController.applyObserveHandoffIfNeeded`
/// full-AI branch and `run_observer_game` once #3176 lands
/// (`humanGreatPowerSlotIndices: {}` at init).
///
/// Without clearing `isHuman`, init defaults slot 0 (`gp1`) to human while only
/// `aiControlByGpId` is overridden. The diplomacy intervention resolver then
/// pauses turn resolution with `TurnResolutionPendingIntervention` when gp1 is
/// eligible to intervene — invalid for Full-AI observer acceptance runs.
Game applyFaithfulFullAiTestHandoff(Game game) {
  return game.copyWith(
    players: [
      for (final p in game.players) p.copyWith(isHuman: false),
    ],
    aiControlByGpId: {for (final p in game.players) p.id: true},
  );
}
