import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_service.dart';
import 'game_service_provider.dart';
import 'observe_session_provider.dart';

/// Persists [game] after stripping in-memory observe control overrides.
void persistGameAfterObserveStrip(Ref ref, Game game) {
  final toSave = ref
      .read(observeSessionProvider.notifier)
      .prepareGameForPersistence(game);
  ref.read(gameServiceProvider).saveGame(toSave);
}

/// Wires observe save-strip into [GameService.saveGame].
void configureGameServiceObservePersistence(Ref ref, GameService service) {
  service.prepareGameForPersistence = (game) => ref
      .read(observeSessionProvider.notifier)
      .prepareGameForPersistence(game);
}
