// Tests for ProvinceSeaZoneDetailOverlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/widgets/ct_region_map.dart';

import 'support/widget_test_assets.dart';

CellViewData _copyCell(
  CellViewData c, {
  TileVisibility? visibility,
}) {
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
    visibility: visibility ?? c.visibility,
  );
}

RegionMapViewData _regionWithCells(
  RegionMapViewData base,
  List<CellViewData> cells,
) {
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: cells,
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

RegionMapViewData _regionWithVisibility(
  RegionMapViewData base,
  TileVisibility Function(CellViewData c) visibilityFor,
) {
  return _regionWithCells(
    base,
    base.cells.map((c) => _copyCell(c, visibility: visibilityFor(c))).toList(),
  );
}

Game _namedSeaZoneGame({String name = 'Named Test Sea'}) {
  final game = demoGameForOverlay;
  return game.copyWith(
    worldState: game.worldState.copyWith(
      seaZoneDisplayNameById: {sampleSeaZoneIdForOverlay: name},
    ),
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required String displayId,
  String? selectedTileKey,
  Game? game,
  RegionMapViewData? region,
  void Function(String?)? onHighlightTile,
  VoidCallback? onClose,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  bool settle = true,
}) async {
  final g = game ?? demoGameForOverlay;
  final r = region ?? demoRegionForOverlay;
  Widget child = MaterialApp(
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: g,
        region: r,
        displayId: displayId,
        selectedTileKey: selectedTileKey,
        humanPlayerId: g.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        onHighlightTile: onHighlightTile,
        onClose: onClose,
        showProspectActionIcon: showProspectActionIcon,
        prospectActionEnabled: prospectActionEnabled,
        onProspectWithExplorerTap: onProspectWithExplorerTap,
        showExploreActionIcon: showExploreActionIcon,
        exploreActionEnabled: exploreActionEnabled,
        onExploreWithExplorerTap: onExploreWithExplorerTap,
        showBuildImprovementActionIcon: showBuildImprovementActionIcon,
        buildImprovementActionEnabled: buildImprovementActionEnabled,
        onBuildImprovementTap: onBuildImprovementTap,
      ),
    ),
  );
  if (mediaQuerySize != null) {
    child = MediaQuery(
      data: MediaQueryData(size: mediaQuerySize),
      child: child,
    );
  }
  await tester.pumpWidget(child);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Map + optional overlay side-by-side host (Refs #4021 densify).
Widget _mapBesideOverlayHost({
  required Widget map,
  Widget? overlay,
  bool expandMap = true,
  double mapWidth = 400,
  double mapHeight = 320,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        children: [
          if (expandMap)
            Expanded(child: map)
          else
            SizedBox(width: mapWidth, height: mapHeight, child: map),
          if (overlay != null) SizedBox(width: 320, child: overlay),
        ],
      ),
    ),
  );
}

ProvinceSeaZoneDetailOverlay _demoOverlay({
  required String displayId,
  required String? selectedTileKey,
  required VoidCallback onClose,
}) {
  final g = demoGameForOverlay;
  return ProvinceSeaZoneDetailOverlay(
    game: g,
    region: demoRegionForOverlay,
    displayId: displayId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: g.players.first.id,
    playerView: demoHumanPlayerViewForOverlay,
    onClose: onClose,
  );
}

