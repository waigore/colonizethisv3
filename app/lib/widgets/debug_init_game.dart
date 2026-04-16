// Lazy-initialized init game result for Widgetbook and tests.
// SPEC/ui/map-widget.md — debug mode uses map from real map generator and initialized game.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

InitGameResult? _debugInitGameResult;
const _debugInitSeeds = <int>[42, 43, 44, 45, 46];

/// Returns a cached init game result (full default config, seed 42).
/// Used by Map Widget stories and tests so they use the real map generator and initialized game.
InitGameResult getDebugInitGameResult() {
  _debugInitGameResult ??= _buildDebugInitGameResult();
  return _debugInitGameResult!;
}

InitGameResult _buildDebugInitGameResult() {
  Object? lastError;
  for (final seed in _debugInitSeeds) {
    try {
      final result = runInitGame(
        config: GameSetupConfig(seed: seed),
        options: const InitGameOptions(cellSize: 24, renderPng: false),
      );
      if (_hasLandCellWithoutTerrain(result.mapViewData.oldWorld)) {
        lastError = StateError(
          'seed $seed produced Old World land cells without terrain metadata',
        );
        continue;
      }
      return result;
    } on Exception catch (error) {
      lastError = error;
    }
  }
  throw StateError(
    'debug init failed for seeds: ${_debugInitSeeds.join(", ")}; '
    'lastError=$lastError',
  );
}

bool _hasLandCellWithoutTerrain(RegionMapViewData region) {
  for (final cell in region.cells) {
    if (cell.isSea) {
      continue;
    }
    if (cell.terrainType == null && cell.terrainTypeId == null) {
      return true;
    }
  }
  return false;
}
