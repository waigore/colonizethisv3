import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/game_service.dart';
import 'app_event_bus_provider.dart';
import 'games_box_provider.dart';

final gameSaveAdapterProvider = Provider<GameSaveAdapter>(
  (ref) => GameSaveAdapter(),
);

final gameServiceProvider = Provider<GameService>((ref) {
  final box = ref.watch(gamesBoxProvider);
  final adapter = ref.watch(gameSaveAdapterProvider);
  final bus = ref.watch(appEventBusProvider);
  final service = GameService(box, adapter);
  service.eventBus = bus;
  return service;
});
