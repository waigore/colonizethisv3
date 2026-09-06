// Concern split under repo.app_test_file_size (Refs #4013, #4352, #4734):
// port-drawable sea taps (sea-zone plates live in sibling test).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, OpenProvinceDetailPanelEvent;

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode;

import 'ct_region_map_test_support.dart';
import 'ct_region_map_widget_port_and_sea_plates_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap (Flame map widget)', () {
    setUpAll(warmCtRegionMapCachesForTests);

    testWidgets(
      'tap on port drawable sea cell emits OpenProvinceDetailPanelEvent same as town',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        String? panelProvinceId;
        bus.on<OpenProvinceDetailPanelEvent>().listen((e) {
          panelProvinceId = e.provinceId;
        });

        await pumpCtRegionMapTest(
          tester,
          region: ctRegionMapPortDrawableRegion(),
          width: 64,
          height: 64,
          cellSizePx: 32,
          bus: bus,
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
        );
        await tapCtRegionMapPortSeaCell(tester);

        expect(panelProvinceId, equals('oldWorld|p1'));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    testWidgets(
      'tap on port drawable sea cell selects owning province not sea zone id',
      (WidgetTester tester) async {
        String? selectedProvinceId;
        await pumpCtRegionMapTest(
          tester,
          region: ctRegionMapPortDrawableRegion(),
          width: 64,
          height: 64,
          cellSizePx: 32,
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          onProvinceSelected: (id) => selectedProvinceId = id,
        );
        await tapCtRegionMapPortSeaCell(tester);

        expect(selectedProvinceId, equals('oldWorld|p1'));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
