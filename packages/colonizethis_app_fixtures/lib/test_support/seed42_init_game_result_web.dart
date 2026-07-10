// Web fallback for seed-42 [InitGameResult] when committed JSON is unavailable.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

InitGameResult? _cachedSeed42InitGameResult;

/// Builds an [InitGameResult]; on web uses the procedural generator.
InitGameResult loadSeed42InitGameResult() {
  return _cachedSeed42InitGameResult ??= runInitGame(
    config: GameSetupConfig.defaultConfig,
    options: const InitGameOptions(cellSize: 24, renderPng: false),
  );
}
