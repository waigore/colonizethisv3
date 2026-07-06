// Advanced-start bootstrap. SPEC/game/advanced-starts.md, SPEC/program/game-setup-pipeline.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_bootstrap_colonization.dart';
import 'advanced_start_bootstrap_development.dart';
import 'advanced_start_bootstrap_diplomacy.dart';
import 'advanced_start_bootstrap_units.dart';
import 'advanced_start_bootstrap_world.dart';
import 'setup_logging.dart';

/// Mutates a fully initialized turn-0 [Game] per [config.advancedStart].
///
/// Returns [game] unchanged when [AdvancedStartType.none] or when the config is
/// not the locked full-init profile.
Game applyAdvancedStartBootstrap({
  required Game game,
  required GameSetupConfig config,
  MapTopology? topologyOldWorld,
  MapTopology? topologyNewWorld,
  List<WarpLink> warpLinks = const [],
  Map<String, TileMapResult> tileMapByRegion = const {},
  Map<String, MapTopology> topologyByRegion = const {},
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

  var encounteredTribeIds = <String>{};
  if (topologyOldWorld != null && topologyNewWorld != null) {
    final worldResult = applyAdvancedStartWorldKnowledge(
      game: updated,
      startType: startType,
      topologyOldWorld: topologyOldWorld,
      topologyNewWorld: topologyNewWorld,
      warpLinks: warpLinks,
    );
    updated = worldResult.game;
    encounteredTribeIds = worldResult.encounteredTribeIds;
  } else {
    setupLog.w(
      'logic: advanced start NW exploration skipped — missing topology',
    );
  }

  updated = applyAdvancedStartDiplomacy(
    game: updated,
    startType: startType,
    encounteredTribeIds: encounteredTribeIds,
  );

  if (topologyOldWorld != null &&
      topologyNewWorld != null &&
      tileMapByRegion.isNotEmpty) {
    final topoByRegion = topologyByRegion.isNotEmpty
        ? topologyByRegion
        : {
            kRegionOldWorld: topologyOldWorld,
            kRegionNewWorld: topologyNewWorld,
          };

    updated = applyAdvancedStartNwColonization(
      game: updated,
      startType: startType,
      topologyOldWorld: topologyOldWorld,
      topologyNewWorld: topologyNewWorld,
      warpLinks: warpLinks,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topoByRegion,
    );

    updated = applyAdvancedStartCoastalSeaVisibility(
      game: updated,
      topologyByRegion: topoByRegion,
    );

    updated = applyAdvancedStartDevelopment(
      game: updated,
      startType: startType,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topoByRegion,
    );
  } else if (startType != AdvancedStartType.none) {
    setupLog.w(
      'logic: advanced start colonization/development skipped — '
      'missing tile maps',
    );
  }

  setupLog.i(
    'logic: advanced start ${startType.name} applied turn=$turnNumber '
    'techs=${techIds.length} treasury=${tier.treasury} '
    'regiments=${advancedStartRegimentCount(startType)} '
    'ships=${advancedStartCargoShipCount(startType)}',
  );

  return updated;
}
