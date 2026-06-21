// Widget tests for resource icon + label in province overlay (Tile + Economic).
// SPEC/ui/province-sea-zone-detail-overlay.md, SPEC/ui/pixel-art-ui-catalog.md.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pResTest';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

RegionMapViewData _regionWithCells(List<CellViewData> cells, int w, int h) {
  return RegionMapViewData(
    regionId: _regionId,
    width: w,
    height: h,
    cellSize: 32,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

Game _minimalGame({
  required Map<String, List<String>> tileKeysByProvince,
  Map<String, String> resourceByTileKey = const {},
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Map<String, Set<String>> playerProspectedTiles = const {},
}) {
  return Game(
    id: 'res_label_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            displayName: 'ResTest',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {_regionId: tileKeysByProvince},
      resourceByTileKey: resourceByTileKey,
      playerVisibilityByTile: playerVisibilityByTile,
      playerProspectedTiles: playerProspectedTiles,
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

PlayerView _omniscientViewForTiles(Iterable<String> keys) {
  return PlayerView(
    playerId: 'gp1',
    player: const Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {for (final k in keys) k: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay resource labels', () {
    testWidgets(
      'Tile and Economic show ResourceLabelInline when grain is visible and prospected',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = _minimalGame(
          tileKeysByProvince: {
            _fullProvinceId: [tk],
          },
          resourceByTileKey: {tk: 'grain'},
          playerVisibilityByTile: {
            'gp1': {tk: 'fullyVisible'},
          },
          playerProspectedTiles: {
            'gp1': {tk},
          },
        );
        final region = _regionWithCells(
          [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: _localProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              resourceId: 'grain',
              visibility: TileVisibility.visible,
            ),
          ],
          1,
          1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  displayId: _fullProvinceId,
                  selectedTileKey: tk,
                  humanPlayerId: 'gp1',
                  playerView: _omniscientViewForTiles([tk]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('grain'), findsNWidgets(2));
        expect(find.byType(ResourceLabelInline), findsNWidgets(2));
        expect(find.byType(StrictAssetIcon), findsNWidgets(2));
      },
    );

    testWidgets(
      'Economic excludes unprospected tile even when resource is visible in Tile section',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = _minimalGame(
          tileKeysByProvince: {
            _fullProvinceId: [tk],
          },
          resourceByTileKey: {tk: 'grain'},
          playerVisibilityByTile: {
            'gp1': {tk: 'fullyVisible'},
          },
          playerProspectedTiles: const {'gp1': <String>{}},
        );
        final region = _regionWithCells(
          [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: _localProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              resourceId: 'grain',
              visibility: TileVisibility.visible,
            ),
          ],
          1,
          1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  displayId: _fullProvinceId,
                  selectedTileKey: tk,
                  humanPlayerId: 'gp1',
                  playerView: _omniscientViewForTiles([tk]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('grain'), findsOneWidget);
        expect(find.byType(ResourceLabelInline), findsOneWidget);
      },
    );

    testWidgets(
      'Economic excludes prospected tiles with no discovered resource',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = _minimalGame(
          tileKeysByProvince: {
            _fullProvinceId: [tk],
          },
          resourceByTileKey: const {},
          playerVisibilityByTile: {
            'gp1': {tk: 'fullyVisible'},
          },
          playerProspectedTiles: {
            'gp1': {tk},
          },
        );
        final region = _regionWithCells(
          [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: _localProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              visibility: TileVisibility.visible,
            ),
          ],
          1,
          1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  displayId: _fullProvinceId,
                  selectedTileKey: tk,
                  humanPlayerId: 'gp1',
                  playerView: _omniscientViewForTiles([tk]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResourceLabelInline), findsNothing);
        expect(find.textContaining('Resource:'), findsWidgets);
      },
    );

    testWidgets('Tile shows plain em dash when tile has no visible resource', (
      WidgetTester tester,
    ) async {
      final tk = _tileKey(0, 0);
      final game = _minimalGame(
        tileKeysByProvince: {
          _fullProvinceId: [tk],
        },
        resourceByTileKey: const {},
        playerVisibilityByTile: {
          'gp1': {tk: 'fullyVisible'},
        },
      );
      final region = _regionWithCells(
        [
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'plains',
            visibility: TileVisibility.visible,
          ),
        ],
        1,
        1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: _fullProvinceId,
                selectedTileKey: tk,
                humanPlayerId: 'gp1',
                playerView: _omniscientViewForTiles([tk]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResourceLabelInline), findsNothing);
      expect(find.textContaining('Resource:'), findsWidgets);
    });

    testWidgets(
      'Prospect-required resource hidden until prospected (no ResourceLabelInline)',
      (WidgetTester tester) async {
        final tk = _tileKey(0, 0);
        final game = _minimalGame(
          tileKeysByProvince: {
            _fullProvinceId: [tk],
          },
          resourceByTileKey: {tk: 'iron'},
          playerVisibilityByTile: {
            'gp1': {tk: 'fullyVisible'},
          },
        );
        final region = _regionWithCells(
          [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: _localProvinceId,
              isSea: false,
              terrainTypeId: 'hills',
              resourceId: 'iron',
              visibility: TileVisibility.visible,
            ),
          ],
          1,
          1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                child: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: region,
                  displayId: _fullProvinceId,
                  selectedTileKey: tk,
                  humanPlayerId: 'gp1',
                  playerView: _omniscientViewForTiles([tk]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ResourceLabelInline), findsNothing);
        expect(find.text('iron'), findsNothing);
      },
    );

    testWidgets('Economic lists two province resources with icons (sorted)', (
      WidgetTester tester,
    ) async {
      final tk0 = _tileKey(0, 0);
      final tk1 = _tileKey(1, 0);
      final game = _minimalGame(
        tileKeysByProvince: {
          _fullProvinceId: [tk0, tk1],
        },
        resourceByTileKey: {tk0: 'timber', tk1: 'grain'},
        playerVisibilityByTile: {
          'gp1': {tk0: 'fullyVisible', tk1: 'fullyVisible'},
        },
        playerProspectedTiles: {
          'gp1': {tk0, tk1},
        },
      );
      final region = _regionWithCells(
        [
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'hardwoodForest',
            resourceId: 'timber',
            visibility: TileVisibility.visible,
          ),
          const CellViewData(
            x: 1,
            y: 0,
            regionCellId: _localProvinceId,
            isSea: false,
            terrainTypeId: 'plains',
            resourceId: 'grain',
            visibility: TileVisibility.visible,
          ),
        ],
        2,
        1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: _fullProvinceId,
                selectedTileKey: tk0,
                humanPlayerId: 'gp1',
                playerView: _omniscientViewForTiles([tk0, tk1]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('grain'), findsOneWidget);
      expect(find.text('timber'), findsNWidgets(2));
      expect(find.byType(ResourceLabelInline), findsNWidgets(3));
      expect(find.byType(StrictAssetIcon), findsNWidgets(3));
    });
  });
}
