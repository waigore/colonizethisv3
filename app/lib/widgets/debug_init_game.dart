// Lazy-initialized init game result for Widgetbook and tests.
// SPEC/ui/map-widget.md — debug mode uses map from real map generator and initialized game.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

InitGameResult? _debugInitGameResult;

/// Returns a cached init game result (full default config, seed 42).
/// Used by Map Widget stories and tests so they use the real map generator and initialized game.
InitGameResult getDebugInitGameResult() {
  _debugInitGameResult ??= runInitGame(
    config: GameSetupConfig.defaultConfig,
    options: const InitGameOptions(cellSize: 24, renderPng: false),
  );
  return _debugInitGameResult!;
}
