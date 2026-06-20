import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../config/constants.dart';
import '../../../core/services/game_service.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/observe_session_provider.dart';
import '../shell_player_context.dart';

String tribeCapitalDisplayName(Game game, Tribe tribe) {
  final capId = tribe.capitalProvinceId;
  if (capId == null || capId.isEmpty) {
    return tribe.displayName ?? tribe.id;
  }
  for (final p in allProvinces(game.worldState)) {
    if (p.id == capId) {
      return p.displayName ?? ProvinceId.localIdFrom(capId);
    }
  }
  return ProvinceId.localIdFrom(capId);
}

/// Applies persisted GP–Tribe first-contact relations and enqueues heralds
/// for tribes not yet announced this session.
void syncGpTribeFirstContact({
  required Game game,
  required ShellPlayerContext shell,
  required CurrentGameNotifier gameNotifier,
  required GameService gameService,
  required ObserveSessionNotifier observeNotifier,
  required TribeFirstContactHeraldsShownNotifier shownNotifier,
  required TribeFirstContactHeraldQueueNotifier queueNotifier,
}) {
  // Widget tests and Widgetbook mount GameScreen without opening the Hive
  // games box; skip sync until persistence is available.
  if (!Hive.isBoxOpen(HiveBoxNames.games)) return;

  final humanPlayerId =
      shell.panelPlayerId ?? resolveShellPanelPlayerId(shell, game);
  Player? human;
  for (final p in game.players) {
    if (p.id == humanPlayerId) {
      human = p;
      break;
    }
  }
  if (human == null || !human.isHuman) return;

  final mapData = gameService.getMapData(game.id);
  if (mapData == null) return;

  final view = buildPlayerView(game, mapData.combinedTopology, humanPlayerId);
  final result = applyGpTribeFirstContactRelations(
    game: game,
    gpId: humanPlayerId,
    view: view,
    topology: mapData.combinedTopology,
  );
  if (result.newlyContactedTribeIds.isEmpty) return;

  gameNotifier.setGame(result.game);
  final toSave = observeNotifier.prepareGameForPersistence(result.game);
  gameService.saveGame(toSave);

  for (final tribeId in result.newlyContactedTribeIds) {
    if (shownNotifier.isShown(game.id, tribeId)) continue;
    final tribe = result.game.tribes.firstWhere((t) => t.id == tribeId);
    queueNotifier.enqueue(
      TribeFirstContactHeraldPayload(
        tribeId: tribeId,
        tribeName: tribe.displayName ?? tribeId,
        capitalName: tribeCapitalDisplayName(result.game, tribe),
      ),
    );
  }
}

/// Watches [currentGameProvider] and syncs tribe first-contact state after
/// each game update (turn resolution, load, visibility changes).
class TribeFirstContactSyncListener extends ConsumerStatefulWidget {
  const TribeFirstContactSyncListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<TribeFirstContactSyncListener> createState() =>
      _TribeFirstContactSyncListenerState();
}

class _TribeFirstContactSyncListenerState
    extends ConsumerState<TribeFirstContactSyncListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCurrentGame());
  }

  void _syncCurrentGame() {
    if (!mounted) return;
    final game = ref.read(currentGameProvider);
    if (game != null) {
      _syncGame(game);
    }
  }

  void _syncGame(Game game) {
    syncGpTribeFirstContact(
      game: game,
      shell: ref.read(shellPlayerContextProvider),
      gameNotifier: ref.read(currentGameProvider.notifier),
      gameService: ref.read(gameServiceProvider),
      observeNotifier: ref.read(observeSessionProvider.notifier),
      shownNotifier: ref.read(tribeFirstContactHeraldsShownProvider.notifier),
      queueNotifier: ref.read(tribeFirstContactHeraldQueueProvider.notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Game?>(currentGameProvider, (previous, next) {
      if (next != null) {
        _syncGame(next);
      }
    });
    return widget.child;
  }
}
