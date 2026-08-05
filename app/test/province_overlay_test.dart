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
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';

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
  bool buildImprovementActionHasBuilderUnits = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  bool settle = true,
}) async {
  final g = game ?? demoGameForOverlay;
  // Editorial shell via [buildAppShell] (Refs #4035 — no inline MaterialApp).
  // Optional [mediaQuerySize] maps to the shell viewport wrapper.
  await tester.pumpWidget(
    buildAppShell(
      viewport: mediaQuerySize,
      child: Scaffold(
        body: ProvinceSeaZoneDetailOverlay(
          game: g,
          region: region ?? demoRegionForOverlay,
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
          buildImprovementActionHasBuilderUnits:
              buildImprovementActionHasBuilderUnits,
          onBuildImprovementTap: onBuildImprovementTap,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _pumpProvinceDemo(
  WidgetTester tester, {
  VoidCallback? onClose,
  bool showProspectActionIcon = false,
  bool prospectActionEnabled = false,
  VoidCallback? onProspectWithExplorerTap,
  bool showExploreActionIcon = false,
  bool exploreActionEnabled = false,
  VoidCallback? onExploreWithExplorerTap,
  bool showBuildImprovementActionIcon = false,
  bool buildImprovementActionEnabled = false,
  bool buildImprovementActionHasBuilderUnits = false,
  VoidCallback? onBuildImprovementTap,
  Size? mediaQuerySize,
  Game? game,
  RegionMapViewData? region,
}) {
  return _pumpOverlay(
    tester,
    displayId: sampleProvinceIdForOverlay,
    selectedTileKey: sampleTileKeyForProvinceOverlay,
    onClose: onClose,
    showProspectActionIcon: showProspectActionIcon,
    prospectActionEnabled: prospectActionEnabled,
    onProspectWithExplorerTap: onProspectWithExplorerTap,
    showExploreActionIcon: showExploreActionIcon,
    exploreActionEnabled: exploreActionEnabled,
    onExploreWithExplorerTap: onExploreWithExplorerTap,
    showBuildImprovementActionIcon: showBuildImprovementActionIcon,
    buildImprovementActionEnabled: buildImprovementActionEnabled,
    buildImprovementActionHasBuilderUnits: buildImprovementActionHasBuilderUnits,
    onBuildImprovementTap: onBuildImprovementTap,
    mediaQuerySize: mediaQuerySize,
    game: game,
    region: region,
  );
}

Future<void> _pumpNamedSea(
  WidgetTester tester, {
  RegionMapViewData? region,
}) async {
  await installNinePatchAssetMock();
  await _pumpOverlay(
    tester,
    displayId: sampleSeaZoneIdForOverlay,
    game: _namedSeaZoneGame(),
    region: region,
  );
}

void _expectMaxHeight(double maxHeight) {
  expect(
    find.byWidgetPredicate(
      (w) => w is ConstrainedBox && w.constraints.maxHeight == maxHeight,
    ),
    findsAtLeastNWidgets(1),
  );
}

/// Map + optional overlay side-by-side host (Refs #4021 densify).
/// Editorial shell via [buildAppShell] (Refs #4035 — no inline MaterialApp).
Widget _mapBesideOverlayHost({
  required Widget map,
  Widget? overlay,
  bool expandMap = true,
  double mapWidth = 400,
  double mapHeight = 320,
}) {
  return buildAppShell(
    child: Scaffold(
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
      'AC: province sections, name/owner, close, and sea-zone sections',
      (WidgetTester tester) async {
        final region = demoRegionForOverlay;
        final selectedId = sampleProvinceIdForOverlay;
        final cell = region.cells.firstWhere(
          (c) =>
              !c.isSea && '${region.regionId}|${c.regionCellId}' == selectedId,
        );
        final game = demoGameForOverlay;
        var closed = false;
        await _pumpProvinceDemo(tester, onClose: () => closed = true);

        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
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

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pumpAndSettle();
        expect(closed, isTrue);

        await _pumpOverlay(tester, displayId: sampleSeaZoneIdForOverlay);
        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        _expectOverlayTexts(const ['Sea zone', 'POLITICAL', 'NAVAL']);
      },
    );

    testWidgets('sea zone display name follows reveal/fog visibility', (
      WidgetTester tester,
    ) async {
      await _pumpNamedSea(tester);
      expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);

      await _pumpNamedSea(
        tester,
        region: _regionWithVisibility(
          demoRegionForOverlay,
          (_) => TileVisibility.unrevealed,
        ),
      );
      expect(find.textContaining('Named Test Sea'), findsNothing);
      expect(find.textContaining('Sea zone:'), findsNothing);
      expect(find.text('???'), findsWidgets);

      final seaParts = sampleSeaZoneIdForOverlay.split('|');
      final localSea = seaParts.length >= 2
          ? seaParts.sublist(1).join('|')
          : sampleSeaZoneIdForOverlay;
      var revealOneSeaInZone = true;
      await _pumpNamedSea(
        tester,
        region: _regionWithVisibility(demoRegionForOverlay, (c) {
          final inZone = c.isSea && c.regionCellId == localSea;
          if (inZone && revealOneSeaInZone) {
            revealOneSeaInZone = false;
            return TileVisibility.fogged;
          }
          return TileVisibility.unrevealed;
        }),
      );
      expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);
    });

    testWidgets('tile shortcut tooltips: prospect / explore order / build', (
      WidgetTester tester,
    ) async {
      await _pumpProvinceDemo(
        tester,
        showProspectActionIcon: true,
        prospectActionEnabled: true,
        onProspectWithExplorerTap: () {},
      );
      expect(find.byTooltip('Prospect with explorer'), findsOneWidget);

      await _pumpProvinceDemo(
        tester,
        showExploreActionIcon: true,
        exploreActionEnabled: true,
        onExploreWithExplorerTap: () {},
        showProspectActionIcon: true,
        prospectActionEnabled: true,
        onProspectWithExplorerTap: () {},
        showBuildImprovementActionIcon: true,
        buildImprovementActionEnabled: true,
        buildImprovementActionHasBuilderUnits: true,
        onBuildImprovementTap: () {},
      );
      final exploreFinder = find.byTooltip('Explore with explorer');
      final prospectFinder = find.byTooltip('Prospect with explorer');
      final buildImprovementFinder = find.byWidgetPredicate(
        (widget) => widget is CtIconAction && widget.icon == Icons.handyman,
      );
      expect(exploreFinder, findsOneWidget);
      expect(prospectFinder, findsOneWidget);
      expect(buildImprovementFinder, findsOneWidget);
      expect(
        tester.getTopLeft(exploreFinder).dx,
        lessThan(tester.getTopLeft(prospectFinder).dx),
      );
    });

    testWidgets('AC: overlay height — narrow one-third vs desktop full', (
      WidgetTester tester,
    ) async {
      const viewportHeight = 600.0;
      for (final case_ in <({double width, double maxHeight})>[
        (width: 400, maxHeight: 198.0), // 0.33 * 600
        (width: 800, maxHeight: viewportHeight),
      ]) {
        await _pumpProvinceDemo(
          tester,
          onClose: () {},
          mediaQuerySize: Size(case_.width, viewportHeight),
        );
        _expectMaxHeight(case_.maxHeight);
      }
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
