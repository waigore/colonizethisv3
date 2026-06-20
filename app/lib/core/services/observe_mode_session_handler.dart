import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/shell_player_context.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/observe_session_provider.dart';
import 'game_service.dart';

/// Applies `/observe` session events. SPEC/ui/observe-mode.md.
class ObserveModeSessionHandler {
  const ObserveModeSessionHandler({
    required this.currentGameNotifier,
    required this.observeSessionNotifier,
    required this.gameService,
    required this.readCurrentGame,
    required this.readObserveSession,
  });

  final CurrentGameNotifier currentGameNotifier;
  final ObserveSessionNotifier observeSessionNotifier;
  final GameService gameService;
  final Game? Function() readCurrentGame;
  final ObserveSessionState Function() readObserveSession;

  void applySetObserveModeOff() {
    final game = readCurrentGame();
    if (game == null) {
      observeSessionNotifier.reset();
      return;
    }
    final restored = observeSessionNotifier.applyObserveOff(game);
    currentGameNotifier.setGame(restored);
    gameService.saveGame(
      observeSessionNotifier.prepareGameForPersistence(restored),
    );
  }

  void applySetObserveModeGlobal() {
    final wasOff = readObserveSession().mode == ObserveMode.off;
    var game = readCurrentGame();
    if (game == null) {
      return;
    }
    if (wasOff) {
      game = observeSessionNotifier.applyObserveHandoffIfNeeded(game);
      currentGameNotifier.setGame(game);
      gameService.saveGame(
        observeSessionNotifier.prepareGameForPersistence(game),
      );
    }
    observeSessionNotifier.setModeGlobal();
  }

  void applySetObserveModePlayer(String targetPlayerId) {
    final game = readCurrentGame();
    if (game == null) {
      return;
    }
    if (game.playerById(targetPlayerId) == null) {
      return;
    }
    final wasOff = readObserveSession().mode == ObserveMode.off;
    var next = game;
    if (wasOff) {
      next = observeSessionNotifier.applyObserveHandoffIfNeeded(game);
      currentGameNotifier.setGame(next);
      gameService.saveGame(
        observeSessionNotifier.prepareGameForPersistence(next),
      );
    }
    observeSessionNotifier.setModePlayer(targetPlayerId);
  }
}

final observeModeSessionHandlerProvider =
    Provider<ObserveModeSessionHandler>((ref) {
      return ObserveModeSessionHandler(
        currentGameNotifier: ref.read(currentGameProvider.notifier),
        observeSessionNotifier: ref.read(observeSessionProvider.notifier),
        gameService: ref.read(gameServiceProvider),
        readCurrentGame: () => ref.read(currentGameProvider),
        readObserveSession: () => ref.read(observeSessionProvider),
      );
    });

bool rejectUiMutationIfObserving({
  required ShellPlayerContext shell,
  required void Function(ShowSnackBarEvent event) showSnack,
}) {
  if (!shell.canMutateViaUi) {
    showSnack(
      const ShowSnackBarEvent(
        message: 'Observe mode: UI actions are read-only.',
      ),
    );
    return true;
  }
  return false;
}
