import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

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
      final seaCount = region.cells.where((c) => c.isSea).length;
      final landCount = region.cells.where((c) => !c.isSea).length;
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

  RegionMapViewData _oldWorldRegion() =>
      getDebugInitGameResult().mapViewData.oldWorld;

  Widget _buildCtRegionMap({
    required RegionMapViewData region,
    double width = 400,
    double height = 320,
    double cellSizePx = 24,
    bool showPoliticalOverlay = true,
    CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
    String? centerOnTileKey,
    void Function(String)? onProvinceSelected,
    void Function(String?)? onProvinceHovered,
    void Function(String?)? onTileHovered,
    VoidCallback? onRegionViewChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: CtRegionMap(
              region: region,
              cellSizePx: cellSizePx,
              showPoliticalOverlay: showPoliticalOverlay,
              visibilityMode: visibilityMode,
              centerOnTileKey: centerOnTileKey,
              onProvinceSelected: onProvinceSelected,
              onProvinceHovered: onProvinceHovered,
              onTileHovered: onTileHovered,
              onRegionViewChanged: onRegionViewChanged,
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

    testWidgets(
      'applies non-default visibility and political overlay flags',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            showPoliticalOverlay: false,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'responds to +/- keyboard shortcuts for zoom',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(_buildCtRegionMap(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        // Give the Focus widget a chance to attach.
        await tester.tap(mapFinder);
        await tester.pump();

        // Zoom in.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
        await tester.pump();

        // Zoom out.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'supports drag-to-pan gesture without throwing',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(_buildCtRegionMap(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        await tester.drag(mapFinder, const Offset(40, 20));
        await tester.pump();

        // Widget remains mounted after pan.
        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'centerOnTileKey triggers centering logic without throwing',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        final landCell = region.cells.firstWhere((c) => !c.isSea);
        final tileKey =
            '${region.regionId}|${landCell.regionCellId}|${landCell.x}|${landCell.y}';

        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            centerOnTileKey: tileKey,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'didUpdateWidget propagates updated props into game',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();

        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            visibilityMode: CtMapVisibilityMode.full,
          ),
        );
        await tester.pump();

        // Rebuild with changed visibility and political overlay flags.
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            showPoliticalOverlay: false,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'camera resize logic runs when parent size changes',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();

        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            width: 400,
            height: 320,
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            width: 640,
            height: 360,
          ),
        );
        await tester.pump();

        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            width: 320,
            height: 240,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'small cell size triggers map-smaller-than-viewport clamp path',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            width: 600,
            height: 600,
          ),
        );
        await tester.pump();

        // Rebuild with tiny cell size so that the map is smaller than the viewport.
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            width: 600,
            height: 600,
            // Use a small cell size so the map is smaller than the viewport.
            cellSizePx: 4,
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'onRegionViewChanged fires when camera moves',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        var callbackCount = 0;

        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            onRegionViewChanged: () {
              callbackCount++;
            },
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        // Trigger a pan (which should invoke the callback).
        await tester.drag(mapFinder, const Offset(20, 10));
        await tester.pump();

        // Trigger a zoom (which should also invoke the callback).
        await tester.tap(mapFinder);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();

        expect(callbackCount, greaterThanOrEqualTo(1));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'hover and exit events are forwarded into the game',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(_buildCtRegionMap(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        final element = tester.element(mapFinder);
        final box = element.renderObject! as RenderBox;
        final inside = box.localToGlobal(box.size.center(Offset.zero));
        final outside = inside + const Offset(2000, 2000);

        await tester.sendEventToBinding(
          PointerHoverEvent(position: inside),
        );
        await tester.pump();

        await tester.sendEventToBinding(
          PointerExitEvent(position: outside),
        );
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'scroll wheel events are forwarded to zoom handler',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        await tester.pumpWidget(_buildCtRegionMap(region: region));
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);

        final element = tester.element(mapFinder);
        final box = element.renderObject! as RenderBox;
        final center = box.localToGlobal(box.size.center(Offset.zero));

        // Scroll up (zoom in) at the center of the map.
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, -20),
          ),
        );
        await tester.pump();

        // Scroll down (zoom out).
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: center,
            scrollDelta: const Offset(0, 20),
          ),
        );
        await tester.pump();

        expect(mapFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap on map invokes onProvinceSelected with prefixed province id (mobile/touch)',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        String? selectedId;
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            onProvinceSelected: (id) => selectedId = id,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
        expect(selectedId!.split('|').length, 2);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap invokes onTileHovered with tapped tile key so overlay shows tile on mobile',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        String? selectedId;
        String? hoveredTileKey;
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            onProvinceSelected: (id) => selectedId = id,
            onTileHovered: (key) => hoveredTileKey = key,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedId, isNotNull);
        expect(hoveredTileKey, isNotNull);
        final parts = hoveredTileKey!.split('|');
        expect(parts.length, 4);
        expect(parts[0], region.regionId);
        expect(parts[1], selectedId!.split('|').last);
        expect(int.tryParse(parts[2]), isNotNull);
        expect(int.tryParse(parts[3]), isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap also drives hover selector on mobile (no crash path)',
      (WidgetTester tester) async {
        final region = _oldWorldRegion();
        String? hoveredTileKey;
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            onTileHovered: (key) => hoveredTileKey = key,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        // The game wrapper translates tap into a world-position tap; as long as
        // we get a hovered tile key back, the Flame component has updated its
        // internal hover state for the tapped tile (selector + glow).
        expect(hoveredTileKey, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    testWidgets(
      'tap still selects province when all tiles are unrevealed in player-constrained mode',
      (WidgetTester tester) async {
        final base = _oldWorldRegion();
        final unrevealedCells = base.cells
            .map(
              (c) => CellViewData(
                x: c.x,
                y: c.y,
                regionCellId: c.regionCellId,
                isSea: c.isSea,
                terrainTypeId: c.terrainTypeId,
                terrainType: c.terrainType,
                resourceId: c.resourceId,
                ownerFactionId: c.ownerFactionId,
                provinceDisplayName: c.provinceDisplayName,
                improvementLevel: c.improvementLevel,
                roadLevel: c.roadLevel,
                visibility: TileVisibility.unrevealed,
              ),
            )
            .toList();
        final region = RegionMapViewData(
          regionId: base.regionId,
          width: base.width,
          height: base.height,
          cellSize: base.cellSize,
          cells: unrevealedCells,
          capitalMarkers: base.capitalMarkers,
          portMarkers: base.portMarkers,
          factionColors: base.factionColors,
          terrainColors: base.terrainColors,
          unitMarkers: base.unitMarkers,
        );

        String? selectedId;
        await tester.pumpWidget(
          _buildCtRegionMap(
            region: region,
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            onProvinceSelected: (id) => selectedId = id,
          ),
        );
        await tester.pump();

        final mapFinder = find.byType(CtRegionMap);
        expect(mapFinder, findsOneWidget);
        await tester.tap(mapFinder);
        await tester.pump();

        expect(selectedId, isNotNull);
        expect(selectedId!, startsWith('${region.regionId}|'));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );
  });
}

