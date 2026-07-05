// Advanced-start bootstrap. SPEC/game/advanced-starts.md, SPEC/program/game-setup-pipeline.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'advanced_start_bootstrap_units.dart';
import 'setup_logging.dart';

/// Mutates a fully initialized turn-0 [Game] per [config.advancedStart].
///
/// Implemented steps: turn number, tech unlocks, treasury, workforce (1–4);
/// civilians, regiments, cargo ships (5–7). Returns [game] unchanged when
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

  var updated = game.copyWith(
    players: updatedPlayers,
    worldState: updatedWorldState,
    advancedStartType: startType,
  );

  updated = applyAdvancedStartUnitsAndShips(
    game: updated,
    startType: startType,
  );

  setupLog.i(
    'logic: advanced start ${startType.name} applied turn=$turnNumber '
    'techs=${techIds.length} treasury=${tier.treasury} '
    'regiments=${advancedStartRegimentCount(startType)} '
    'ships=${advancedStartCargoShipCount(startType)}',
  );

  return updated;
}
