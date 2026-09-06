// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// didUpdateWidget presence refresh after rebuild.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'didUpdateWidget refreshes map region presence data after rebuild',
      (WidgetTester tester) async {
        final base = ctRegionMapTestOldWorldRegion();
        final localProvinceId = base.cells
            .firstWhere((c) => !c.isSea)
            .regionCellId;
        final fullProvinceId = '${base.regionId}|$localProvinceId';

        final initial = ctRegionMapWithPresence(
          base: base,
          fullProvinceId: fullProvinceId,
          civilianCount: 0,
          regimentCount: 0,
          shipCount: 0,
          intelVisible: true,
        );
        final refreshed = ctRegionMapWithPresence(
          base: base,
          fullProvinceId: fullProvinceId,
          civilianCount: 1,
          regimentCount: 1,
          shipCount: 1,
          intelVisible: true,
        );

        await tester.pumpWidget(ctRegionMapTestHarness(region: initial));
        await tester.pump();

        final gameWidgetFinder = find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('GameWidget<'),
        );
        expect(gameWidgetFinder, findsOneWidget);
        final beforeRegion =
            (tester.widget(gameWidgetFinder) as dynamic).game.region
                as RegionMapViewData;
        void expectPresence(RegionMapViewData region, int n) {
          final p = region.provinceUnitPresenceByProvinceId[fullProvinceId]!;
          expect(p.civilianCount, n);
          expect(p.regimentCount, n);
          expect(p.shipCount, n);
        }

        expectPresence(beforeRegion, 0);

        await tester.pumpWidget(ctRegionMapTestHarness(region: refreshed));
        await tester.pump();

        expectPresence(
          (tester.widget(gameWidgetFinder) as dynamic).game.region
              as RegionMapViewData,
          1,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
