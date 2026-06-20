import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_event_bridge.dart';
import '../core/services/game_service.dart';
import 'app_event_bus_provider.dart';
import 'games_box_provider.dart';
import 'observe_session_provider.dart';

final gameSaveAdapterProvider = Provider<GameSaveAdapter>(
  (ref) => GameSaveAdapter(),
);

final gameEventBridgeProvider = Provider<GameEventBridge>((ref) {
  final appBus = ref.watch(appEventBusProvider);
  final logicBus = DefaultGameEventBus();
  final bridge = GameEventBridge(logicBus: logicBus, appBus: appBus);
  bridge.start();
  ref.onDispose(() => bridge.dispose());
  return bridge;
});

final gameServiceProvider = Provider<GameService>((ref) {
  final box = ref.watch(gamesBoxProvider);
  final adapter = ref.watch(gameSaveAdapterProvider);
  final bus = ref.watch(appEventBusProvider);
  final bridge = ref.watch(gameEventBridgeProvider);

  final service = GameService(box, adapter);
  service.eventBus = bus;
  service.logicEventBus = bridge.logicBus;
  service.prepareGameForPersistence = (game) => ref
      .read(observeSessionProvider.notifier)
      .prepareGameForPersistence(game);
  return service;
});
