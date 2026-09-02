// Right-click / primary-tap contract for MAP30001. Refs #4440.

import 'package:colonizethis_app/features/game/flame/region_map/region_map_component_secondary.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app/widgets/ct_region_map_state.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';

Future<void> _waitForMap(WidgetTester tester) async {
  final game = tester.state<CtRegionMapState>(find.byType(CtRegionMap)).game;
  for (var i = 0; i < 40; i++) {
    if (game.state.mapLoaded && game.size.x > 0 && game.size.y > 0) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  suppressLogsForTests();
  setUpAll(warmCtRegionMapCachesForTests);

  testWidgets(
    'secondary hit on a bare tile reports a tile key and skips MAP20001',
    (tester) async {
      String? detailTileKey;
      String? secondaryTileKey;
      await pumpCtRegionMapTest(
        tester,
        region: ctRegionMapMiniLandStrip(
          base: ctRegionMapTestOldWorldRegion(),
          width: 1,
          height: 1,
          cellSize: 32,
          regionCellId: 'p1',
        ),
        cellSizePx: 32,
        onMapTileTappedForDetail: (tk) => detailTileKey = tk,
        onMapTileSecondaryForRadial: (tk, _) => secondaryTileKey = tk,
      );
      await _waitForMap(tester);
      final component = ctRegionMapComponentFromTester(tester);
      final world =
          component.absoluteTopLeftPosition +
          Vector2(component.cellSize / 2, component.cellSize / 2);
      expect(
        ctRegionMapComponentTileKeyForSecondaryAtWorld(component, world),
        isNotNull,
      );
      tester
          .state<CtRegionMapState>(find.byType(CtRegionMap))
          .game
          .onMapTileSecondaryForRadial
          ?.call(
            ctRegionMapComponentTileKeyForSecondaryAtWorld(component, world)!,
            Offset.zero,
          );
      expect(secondaryTileKey, isNotNull);
      expect(secondaryTileKey!.split('|'), hasLength(4));
      expect(detailTileKey, isNull);
    },
  );

  testWidgets('primary tap still reports MAP20001 detail and not secondary', (
    tester,
  ) async {
    String? detailTileKey;
    String? secondaryTileKey;
    await pumpCtRegionMapTest(
      tester,
      region: ctRegionMapMiniLandStrip(
        base: ctRegionMapTestOldWorldRegion(),
        width: 1,
        height: 1,
        cellSize: 32,
        regionCellId: 'p1',
      ),
      cellSizePx: 32,
      onMapTileTappedForDetail: (tk) => detailTileKey = tk,
      onMapTileSecondaryForRadial: (tk, _) => secondaryTileKey = tk,
    );
    await _waitForMap(tester);
    await tapCtRegionMap(tester);
    expect(detailTileKey, isNotNull);
    expect(secondaryTileKey, isNull);
  });

  testWidgets('work-target mode suppresses the secondary radial callback', (
    tester,
  ) async {
    await pumpCtRegionMapTest(
      tester,
      region: ctRegionMapMiniLandStrip(
        base: ctRegionMapTestOldWorldRegion(),
        width: 1,
        height: 1,
        cellSize: 32,
        regionCellId: 'p1',
      ),
      cellSizePx: 32,
      validTileKeys: const {'oldWorld|p1|0|0'},
    );
    await _waitForMap(tester);
    final component = ctRegionMapComponentFromTester(tester);
    final world =
        component.absoluteTopLeftPosition +
        Vector2(component.cellSize / 2, component.cellSize / 2);
    expect(
      ctRegionMapComponentTileKeyForSecondaryAtWorld(component, world),
      isNull,
    );
  });
}
