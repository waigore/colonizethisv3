// Concern split under repo.app_test_file_size (Refs #4013, #4352, #4406):
// unrevealed-tile hover still reports tile keys in player-constrained mode.

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget) — unrevealed hover', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'onTileHovered still reports unrevealed tiles in player-constrained mode',
      (WidgetTester tester) async {
        final region = ctRegionMapWithUniformVisibility(
          base: ctRegionMapTestOldWorldRegion(),
          visibility: TileVisibility.unrevealed,
        );
        String? hoveredTileKey;
        String? hoveredProvinceId;
        await pumpCtRegionMapTest(
          tester,
          region: region,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          playerConstrained: true,
          onTileHovered: (key) => hoveredTileKey = key,
          onProvinceHovered: (id) => hoveredProvinceId = id,
        );
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer();
        await gesture.moveTo(tester.getCenter(ctRegionMapFinder()));
        await tester.pump();
        expect(hoveredTileKey, isNotNull);
        expect(hoveredTileKey!, startsWith('${region.regionId}|'));
        expect(hoveredProvinceId, isNull);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
