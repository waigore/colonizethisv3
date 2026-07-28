import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work.dart';
import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_feedstock_priority_fixtures.dart';

/// Determinism pin for connectivity-aware work suggestions (Refs #4176 AC-F4).
void main() {
  runLabeledScenarioGroup('suggestWorkOrders determinism (AC-F4)', [
    rs('byte-identical across two passes', () {
      final game = feedstockPriorityGame();
      final topology = feedstockPriorityTopology(game);
      final view = buildPlayerView(game, topology, feedstockPrioritySupplierId);
      final tileMapByRegion = <String, TileMapResult>{
        for (final regionEntry
            in game.worldState.tileKeysByRegionAndProvince.entries)
          regionEntry.key:
              _tileMapForRegion(regionEntry.key, regionEntry.value),
      };

      final first = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
        tileMapByRegion: tileMapByRegion,
      );
      final second = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
        tileMapByRegion: tileMapByRegion,
      );

      expect(
        second.map((o) => (o.unitId, o.target, o.targetTileKey)).toList(),
        first.map((o) => (o.unitId, o.target, o.targetTileKey)).toList(),
      );
    }),
  ], runRunnableScenario);
}

TileMapResult _tileMapForRegion(
  String regionId,
  Map<String, List<String>> provinces,
) {
  var maxX = 0;
  var maxY = 0;
  for (final tiles in provinces.values) {
    for (final tileKey in tiles) {
      final coords = parseTileKeyCoordinates(tileKey);
      if (coords == null) continue;
      if (coords.x > maxX) maxX = coords.x;
      if (coords.y > maxY) maxY = coords.y;
    }
  }
  final w = maxX + 1;
  final h = maxY + 1;
  final grid = List.generate(
    h,
    (_) => List.filled(w, provinces.keys.first),
  );
  for (final provinceEntry in provinces.entries) {
    for (final tileKey in provinceEntry.value) {
      final coords = parseTileKeyCoordinates(tileKey);
      if (coords == null) continue;
      grid[coords.y][coords.x] = provinceEntry.key;
    }
  }
  return TileMapResult(width: w, height: h, grid: grid);
}
