// Tests for ProvinceSeaZoneDetailOverlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'dart:convert';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(
        game.worldState.oldWorld.provinces.length,
        greaterThanOrEqualTo(1),
      );
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

    testWidgets(
      'AC: Standalone province overlay displays Political, Economic, Military, Civilian, Naval',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildOverlay(
            displayId: sampleProvinceIdForOverlay,
            selectedTileKey: sampleTileKeyForProvinceOverlay,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        expect(find.text('Province'), findsOneWidget);
        // Section headers render via CtSectionLabel (Refs #2865 S4) which
        // upper-cases the label per SPEC § Dark-theme section labels.
        expect(find.text('TILE'), findsOneWidget);
        expect(find.text('POLITICAL'), findsOneWidget);
        expect(find.text('ECONOMIC'), findsOneWidget);
        expect(find.text('MILITARY'), findsOneWidget);
        expect(find.text('CIVILIAN'), findsOneWidget);
        expect(find.text('NAVAL'), findsOneWidget);
        expect(find.byKey(const Key('overlay_close')), findsOneWidget);
      },
    );

    testWidgets('AC: Province overlay shows province name and owner', (
      WidgetTester tester,
    ) async {
      final region = demoRegionForOverlay;
      final selectedId = sampleProvinceIdForOverlay;
      final cell = region.cells.firstWhere(
        (c) => !c.isSea && '${region.regionId}|${c.regionCellId}' == selectedId,
      );
      final game = demoGameForOverlay;
      await tester.pumpWidget(
        buildOverlay(
          displayId: selectedId,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
        ),
      );
      await tester.pumpAndSettle();

      final provinceName = cell.provinceDisplayName ?? cell.regionCellId;
      expect(provinceName, isNotEmpty);
      expect(find.textContaining(provinceName), findsAtLeastNWidgets(1));
      final ownerId = cell.ownerFactionId;
      if (ownerId != null && ownerId.isNotEmpty) {
        final ownerName =
            game.players
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

    testWidgets('AC: Sea zone overlay displays Political and Naval', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildOverlay(displayId: sampleSeaZoneIdForOverlay),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      expect(find.text('Sea zone'), findsOneWidget);
      // Section headers render via CtSectionLabel (Refs #2865 S4) which
      // upper-cases the label per SPEC § Dark-theme section labels.
      expect(find.text('POLITICAL'), findsOneWidget);
      expect(find.text('NAVAL'), findsOneWidget);
    });

    testWidgets('sea zone overlay uses sea-zone display name field', (
      WidgetTester tester,
    ) async {
      const tinyPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=';
      final tinyPng = Uint8List.fromList(base64Decode(tinyPngBase64));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final key = const StringCodec().decodeMessage(message);
            if (key == 'assets/images/ui_button_nine_patch.png') {
              return ByteData.view(tinyPng.buffer);
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      final game = demoGameForOverlay;
      final named = game.copyWith(
        worldState: game.worldState.copyWith(
          seaZoneDisplayNameById: {sampleSeaZoneIdForOverlay: 'Named Test Sea'},
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: named,
              region: demoRegionForOverlay,
              displayId: sampleSeaZoneIdForOverlay,
              selectedTileKey: null,
              humanPlayerId: named.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);
    });

    testWidgets(
      'AC: sea zone hides canonical name when all sea tiles in zone are unrevealed',
      (WidgetTester tester) async {
        const tinyPngBase64 =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=';
        final tinyPng = Uint8List.fromList(base64Decode(tinyPngBase64));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
              final key = const StringCodec().decodeMessage(message);
              if (key == 'assets/images/ui_button_nine_patch.png') {
                return ByteData.view(tinyPng.buffer);
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMessageHandler('flutter/assets', null);
        });

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

        final game = demoGameForOverlay;
        final named = game.copyWith(
          worldState: game.worldState.copyWith(
            seaZoneDisplayNameById: {
              sampleSeaZoneIdForOverlay: 'Named Test Sea',
            },
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: named,
                region: region,
                displayId: sampleSeaZoneIdForOverlay,
                selectedTileKey: null,
                humanPlayerId: named.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Named Test Sea'), findsNothing);
        expect(find.textContaining('Sea zone:'), findsNothing);
        expect(find.text('???'), findsWidgets);
      },
    );

    testWidgets(
      'AC: sea zone shows display name when at least one sea tile in zone is fogged',
      (WidgetTester tester) async {
        const tinyPngBase64 =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=';
        final tinyPng = Uint8List.fromList(base64Decode(tinyPngBase64));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) async {
              final key = const StringCodec().decodeMessage(message);
              if (key == 'assets/images/ui_button_nine_patch.png') {
                return ByteData.view(tinyPng.buffer);
              }
              return null;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMessageHandler('flutter/assets', null);
        });

        final baseRegion = demoRegionForOverlay;
        final seaPrefixed = sampleSeaZoneIdForOverlay;
        final seaParts = seaPrefixed.split('|');
        final localSea = seaParts.length >= 2
            ? seaParts.sublist(1).join('|')
            : seaPrefixed;
        var revealOneSeaInZone = true;
        final cells = baseRegion.cells.map((c) {
          final inZone = c.isSea && c.regionCellId == localSea;
          var visibility = TileVisibility.unrevealed;
          if (inZone && revealOneSeaInZone) {
            revealOneSeaInZone = false;
            visibility = TileVisibility.fogged;
          }
          return CellViewData(
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
            visibility: visibility,
          );
        }).toList();
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

        final game = demoGameForOverlay;
        final named = game.copyWith(
          worldState: game.worldState.copyWith(
            seaZoneDisplayNameById: {
              sampleSeaZoneIdForOverlay: 'Named Test Sea',
            },
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: named,
                region: region,
                displayId: sampleSeaZoneIdForOverlay,
                selectedTileKey: null,
                humanPlayerId: named.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);
      },
    );

    testWidgets('AC: Close button invokes onClose', (
      WidgetTester tester,
    ) async {
      var closed = false;
      await tester.pumpWidget(
        buildOverlay(
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          onClose: () => closed = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overlay_close')));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets(
      'Tile prospected row shows prospect shortcut icon with tooltip when enabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: demoRegionForOverlay,
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                showProspectActionIcon: true,
                prospectActionEnabled: true,
                onProspectWithExplorerTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Prospect with explorer'), findsOneWidget);
      },
    );

    testWidgets(
      'Tile prospected row shows explore icon before prospect when both enabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: demoRegionForOverlay,
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                showExploreActionIcon: true,
                exploreActionEnabled: true,
                onExploreWithExplorerTap: () {},
                showProspectActionIcon: true,
                prospectActionEnabled: true,
                onProspectWithExplorerTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final exploreFinder = find.byTooltip('Explore with explorer');
        final prospectFinder = find.byTooltip('Prospect with explorer');
        expect(exploreFinder, findsOneWidget);
        expect(prospectFinder, findsOneWidget);
        final exploreX = tester.getTopLeft(exploreFinder).dx;
        final prospectX = tester.getTopLeft(prospectFinder).dx;
        expect(exploreX, lessThan(prospectX));
      },
    );

    testWidgets(
      'Tile improvement row shows build improvement shortcut icon tooltip when enabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: demoGameForOverlay,
                region: demoRegionForOverlay,
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: demoGameForOverlay.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                showBuildImprovementActionIcon: true,
                buildImprovementActionEnabled: true,
                onBuildImprovementTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Build improvement'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Overlay constrained to one-third height on narrow viewport',
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
      },
    );

    testWidgets('AC: Overlay uses full height on desktop', (
      WidgetTester tester,
    ) async {
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
        (w) => w is ConstrainedBox && w.constraints.maxHeight == viewportHeight,
      );
      expect(constrained, findsAtLeastNWidgets(1));
    });

    testWidgets(
      'Tile section shows ??? for unrevealed tiles in player-constrained view',
      (WidgetTester tester) async {
        final baseRegion = demoRegionForOverlay;
        final targetCell = baseRegion.cells.firstWhere(
          (c) =>
              !c.isSea &&
              baseRegion.cells.any(
                (other) =>
                    other.regionCellId == c.regionCellId &&
                    other.visibility != TileVisibility.unrevealed,
              ),
        );
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
                visibility: c.x == targetCell.x && c.y == targetCell.y
                    ? TileVisibility.unrevealed
                    : c.visibility,
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

        final selectedTileKey =
            '${region.regionId}|${targetCell.regionCellId}|${targetCell.x}|${targetCell.y}';
        final provinceId = '${region.regionId}|${targetCell.regionCellId}';

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

    testWidgets('Province sections use ??? when province is fully unrevealed', (
      WidgetTester tester,
    ) async {
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
    });
  });

  group('ProvinceSeaZoneDetailOverlay with map', () {
    testWidgets('AC: Map orange selection may persist after overlay closes', (
      WidgetTester tester,
    ) async {
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
    });

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
      },
    );
  });
}
