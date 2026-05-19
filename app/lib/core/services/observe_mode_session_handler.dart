import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/shell_player_context.dart';
import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/observe_session_provider.dart';

/// Applies `/observe` session events. SPEC/ui/observe-mode.md.
void applySetObserveModeOff(WidgetRef ref) {
  final game = ref.read(currentGameProvider);
  if (game == null) {
    ref.read(observeSessionProvider.notifier).reset();
    return;
  }
  final restored = ref.read(observeSessionProvider.notifier).applyObserveOff(game);
  ref.read(currentGameProvider.notifier).setGame(restored);
  ref.read(gameServiceProvider).saveGame(
    ref.read(observeSessionProvider.notifier).prepareGameForPersistence(restored),
  );
}

void applySetObserveModeGlobal(WidgetRef ref) {
  final observe = ref.read(observeSessionProvider.notifier);
  final wasOff = ref.read(observeSessionProvider).mode == ObserveMode.off;
  var game = ref.read(currentGameProvider);
  if (game == null) {
    return;
  }
  if (wasOff) {
    game = observe.applyObserveHandoffIfNeeded(game);
    ref.read(currentGameProvider.notifier).setGame(game);
    ref.read(gameServiceProvider).saveGame(
      ref.read(observeSessionProvider.notifier).prepareGameForPersistence(game),
    );
  }
  observe.setModeGlobal();
}

void applySetObserveModePlayer(WidgetRef ref, String targetPlayerId) {
  final game = ref.read(currentGameProvider);
  if (game == null) {
    return;
  }
  if (game.playerById(targetPlayerId) == null) {
    return;
  }
  final observe = ref.read(observeSessionProvider.notifier);
  final wasOff = ref.read(observeSessionProvider).mode == ObserveMode.off;
  var next = game;
  if (wasOff) {
    next = observe.applyObserveHandoffIfNeeded(game);
    ref.read(currentGameProvider.notifier).setGame(next);
    ref.read(gameServiceProvider).saveGame(
      ref.read(observeSessionProvider.notifier).prepareGameForPersistence(next),
    );
  }
  observe.setModePlayer(targetPlayerId);
}

bool rejectUiMutationIfObserving(
  WidgetRef ref,
  void Function(ShowSnackBarEvent) showSnack,
) {
  if (!ref.read(shellPlayerContextProvider).canMutateViaUi) {
    showSnack(
      const ShowSnackBarEvent(
        message: 'Observe mode: UI actions are read-only.',
      ),
    );
    return true;
  }
  return false;
}
