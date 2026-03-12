// Tests for ProvinceSeaZoneDetailOverlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/widgets/region_map_debug.dart';

void main() {
  suppressLogsForTests();

  group('demoGameForOverlay', () {
    test('returns game with Old World provinces and players', () {
      final game = demoGameForOverlay;
      expect(game.players.length, greaterThanOrEqualTo(1));
      expect(game.worldState.oldWorld.provinces.length, greaterThanOrEqualTo(1));
      expect(
        game.worldState.tileKeysByRegionAndProvince.containsKey('oldWorld'),
        isTrue,
      );
    });
  });

  group('ProvinceSeaZoneDetailOverlay', () {
    Widget buildOverlay({
      required String selectedId,
      void Function(String?)? onHighlightTile,
      VoidCallback? onClose,
    }) {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      return MaterialApp(
        home: Scaffold(
          body: ProvinceSeaZoneDetailOverlay(
            game: game,
            region: region,
            selectedId: selectedId,
            displayId: selectedId,
            humanPlayerId: game.players.first.id,
            onHighlightTile: onHighlightTile,
            onClose: onClose,
          ),
        ),
      );
    }

    testWidgets('AC: Standalone province overlay displays Political, Economic, Military, Civilian, Naval',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOverlay(selectedId: sampleProvinceIdForOverlay));
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Province'), findsOneWidget);
      expect(find.text('Tile'), findsOneWidget);
      expect(find.text('Political'), findsOneWidget);
      expect(find.text('Economic'), findsOneWidget);
      expect(find.text('Military'), findsOneWidget);
      expect(find.text('Civilian'), findsOneWidget);
      expect(find.text('Naval'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('AC: Province overlay shows province name and owner',
        (WidgetTester tester) async {
      final region = demoRegionForOverlay;
      final selectedId = sampleProvinceIdForOverlay;
      final cell = region.cells.firstWhere(
        (c) => !c.isSea && '${region.regionId}|${c.regionCellId}' == selectedId,
      );
      final game = demoGameForOverlay;
      await tester.pumpWidget(buildOverlay(selectedId: selectedId));
      await tester.pumpAndSettle();

      final provinceName = cell.provinceDisplayName ?? cell.regionCellId;
      expect(provinceName, isNotEmpty);
      expect(find.textContaining(provinceName), findsAtLeastNWidgets(1));
      final ownerId = cell.ownerFactionId;
      if (ownerId != null && ownerId.isNotEmpty) {
        final ownerName = game.players
                .where((p) => p.id == ownerId)
                .map((p) => p.displayName)
                .firstOrNull ??
            game.minorNations
                .where((m) => m.id == ownerId)
                .map((m) => m.displayName ?? m.id)
                .firstOrNull ??
            ownerId;
        expect(find.textContaining(ownerName), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Sea zone overlay displays Political and Naval',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOverlay(selectedId: sampleSeaZoneIdForOverlay));
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Sea zone'), findsOneWidget);
      expect(find.text('Political'), findsOneWidget);
      expect(find.text('Naval'), findsOneWidget);
    });

    testWidgets('AC: Close button invokes onClose', (WidgetTester tester) async {
      var closed = false;
      await tester.pumpWidget(buildOverlay(
        selectedId: sampleProvinceIdForOverlay,
        onClose: () => closed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('AC: Overlay constrained to one-third height on narrow viewport',
        (WidgetTester tester) async {
      const viewportHeight = 600.0;
      const expectedMaxHeight = 198.0; // 0.33 * 600
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, viewportHeight)),
          child: MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: demoRegionForOverlay,
                selectedId: sampleProvinceIdForOverlay,
                displayId: sampleProvinceIdForOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final constrained = find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.maxHeight == expectedMaxHeight,
      );
      expect(constrained, findsAtLeastNWidgets(1));
    });

    testWidgets('AC: Overlay uses full height on desktop', (WidgetTester tester) async {
      const viewportHeight = 600.0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, viewportHeight)),
          child: MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: demoRegionForOverlay,
                selectedId: sampleProvinceIdForOverlay,
                displayId: sampleProvinceIdForOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final constrained = find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.maxHeight == viewportHeight,
      );
      expect(constrained, findsAtLeastNWidgets(1));
    });

    testWidgets(
      'Tile section shows ??? for unrevealed tiles in player-constrained view',
      (WidgetTester tester) async {
        final baseRegion = demoRegionForOverlay;
        final cells = <CellViewData>[];
        for (var i = 0; i < baseRegion.cells.length; i++) {
          final c = baseRegion.cells[i];
          cells.add(
            CellViewData(
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
              visibility:
                  i == 0 ? TileVisibility.unrevealed : c.visibility,
            ),
          );
        }
        final region = RegionMapViewData(
          regionId: baseRegion.regionId,
          width: baseRegion.width,
          height: baseRegion.height,
          cellSize: baseRegion.cellSize,
          cells: cells,
          capitalMarkers: baseRegion.capitalMarkers,
          portMarkers: baseRegion.portMarkers,
          factionColors: baseRegion.factionColors,
          terrainColors: baseRegion.terrainColors,
          unitMarkers: baseRegion.unitMarkers,
        );

        final hoveredCell = region.cells.first;
        final hoveredTileKey =
            '${region.regionId}|${hoveredCell.regionCellId}|${hoveredCell.x}|${hoveredCell.y}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: region,
                selectedId:
                    '${region.regionId}|${hoveredCell.regionCellId}',
                displayId:
                    '${region.regionId}|${hoveredCell.regionCellId}',
                humanPlayerId: demoGameForOverlay.players.first.id,
                hoveredTileKey: hoveredTileKey,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Coordinates: ???'), findsOneWidget);
        expect(find.textContaining('Terrain: ???'), findsOneWidget);
        expect(find.textContaining('Resource: ???'), findsOneWidget);
      },
    );

    testWidgets(
      'Province sections use ??? when province is fully unrevealed',
      (WidgetTester tester) async {
        final baseRegion = demoRegionForOverlay;
        final cells = baseRegion.cells
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
          regionId: baseRegion.regionId,
          width: baseRegion.width,
          height: baseRegion.height,
          cellSize: baseRegion.cellSize,
          cells: cells,
          capitalMarkers: baseRegion.capitalMarkers,
          portMarkers: baseRegion.portMarkers,
          factionColors: baseRegion.factionColors,
          terrainColors: baseRegion.terrainColors,
          unitMarkers: baseRegion.unitMarkers,
        );

        final provinceId =
            '${region.regionId}|${region.cells.first.regionCellId}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: region,
                selectedId: provinceId,
                displayId: provinceId,
                humanPlayerId: demoGameForOverlay.players.first.id,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('???'), findsWidgets);
      },
    );
  });

  group('ProvinceSeaZoneDetailOverlay with map', () {
    testWidgets('AC: Map and overlay appear side by side when province selected',
        (WidgetTester tester) async {
      final game = demoGameForOverlay;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: CtRegionMapDebug(
                    region: demoRegionForOverlay,
                    cellSizePx: 28,
                    onProvinceSelected: (_) {},
                    highlightedTileKey: null,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: ProvinceSeaZoneDetailOverlay(
                    game: game,
                    region: demoRegionForOverlay,
                    selectedId: sampleProvinceIdForOverlay,
                    displayId: sampleProvinceIdForOverlay,
                    humanPlayerId: game.players.first.id,
                    onClose: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtRegionMapDebug), findsOneWidget);
      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
    });

    testWidgets('AC: Map tap invokes onProvinceSelected; overlay can show selection',
        (WidgetTester tester) async {
      final region = demoRegionForOverlay;
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  children: [
                    SizedBox(
                      width: 400,
                      height: 320,
                      child: CtRegionMapDebug(
                        region: region,
                        cellSizePx: 28,
                        onProvinceSelected: (id) =>
                            setState(() => selectedId = id),
                        highlightedTileKey: null,
                      ),
                    ),
                    if (selectedId != null && selectedId!.isNotEmpty)
                      SizedBox(
                        width: 320,
                        child: ProvinceSeaZoneDetailOverlay(
                          game: demoGameForOverlay,
                          region: demoRegionForOverlay,
                          selectedId: selectedId!,
                          displayId: selectedId!,
                          humanPlayerId: demoGameForOverlay.players.first.id,
                          onClose: () => setState(() => selectedId = null),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(selectedId, isNull);
      final mapFinder = find.byType(CtRegionMapDebug);
      final element = tester.element(
        find.descendant(
          of: mapFinder,
          matching: find.byType(SizedBox),
        ).first,
      );
      final box = element.renderObject! as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(selectedId, isNotNull);
      expect(selectedId!, startsWith('${region.regionId}|'));
    });
  });
}