void _expectOverlayTexts(Iterable<String> texts) {
  for (final text in texts) {
    expect(find.text(text), findsOneWidget);
  }
}

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
    testWidgets(
      'AC: Standalone province overlay displays Political, Economic, Military, Civilian, Naval',
      (WidgetTester tester) async {
        await _pumpOverlay(
          tester,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
        );

        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        // Section headers render via CtSectionLabel (Refs #2865 S4) which
        // upper-cases the label per SPEC § Dark-theme section labels.
        _expectOverlayTexts(const [
          'Province',
          'TILE',
          'POLITICAL',
          'ECONOMIC',
          'MILITARY',
          'CIVILIAN',
          'NAVAL',
        ]);
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
      await _pumpOverlay(
        tester,
        displayId: selectedId,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
      );

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
      await _pumpOverlay(tester, displayId: sampleSeaZoneIdForOverlay);

      expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
      _expectOverlayTexts(const ['Sea zone', 'POLITICAL', 'NAVAL']);
    });

    testWidgets('sea zone overlay uses sea-zone display name field', (
      WidgetTester tester,
    ) async {
      await installNinePatchAssetMock();
      await _pumpOverlay(
        tester,
        displayId: sampleSeaZoneIdForOverlay,
        game: _namedSeaZoneGame(),
      );

      expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);
    });

    testWidgets(
      'AC: sea zone hides canonical name when all sea tiles in zone are unrevealed',
      (WidgetTester tester) async {
        await installNinePatchAssetMock();
        final region = _regionWithVisibility(
          demoRegionForOverlay,
          (_) => TileVisibility.unrevealed,
        );
        await _pumpOverlay(
          tester,
          displayId: sampleSeaZoneIdForOverlay,
          game: _namedSeaZoneGame(),
          region: region,
        );

        expect(find.textContaining('Named Test Sea'), findsNothing);
        expect(find.textContaining('Sea zone:'), findsNothing);
        expect(find.text('???'), findsWidgets);
      },
    );

    testWidgets(
      'AC: sea zone shows display name when at least one sea tile in zone is fogged',
      (WidgetTester tester) async {
        await installNinePatchAssetMock();

        final seaPrefixed = sampleSeaZoneIdForOverlay;
        final seaParts = seaPrefixed.split('|');
        final localSea = seaParts.length >= 2
            ? seaParts.sublist(1).join('|')
            : seaPrefixed;
        var revealOneSeaInZone = true;
        final region = _regionWithVisibility(demoRegionForOverlay, (c) {
          final inZone = c.isSea && c.regionCellId == localSea;
          if (inZone && revealOneSeaInZone) {
            revealOneSeaInZone = false;
            return TileVisibility.fogged;
          }
          return TileVisibility.unrevealed;
        });

        await _pumpOverlay(
          tester,
          displayId: sampleSeaZoneIdForOverlay,
          game: _namedSeaZoneGame(),
          region: region,
        );

        expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);
      },
    );

    testWidgets('AC: Close button invokes onClose', (
      WidgetTester tester,
    ) async {
      var closed = false;
      await _pumpOverlay(
        tester,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        onClose: () => closed = true,
      );

      await tester.tap(find.byKey(const Key('overlay_close')));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets(
      'Tile prospected row shows prospect shortcut icon with tooltip when enabled',
      (WidgetTester tester) async {
        await _pumpOverlay(
          tester,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          showProspectActionIcon: true,
          prospectActionEnabled: true,
          onProspectWithExplorerTap: () {},
        );

        expect(find.byTooltip('Prospect with explorer'), findsOneWidget);
      },
    );

    testWidgets(
      'Tile prospected row shows explore icon before prospect when both enabled',
      (WidgetTester tester) async {
        await _pumpOverlay(
          tester,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          showExploreActionIcon: true,
          exploreActionEnabled: true,
          onExploreWithExplorerTap: () {},
          showProspectActionIcon: true,
          prospectActionEnabled: true,
          onProspectWithExplorerTap: () {},
        );

        final exploreFinder = find.byTooltip('Explore with explorer');
        final prospectFinder = find.byTooltip('Prospect with explorer');
        expect(exploreFinder, findsOneWidget);
        expect(prospectFinder, findsOneWidget);
        expect(
          tester.getTopLeft(exploreFinder).dx,
          lessThan(tester.getTopLeft(prospectFinder).dx),
        );
      },
    );

    testWidgets(
      'Tile improvement row shows build improvement shortcut icon tooltip when enabled',
      (WidgetTester tester) async {
        await _pumpOverlay(
          tester,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          showBuildImprovementActionIcon: true,
          buildImprovementActionEnabled: true,
          onBuildImprovementTap: () {},
        );

        expect(find.byTooltip('Build improvement'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: Overlay constrained to one-third height on narrow viewport',
      (WidgetTester tester) async {
        const viewportHeight = 600.0;
        const expectedMaxHeight = 198.0; // 0.33 * 600
        await _pumpOverlay(
          tester,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          onClose: () {},
          mediaQuerySize: const Size(400, viewportHeight),
        );

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is ConstrainedBox &&
                w.constraints.maxHeight == expectedMaxHeight,
          ),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets('AC: Overlay uses full height on desktop', (
      WidgetTester tester,
    ) async {
      const viewportHeight = 600.0;
      await _pumpOverlay(
        tester,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        onClose: () {},
        mediaQuerySize: const Size(800, viewportHeight),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is ConstrainedBox && w.constraints.maxHeight == viewportHeight,
        ),
        findsAtLeastNWidgets(1),
      );
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
        final region = _regionWithVisibility(
          baseRegion,
          (c) => c.x == targetCell.x && c.y == targetCell.y
              ? TileVisibility.unrevealed
              : c.visibility,
        );

        final selectedTileKey =
            '${region.regionId}|${targetCell.regionCellId}|${targetCell.x}|${targetCell.y}';
        final provinceId = '${region.regionId}|${targetCell.regionCellId}';

        await _pumpOverlay(
          tester,
          displayId: provinceId,
          selectedTileKey: selectedTileKey,
          region: region,
          onClose: () {},
        );

        expect(find.textContaining('Coordinates: ???'), findsOneWidget);
        expect(find.textContaining('Terrain: ???'), findsOneWidget);
        expect(find.textContaining('Resource: ???'), findsOneWidget);
      },
    );

    testWidgets('Province sections use ??? when province is fully unrevealed', (
      WidgetTester tester,
    ) async {
      final region = _regionWithVisibility(
        demoRegionForOverlay,
        (_) => TileVisibility.unrevealed,
      );
      final provinceId =
          '${region.regionId}|${region.cells.first.regionCellId}';

      await _pumpOverlay(
        tester,
        displayId: provinceId,
        region: region,
        onClose: () {},
      );

      expect(find.text('???'), findsWidgets);
    });
  });

  group('ProvinceSeaZoneDetailOverlay with map', () {
    testWidgets('AC: Map orange selection may persist after overlay closes', (
      WidgetTester tester,
    ) async {
      final selectedTk = sampleTileKeyForProvinceOverlay;
      var overlayOpen = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _mapBesideOverlayHost(
              map: CtRegionMap(
                region: demoRegionForOverlay,
                cellSizePx: 28,
                selectedTileKey: selectedTk,
              ),
              overlay: overlayOpen
                  ? _demoOverlay(
                      displayId: sampleProvinceIdForOverlay,
                      selectedTileKey: selectedTk,
                      onClose: () => setState(() => overlayOpen = false),
                    )
                  : null,
            );
          },
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
          StatefulBuilder(
            builder: (context, setState) {
              final tk = selectedTileKey;
              final parts = tk?.split('|') ?? const <String>[];
              final displayId = parts.length >= 2
                  ? '${parts[0]}|${parts[1]}'
                  : '';
              return _mapBesideOverlayHost(
                expandMap: false,
                map: CtRegionMap(
                  region: region,
                  cellSizePx: 28,
                  selectedTileKey: selectedTileKey,
                  onMapTileTappedForDetail: (next) => setState(() {
                    selectedTileKey = next;
                    overlayOpen = true;
                  }),
                ),
                overlay: overlayOpen && tk != null
                    ? _demoOverlay(
                        displayId: displayId,
                        selectedTileKey: tk,
                        onClose: () => setState(() => overlayOpen = false),
                      )
                    : null,
              );
            },
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
