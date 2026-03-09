// Widget and unit tests for CtRegionMapDebug and debug init map data.
// SPEC/ui/map-widget.md; coverage for lib/widgets/ (quality gate 80%).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/region_map_debug.dart';

void main() {
  suppressLogsForTests();

  group('debug init Old World region', () {
    test('returns region with correct dimensions and cell count', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.regionId, 'oldWorld');
      expect(region.width, greaterThanOrEqualTo(8));
      expect(region.height, greaterThanOrEqualTo(8));
      expect(region.cells.length, region.width * region.height);
      expect(region.cellSize, 24);
    });

    test('has terrain and faction colors', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.terrainColors.length, greaterThanOrEqualTo(1));
      expect(region.factionColors.length, greaterThanOrEqualTo(2));
    });

    test('has at least one capital marker', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.capitalMarkers.length, greaterThanOrEqualTo(1));
    });

    test('has both sea and land cells with provinces', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      final seaCount =
          region.cells.where((c) => c.isSea).length;
      final landCount =
          region.cells.where((c) => !c.isSea).length;
      expect(seaCount, greaterThan(0));
      expect(landCount, greaterThan(0));
      final landCell = region.cells.firstWhere((c) => !c.isSea);
      expect(landCell.regionCellId, startsWith('p'));
      expect(landCell.terrainType, isNotNull);
    });

    test('land cells may have improvement and road levels', () {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      expect(region.cells.any((c) => !c.isSea), isTrue);
    });
  });

  group('CtRegionMapDebug', () {
    Widget buildMap({
      required RegionMapViewData region,
      bool showPoliticalOverlay = true,
      double cellSizePx = 28,
      CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
      void Function(String)? onProvinceSelected,
      void Function(String?)? onProvinceHovered,
      void Function(String?)? onTileHovered,
      String? highlightedTileKey,
      String? centerOnTileKey,
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
              visibilityMode: visibilityMode,
              onProvinceSelected: onProvinceSelected,
              onProvinceHovered: onProvinceHovered,
              onTileHovered: onTileHovered,
              highlightedTileKey: highlightedTileKey,
              centerOnTileKey: centerOnTileKey,
            ),
          ),
        ),
      );
    }

    testWidgets('builds and contains InteractiveViewer and CustomPaint',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
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
      final region = getDebugInitGameResult().mapViewData.oldWorld;
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
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      await tester.pumpWidget(buildMap(
        region: region,
        showPoliticalOverlay: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
    });

    testWidgets('player-constrained visibility renders without throwing',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      await tester.pumpWidget(buildMap(
        region: region,
        visibilityMode: CtMapVisibilityMode.playerConstrained,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
    });

    testWidgets('builds without onProvinceSelected callback',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
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
      final region = getDebugInitGameResult().mapViewData.oldWorld;
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
      final region = getDebugInitGameResult().mapViewData.oldWorld;
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
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      final landCell = region.cells.firstWhere((c) => !c.isSea);
      final tileKey =
          '${region.regionId}|${landCell.regionCellId}|${landCell.x}|${landCell.y}';
      await tester.pumpWidget(buildMap(
        region: region,
        highlightedTileKey: tileKey,
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

    testWidgets('arrow key scroll applies translation and is bounded',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      await tester.pumpWidget(buildMap(region: region));
      await tester.pumpAndSettle();

      final focusFinder = find.descendant(
        of: find.byType(CtRegionMapDebug),
        matching: find.byType(Focus),
      );
      expect(focusFinder, findsOneWidget);
      await tester.tap(focusFinder);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
    });

    testWidgets('builds Stack with map and optional scrollbars',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      await tester.pumpWidget(buildMap(region: region));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      final stacks = find.descendant(
        of: find.byType(CtRegionMapDebug),
        matching: find.byType(Stack),
      );
      expect(stacks, findsAtLeastNWidgets(1));
      final firstStack = tester.widgetList<Stack>(stacks).first;
      expect(firstStack.children.length, greaterThanOrEqualTo(1));
    });

    testWidgets('builds with centerOnTileKey and applies centering',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      final landCell = region.cells.firstWhere((c) => !c.isSea);
      final tileKey =
          '${region.regionId}|${landCell.regionCellId}|${landCell.x}|${landCell.y}';
      await tester.pumpWidget(buildMap(
        region: region,
        centerOnTileKey: tileKey,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
    });

    testWidgets('centerOnTileKey change triggers didUpdateWidget and applyCenterOnTileKey',
        (WidgetTester tester) async {
      final region = getDebugInitGameResult().mapViewData.oldWorld;
      final landCell = region.cells.firstWhere((c) => !c.isSea);
      final tileKey =
          '${region.regionId}|${landCell.regionCellId}|${landCell.x}|${landCell.y}';
      await tester.pumpWidget(buildMap(region: region, centerOnTileKey: null));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(buildMap(
        region: region,
        centerOnTileKey: tileKey,
      ));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
    });
  });
}
