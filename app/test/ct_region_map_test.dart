import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/region_map_debug.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  RegionMapViewData _oldWorldRegion() =>
      getDebugInitGameResult().mapViewData.oldWorld;

  Widget _buildCtRegionMap({
    required RegionMapViewData region,
    double width = 400,
    double height = 320,
    CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
    void Function(String)? onProvinceSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: CtRegionMap(
              region: region,
              cellSizePx: 24,
              visibilityMode: visibilityMode,
              onProvinceSelected: onProvinceSelected,
            ),
          ),
        ),
      ),
    );
  }

  group('CtRegionMap (Flame map widget)', () {
    testWidgets(
      'builds without throwing for old world region',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(_buildCtRegionMap(region: region));
        // Do a single pump; CtRegionMap embeds a Flame GameWidget which
        // does not naturally settle for pumpAndSettle.
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      // GameWidget + Flame may keep the frame "dirty"; avoid long timeouts.
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}

