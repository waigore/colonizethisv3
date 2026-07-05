// Advanced-start bootstrap. SPEC/game/advanced-starts.md, SPEC/program/game-setup-pipeline.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'setup_logging.dart';

/// Mutates a fully initialized turn-0 [Game] per [config.advancedStart].
///
/// Steps implemented incrementally; this slice covers turn number, tech unlocks,
/// treasury, and workforce (bootstrap steps 1–4). Returns [game] unchanged when
/// [AdvancedStartType.none] or when the config is not the locked full-init profile.
Game applyAdvancedStartBootstrap({
  required Game game,
  required GameSetupConfig config,
}) {
  final startType = config.advancedStart;
  if (startType == AdvancedStartType.none) {
    return game;
  }
  if (!config.isLockedFullInitProfile) {
    setupLog.w(
      'logic: advanced start ${startType.name} skipped — '
      'requires locked full-init profile',
    );
    return game;
  }

  final tier = advancedStartTierParams(startType);
  final techIds = advancedStartTechIds(startType);
  validateAdvancedStartTechList(techIds);

  final updatedPlayers = game.players.map((player) {
    final techUnlocked = Map<String, bool>.from(player.techUnlocked ?? {});
    for (final techId in techIds) {
      techUnlocked[techId] = true;
    }
    return player.copyWith(
      treasury: tier.treasury,
      workerPool: WorkerPool(
        peasants: tier.peasants,
        apprentices: tier.apprentices,
      ),
      techUnlocked: techUnlocked,
    );
  }).toList();

  final turnNumber = startType.startTurnNumber;
  final updatedWorldState = game.worldState.copyWith(
    turnState: game.worldState.turnState.copyWith(turnNumber: turnNumber),
  );

  setupLog.i(
    'logic: advanced start ${startType.name} applied turn=$turnNumber '
    'techs=${techIds.length} treasury=${tier.treasury}',
  );

  return game.copyWith(
    players: updatedPlayers,
    worldState: updatedWorldState,
    advancedStartType: startType,
  );
}
