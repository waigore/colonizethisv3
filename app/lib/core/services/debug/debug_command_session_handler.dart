import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/observe_session_provider.dart';
import 'debug_command_helpers.dart';
import '../game_service/game_service.dart';

/// Applies ctdev/debug commands to the active session.
/// SPEC/program/app-ui-wiring.md; Refs #3878.
class DebugCommandSessionHandler {
  const DebugCommandSessionHandler({
    required this.currentGameNotifier,
    required this.observeSessionNotifier,
    required this.gameService,
  });

  final CurrentGameNotifier currentGameNotifier;
  final ObserveSessionNotifier observeSessionNotifier;
  final GameService gameService;

  /// Applies [result] to session state; shows snackbar feedback via [showSnackBar].
  void apply(
    DebugCommandResult result, {
    required void Function(ShowSnackBarEvent event) showSnackBar,
    void Function(String message)? logWarning,
  }) {
    final nextGame = result.game;
    if (nextGame == null) {
      final warn = logWarning ?? (_) {};
      warn(result.message);
      showSnackBar(ShowSnackBarEvent(message: result.message));
      return;
    }
    currentGameNotifier.setGame(nextGame);
    gameService.saveGame(
      observeSessionNotifier.prepareGameForPersistence(nextGame),
    );
    showSnackBar(ShowSnackBarEvent(message: result.message));
  }
}

final debugCommandSessionHandlerProvider =
    Provider<DebugCommandSessionHandler>((ref) {
      return DebugCommandSessionHandler(
        currentGameNotifier: ref.read(currentGameProvider.notifier),
        observeSessionNotifier: ref.read(observeSessionProvider.notifier),
        gameService: ref.read(gameServiceProvider),
      );
    });
