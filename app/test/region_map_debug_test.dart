// Widget and unit tests for CtRegionMapDebug and demo map data.
// SPEC/ui/map-widget.md; coverage for lib/widgets/ (quality gate 80%).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/region_map_debug.dart';
import 'package:colonizethis_app/widgets/region_map_demo_data.dart';

void main() {
  suppressLogsForTests();

  group('buildDemoRegionMapViewData', () {
    test('returns region with correct dimensions and cell count', () {
      final region = buildDemoRegionMapViewData();
      expect(region.regionId, 'demo');
      expect(region.width, 14);
      expect(region.height, 10);
      expect(region.cells.length, 14 * 10);
      expect(region.cellSize, 24);
    });

    test('has terrain and faction colors', () {
      final region = buildDemoRegionMapViewData();
      expect(region.terrainColors.length, greaterThanOrEqualTo(1));
      expect(region.factionColors.length, greaterThanOrEqualTo(2));
    });

    test('has one capital and one port marker', () {
      final region = buildDemoRegionMapViewData();
      expect(region.capitalMarkers.length, 1);
      expect(region.portMarkers.length, 1);
    });

    test('frame is sea, inner cells are land with provinces', () {
      final region = buildDemoRegionMapViewData();
      expect(region.cellAt(0, 0).isSea, isTrue);
      expect(region.cellAt(0, 0).regionCellId, 's1');
      expect(region.cellAt(13, 9).isSea, isTrue);
      expect(region.cellAt(1, 1).isSea, isFalse);
      expect(region.cellAt(1, 1).regionCellId, 'p1');
      expect(region.cellAt(1, 1).ownerFactionId, 'gp1');
      expect(region.cellAt(1, 1).terrainType, isNotNull);
    });

    test('land cells have improvement and road levels', () {
      final region = buildDemoRegionMapViewData();
      final cell = region.cellAt(2, 2);
      expect(cell.improvementLevel, isNotNull);
      expect(cell.roadLevel, isNotNull);
    });
  });

  group('CtRegionMapDebug', () {
    Widget buildMap({
      required RegionMapViewData region,
      bool showPoliticalOverlay = true,
      double cellSizePx = 28,
      void Function(String)? onProvinceSelected,
      void Function(String?)? onProvinceHovered,
      String? highlightedTileKey,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 320,
            child: CtRegionMapDebug(
              region: region,
              showPoliticalOverlay: showPoliticalOverlay,
              cellSizePx: cellSizePx,
              onProvinceSelected: onProvinceSelected,
              onProvinceHovered: onProvinceHovered,
              highlightedTileKey: highlightedTileKey,
            ),
          ),
        ),
      );
    }

    testWidgets('builds and contains InteractiveViewer and CustomPaint',
        (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      await tester.pumpWidget(buildMap(region: region));
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CtRegionMapDebug),
          matching: find.byType(InteractiveViewer),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CtRegionMapDebug),
          matching: find.byType(CustomPaint),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('tap on map invokes onProvinceSelected with prefixed province id',
        (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      String? selectedId;
      await tester.pumpWidget(buildMap(
        region: region,
        onProvinceSelected: (id) => selectedId = id,
      ));
      await tester.pumpAndSettle();

      final mapFinder = find.byType(CtRegionMapDebug);
      expect(mapFinder, findsOneWidget);
      final element = tester.element(find.descendant(
        of: mapFinder,
        matching: find.byType(SizedBox),
      ).first);
      final box = element.renderObject! as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(selectedId, isNotNull);
      expect(selectedId!, startsWith('${region.regionId}|'));
      expect(selectedId!.split('|').length, 2);
    });

    testWidgets('builds with showPoliticalOverlay false', (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      await tester.pumpWidget(buildMap(
        region: region,
        showPoliticalOverlay: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
    });

    testWidgets('builds without onProvinceSelected callback',
        (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      await tester.pumpWidget(buildMap(region: region));
      await tester.pumpAndSettle();

      final mapFinder = find.byType(CtRegionMapDebug);
      final element = tester.element(find.descendant(
        of: mapFinder,
        matching: find.byType(SizedBox),
      ).first);
      final box = element.renderObject! as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      await tester.tapAt(center);
      await tester.pumpAndSettle();
      // No throw; callback is optional.
    });

    testWidgets('contains MouseRegion for hover', (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      await tester.pumpWidget(buildMap(region: region));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(CtRegionMapDebug),
          matching: find.byType(MouseRegion),
        ),
        findsOneWidget,
      );
    });

    testWidgets('builds with onProvinceHovered callback', (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      String? lastHoveredId;
      await tester.pumpWidget(buildMap(
        region: region,
        onProvinceHovered: (id) => lastHoveredId = id,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
      expect(lastHoveredId, isNull);
    });

    testWidgets('builds with highlightedTileKey and paints secondary highlight',
        (WidgetTester tester) async {
      final region = buildDemoRegionMapViewData();
      await tester.pumpWidget(buildMap(
        region: region,
        highlightedTileKey: '${region.regionId}|p1|2|3',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CtRegionMapDebug),
          matching: find.byType(CustomPaint),
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
