// Tests for ProvinceSeaZoneDetailOverlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/widgets/ct_region_map.dart';

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
      required String displayId,
      String? selectedTileKey,
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
            displayId: displayId,
            selectedTileKey: selectedTileKey,
            humanPlayerId: game.players.first.id,
            playerView: demoHumanPlayerViewForOverlay,
            onHighlightTile: onHighlightTile,
            onClose: onClose,
          ),
        ),
      );
    }

    testWidgets('AC: Standalone province overlay displays Political, Economic, Military, Civilian, Naval',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOverlay(
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Province'), findsOneWidget);
      expect(find.text('Tile'), findsOneWidget);
      expect(find.text('Political'), findsOneWidget);
      expect(find.text('Economic'), findsOneWidget);
      expect(find.text('Military'), findsOneWidget);
      expect(find.text('Civilian'), findsOneWidget);
      expect(find.text('Naval'), findsOneWidget);
      expect(find.byKey(const Key('overlay_close')), findsOneWidget);
    });

    testWidgets('AC: Province overlay shows province name and owner',
        (WidgetTester tester) async {
      final region = demoRegionForOverlay;
      final selectedId = sampleProvinceIdForOverlay;
      final cell = region.cells.firstWhere(
        (c) => !c.isSea && '${region.regionId}|${c.regionCellId}' == selectedId,
      );
      final game = demoGameForOverlay;
      await tester.pumpWidget(buildOverlay(
        displayId: selectedId,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
      ));
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
      await tester.pumpWidget(buildOverlay(displayId: sampleSeaZoneIdForOverlay));
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Sea zone'), findsOneWidget);
      expect(find.text('Political'), findsOneWidget);
      expect(find.text('Naval'), findsOneWidget);
    });

    testWidgets('AC: Close button invokes onClose', (WidgetTester tester) async {
      var closed = false;
      await tester.pumpWidget(buildOverlay(
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        onClose: () => closed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overlay_close')));
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
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
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
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
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
          greatPowerFactionIds: baseRegion.greatPowerFactionIds,
          terrainColors: baseRegion.terrainColors,
          unitMarkers: baseRegion.unitMarkers,
        );

        final hoveredCell = region.cells.first;
        final selectedTileKey =
            '${region.regionId}|${hoveredCell.regionCellId}|${hoveredCell.x}|${hoveredCell.y}';
        final provinceId =
            '${region.regionId}|${hoveredCell.regionCellId}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: region,
                displayId: provinceId,
                selectedTileKey: selectedTileKey,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
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
          greatPowerFactionIds: baseRegion.greatPowerFactionIds,
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
                displayId: provinceId,
                selectedTileKey: null,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
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
    testWidgets(
      'AC: Map orange selection may persist after overlay closes',
      (WidgetTester tester) async {
        final game = demoGameForOverlay;
        final selectedTk = sampleTileKeyForProvinceOverlay;
        var overlayOpen = true;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Row(
                    children: [
                      Expanded(
                        child: CtRegionMap(
                          region: demoRegionForOverlay,
                          cellSizePx: 28,
                          selectedTileKey: selectedTk,
                        ),
                      ),
                      if (overlayOpen)
                        SizedBox(
                          width: 320,
                          child: ProvinceSeaZoneDetailOverlay(
                            game: game,
                            region: demoRegionForOverlay,
                            displayId: sampleProvinceIdForOverlay,
                            selectedTileKey: selectedTk,
                            humanPlayerId: game.players.first.id,
                            playerView: demoHumanPlayerViewForOverlay,
                            onClose: () => setState(() {
                              overlayOpen = false;
                            }),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CtRegionMap), findsOneWidget);
        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pumpAndSettle();

        expect(overlayOpen, isFalse);
        expect(selectedTk, isNotEmpty);
      },
    );

    testWidgets(
        'AC: Map tap sets tile key and opens overlay; stays open until closed',
        (WidgetTester tester) async {
      final region = demoRegionForOverlay;
      String? selectedTileKey;
      var overlayOpen = false;
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
                      child: CtRegionMap(
                        region: region,
                        cellSizePx: 28,
                        selectedTileKey: selectedTileKey,
                        onMapTileTappedForDetail: (tk) => setState(() {
                          selectedTileKey = tk;
                          overlayOpen = true;
                        }),
                      ),
                    ),
                    if (overlayOpen && selectedTileKey != null)
                      SizedBox(
                        width: 320,
                        child: ProvinceSeaZoneDetailOverlay(
                          game: demoGameForOverlay,
                          region: demoRegionForOverlay,
                          displayId: selectedTileKey!.split('|').length >= 2
                              ? '${selectedTileKey!.split('|')[0]}|${selectedTileKey!.split('|')[1]}'
                              : '',
                          selectedTileKey: selectedTileKey,
                          humanPlayerId: demoGameForOverlay.players.first.id,
                          playerView: demoHumanPlayerViewForOverlay,
                          onClose: () => setState(() {
                            overlayOpen = false;
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(overlayOpen, isFalse);
      final mapFinder = find.byType(CtRegionMap);
      await tester.tap(mapFinder);
      await tester.pump();

      expect(selectedTileKey, isNotNull);
      expect(overlayOpen, isTrue);
      expect(selectedTileKey!, startsWith('${region.regionId}|'));

      await tester.tap(mapFinder);
      await tester.pump();
      expect(overlayOpen, isTrue);

      await tester.tap(find.byKey(const Key('overlay_close')));
      await tester.pump();
      expect(overlayOpen, isFalse);
    });
  });
}
