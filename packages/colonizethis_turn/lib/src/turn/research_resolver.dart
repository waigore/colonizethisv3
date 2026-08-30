import 'turn_logging.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'research_resolver_allocation.dart';

/// Research phase resolution. SPEC/program/research-resolution.md.
Game resolveResearchPhase(Game game, Orders orders) {
  final turn = game.worldState.turnState.turnNumber;
  final researchByPlayer = orders.researchOrdersByPlayerId;
  turnLog.i('research phase start turn=$turn');

  final anyPersistedAssignments = game.players.any(
    (p) => p.researchSlotAssignments?.isNotEmpty ?? false,
  );
  if (researchByPlayer.isEmpty && !anyPersistedAssignments) {
    turnLog.i('research phase end turn=$turn playersWithOrders=0');
    return game;
  }

  final playersWithOrders = researchByPlayer.values
      .where((o) => o.isNotEmpty)
      .length;
  var state = game;
  final extraEvidence = <DossierEvidenceEntry>[];
  final updatedPlayers = <Player>[];

  for (final p in game.players) {
    final player = state.playerById(p.id)!;
    final playerOrders = researchByPlayer[player.id] ?? const <ResearchOrder>[];
    final hasPersistedAssignments =
        player.researchSlotAssignments?.isNotEmpty ?? false;
    if (playerOrders.isEmpty && !hasPersistedAssignments) {
      updatedPlayers.add(player);
      continue;
    }

    final resolved = resolveResearchForOnePlayer(
      game: game,
      state: state,
      player: player,
      playerOrders: playerOrders,
      turn: turn,
      extraEvidence: extraEvidence,
    );
    state = resolved.state;
    updatedPlayers.add(resolved.updatedPlayer!);
  }

  turnLog.i(
    'research phase end turn=$turn playersWithOrders=$playersWithOrders',
  );
  final resolvedState = state.copyWith(
    players: updatedPlayers,
    dossierEvidenceEntries: [...state.dossierEvidenceEntries, ...extraEvidence],
  );

  return syncGeneralCapsFromTech(resolvedState);
}
