import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import '../features/game/widgets/technology/technology_panel_open_path.dart';
import 'panel_session_revision.dart'
    show panelOrdersRevision, panelWorldRevision;
import 'games_provider.dart';

final technologyPanelSessionCacheProvider = Provider<TechnologyPanelSessionCache>(
  (ref) => TechnologyPanelSessionCache(),
);

TechnologyPanelSessionRevision technologyPanelSessionRevision({
  required Game game,
  required String humanPlayerId,
  required Orders orders,
  required bool canEdit,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
    humanPlayerId: humanPlayerId,
    ordersRevision: panelOrdersRevision(orders),
    canEdit: canEdit,
  );
}

/// Session-cached Slots-tab open path for `GAME40001` reopen (Refs #4688 Slice 7).
final technologyPanelSlotsOpenPathProvider =
    Provider.autoDispose<TechnologyPanelSlotsOpenPathSnapshot?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final orders = ref.watch(currentOrdersProvider);
  final shell = ref.watch(shellPlayerContextProvider);
  final humanPlayerId = resolveShellPanelPlayerId(shell, game);
  final player = game.playerById(humanPlayerId);
  if (player == null) return null;

  final revision = technologyPanelSessionRevision(
    game: game,
    humanPlayerId: humanPlayerId,
    orders: orders,
    canEdit: shell.canMutateViaUi,
  );
  return resolveTechnologyPanelSlotsOpenPath(
    cache: ref.read(technologyPanelSessionCacheProvider),
    revision: revision,
    game: game,
    player: player,
    orders: orders,
  );
});
