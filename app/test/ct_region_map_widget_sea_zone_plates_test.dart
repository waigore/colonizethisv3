// Sea-zone name plate layout cases split from port taps (Refs #4734 Slice C).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';
import 'ct_region_map_widget_port_and_sea_plates_support.dart';
import 'ct_region_map_widget_visibility_cases.dart';

void main() {
  suppressLogsForTests();

  group('Sea zone name plate layout (#1756)', () {
    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld uses below placement when above clips map top',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateH = 20.0;
        final invZ = 1.0;
        final hh = plateH * invZ / 2;
        final center = ctRegionMapPlateCenter(
          centroidTileX: 1,
          centroidTileY: 0,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateW: 80,
          plateH: plateH,
        );
        expect(
          center.dy,
          greaterThanOrEqualTo(cellSize + 1 + hh - 1e-6),
          reason: 'Below placement anchors under the centroid cell',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld keeps plate inside region bounds',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 16.0;
        const gw = 20;
        const gh = 20;
        const plateW = 200.0;
        const plateH = 30.0;
        const zoom = 2.0;
        final invZ = 1.0 / zoom.clamp(0.25, 4.0);
        final ww = plateW * invZ / 2;
        final hh = plateH * invZ / 2;
        final center = ctRegionMapPlateCenter(
          centroidTileX: 10,
          centroidTileY: 10,
          cellSize: cellSize,
          gridWidth: gw,
          gridHeight: gh,
          plateW: plateW,
          plateH: plateH,
          zoom: zoom,
        );
        final mapW = gw * cellSize;
        final mapH = gh * cellSize;
        expect(center.dx - ww, greaterThanOrEqualTo(-1e-6));
        expect(center.dx + ww, lessThanOrEqualTo(mapW + 1e-6));
        expect(center.dy - hh, greaterThanOrEqualTo(-1e-6));
        expect(center.dy + hh, lessThanOrEqualTo(mapH + 1e-6));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld avoids overlapping centroid cell when room allows',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 32.0;
        const plateW = 60.0;
        const plateH = 14.0;
        final ww = plateW / 2;
        final hh = plateH / 2;
        final c = ctRegionMapPlateCenter(
          centroidTileX: 5,
          centroidTileY: 5,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateW: plateW,
          plateH: plateH,
        );
        expect(ctRegionMapPlateOverlapsCell(c, ww, hh, 5, 5, cellSize), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld supports avoidedTile overrides for province town collision behavior',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateW = 80.0;
        const plateH = 16.0;
        final ww = plateW / 2;
        final hh = plateH / 2;
        final c = ctRegionMapPlateCenter(
          centroidTileX: 4,
          centroidTileY: 3,
          avoidedTileX: 4,
          avoidedTileY: 3,
          cellSize: cellSize,
          gridWidth: 20,
          gridHeight: 20,
          plateW: plateW,
          plateH: plateH,
        );
        expect(ctRegionMapPlateOverlapsCell(c, ww, hh, 4, 3, cellSize), isFalse);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'resolveSeaZoneNamePlateCenterWorld with avoidedTile uses below fallback when above clips top',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const cellSize = 24.0;
        const plateH = 18.0;
        final hh = plateH / 2;
        final center = ctRegionMapPlateCenter(
          centroidTileX: 1,
          centroidTileY: 0,
          avoidedTileX: 1,
          avoidedTileY: 0,
          cellSize: cellSize,
          gridWidth: 10,
          gridHeight: 10,
          plateW: 70,
          plateH: plateH,
        );
        expect(
          center.dy,
          greaterThanOrEqualTo(cellSize + 1 + hh - 1e-6),
          reason:
              'Fallback should mirror sea-zone semantics for province/town avoidance',
        );
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'sea zone label TextPainter lays out full long string without ellipsis',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox.shrink());
        const long =
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789HelloSeaZoneNameThatIsQuiteVerbose';
        final tp = TextPainter(
          text: const TextSpan(
            text: long,
            style: TextStyle(color: Colors.black, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);
        expect(tp.width, greaterThan(200));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    registerCtRegionMapVisibilityHelperTests();

    for (final showNames in [false, true]) {
      testWidgets(
        'CtRegionMapComponent showProvinceNamesLayer $showNames when harness sets names (#1756)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            ctRegionMapTestHarness(
              region: ctRegionMapTestOldWorldRegion(),
              showProvinceNamesLayer: showNames,
            ),
          );
          await tester.pump();
          expect(
            ctRegionMapComponentFromTester(tester).showProvinceNamesLayer,
            showNames,
          );
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    }
  });
}
