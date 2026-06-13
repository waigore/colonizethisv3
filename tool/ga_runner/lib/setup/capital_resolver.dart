import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

/// Resolves capital province ids for a fully-AI observer setup + seed.
Map<String, String> resolveCapitalProvinces(GameSetupConfig config) {
  final init = runInitGame(
    config: config,
    options: const InitGameOptions(
      cellSize: 24,
      renderPng: false,
      skipFillLakes: false,
    ),
  );
  final capitals = <String, String>{};
  for (final player in init.game.players) {
    final cap = player.capitalProvinceId;
    if (cap != null && cap.isNotEmpty) {
      capitals[player.id] = cap;
    }
  }
  return capitals;
}
