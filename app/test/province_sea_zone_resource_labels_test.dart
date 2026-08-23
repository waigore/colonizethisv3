// Widget tests for resource icon + label in province overlay (Tile + Economic).
// SPEC/ui/province-sea-zone-detail-overlay.md, SPEC/ui/pixel-art-ui-catalog.md.

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';

import 'province_sea_zone_resource_labels_test_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay resource labels', () {
    testWidgets(
      'Tile and Economic show ResourceLabelInline when grain is visible and prospected',
      (WidgetTester tester) async {
        final tk = resourceLabelTileKey(0, 0);
        await pumpResourceLabelOverlay(
          tester,
          game: resourceLabelMinimalGame(
            tileKeysByProvince: {
              resourceLabelFullProvinceId: [tk],
            },
            resourceByTileKey: {tk: 'grain'},
            playerVisibilityByTile: {
              'gp1': {tk: 'fullyVisible'},
            },
            playerProspectedTiles: {
              'gp1': {tk},
            },
          ),
          region: resourceLabelRegionWithCells(
            [
              const CellViewData(
                x: 0,
                y: 0,
                regionCellId: resourceLabelLocalProvinceId,
                isSea: false,
                terrainTypeId: 'plains',
                resourceId: 'grain',
                visibility: TileVisibility.visible,
              ),
            ],
            1,
            1,
          ),
          selectedTileKey: tk,
          viewTileKeys: [tk],
        );

        expect(find.text('Grain'), findsNWidgets(2));
        expect(find.byType(ResourceLabelInline), findsNWidgets(2));
        expect(find.byType(StrictAssetIcon), findsNWidgets(2));
      },
    );

    testWidgets(
      'Economic excludes unprospected tile even when resource is visible in Tile section',
      (WidgetTester tester) async {
        final tk = resourceLabelTileKey(0, 0);
        await pumpResourceLabelOverlay(
          tester,
          game: resourceLabelMinimalGame(
            tileKeysByProvince: {
              resourceLabelFullProvinceId: [tk],
            },
            resourceByTileKey: {tk: 'grain'},
            playerVisibilityByTile: {
              'gp1': {tk: 'fullyVisible'},
            },
            playerProspectedTiles: const {'gp1': <String>{}},
          ),
          region: resourceLabelRegionWithCells(
            [
              const CellViewData(
                x: 0,
                y: 0,
                regionCellId: resourceLabelLocalProvinceId,
                isSea: false,
                terrainTypeId: 'plains',
                resourceId: 'grain',
                visibility: TileVisibility.visible,
              ),
            ],
            1,
            1,
          ),
          selectedTileKey: tk,
          viewTileKeys: [tk],
        );

        expect(find.text('Grain'), findsOneWidget);
        expect(find.byType(ResourceLabelInline), findsOneWidget);
      },
    );

    testWidgets(
      'Economic excludes prospected tiles with no discovered resource',
      (WidgetTester tester) async {
        final tk = resourceLabelTileKey(0, 0);
        await pumpResourceLabelOverlay(
          tester,
          game: resourceLabelMinimalGame(
            tileKeysByProvince: {
              resourceLabelFullProvinceId: [tk],
            },
            resourceByTileKey: const {},
            playerVisibilityByTile: {
              'gp1': {tk: 'fullyVisible'},
            },
            playerProspectedTiles: {
              'gp1': {tk},
            },
          ),
          region: resourceLabelRegionWithCells(
            [
              const CellViewData(
                x: 0,
                y: 0,
                regionCellId: resourceLabelLocalProvinceId,
                isSea: false,
                terrainTypeId: 'plains',
                visibility: TileVisibility.visible,
              ),
            ],
            1,
            1,
          ),
          selectedTileKey: tk,
          viewTileKeys: [tk],
        );

        expect(find.byType(ResourceLabelInline), findsNothing);
        expect(find.textContaining('Resource:'), findsWidgets);
      },
    );

    testWidgets('Tile shows plain em dash when tile has no visible resource', (
      WidgetTester tester,
    ) async {
      final tk = resourceLabelTileKey(0, 0);
      await pumpResourceLabelOverlay(
        tester,
        game: resourceLabelMinimalGame(
          tileKeysByProvince: {
            resourceLabelFullProvinceId: [tk],
          },
          resourceByTileKey: const {},
          playerVisibilityByTile: {
            'gp1': {tk: 'fullyVisible'},
          },
        ),
        region: resourceLabelRegionWithCells(
          [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: resourceLabelLocalProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              visibility: TileVisibility.visible,
            ),
          ],
          1,
          1,
        ),
        selectedTileKey: tk,
        viewTileKeys: [tk],
      );

      expect(find.byType(ResourceLabelInline), findsNothing);
      expect(find.textContaining('Resource:'), findsWidgets);
    });

    testWidgets(
      'Prospect-required resource hidden until prospected (no ResourceLabelInline)',
      (WidgetTester tester) async {
        final tk = resourceLabelTileKey(0, 0);
        await pumpResourceLabelOverlay(
          tester,
          game: resourceLabelMinimalGame(
            tileKeysByProvince: {
              resourceLabelFullProvinceId: [tk],
            },
            resourceByTileKey: {tk: 'iron'},
            playerVisibilityByTile: {
              'gp1': {tk: 'fullyVisible'},
            },
          ),
          region: resourceLabelRegionWithCells(
            [
              const CellViewData(
                x: 0,
                y: 0,
                regionCellId: resourceLabelLocalProvinceId,
                isSea: false,
                terrainTypeId: 'hills',
                resourceId: 'iron',
                visibility: TileVisibility.visible,
              ),
            ],
            1,
            1,
          ),
          selectedTileKey: tk,
          viewTileKeys: [tk],
        );

        expect(find.byType(ResourceLabelInline), findsNothing);
        expect(find.text('iron'), findsNothing);
      },
    );

    testWidgets('Economic lists two province resources with icons (sorted)', (
      WidgetTester tester,
    ) async {
      final tk0 = resourceLabelTileKey(0, 0);
      final tk1 = resourceLabelTileKey(1, 0);
      await pumpResourceLabelOverlay(
        tester,
        game: resourceLabelMinimalGame(
          tileKeysByProvince: {
            resourceLabelFullProvinceId: [tk0, tk1],
          },
          resourceByTileKey: {tk0: 'timber', tk1: 'grain'},
          playerVisibilityByTile: {
            'gp1': {tk0: 'fullyVisible', tk1: 'fullyVisible'},
          },
          playerProspectedTiles: {
            'gp1': {tk0, tk1},
          },
        ),
        region: resourceLabelRegionWithCells(
          [
            const CellViewData(
              x: 0,
              y: 0,
              regionCellId: resourceLabelLocalProvinceId,
              isSea: false,
              terrainTypeId: 'hardwoodForest',
              resourceId: 'timber',
              visibility: TileVisibility.visible,
            ),
            const CellViewData(
              x: 1,
              y: 0,
              regionCellId: resourceLabelLocalProvinceId,
              isSea: false,
              terrainTypeId: 'plains',
              resourceId: 'grain',
              visibility: TileVisibility.visible,
            ),
          ],
          2,
          1,
        ),
        selectedTileKey: tk0,
        viewTileKeys: [tk0, tk1],
      );

      expect(find.text('Grain'), findsOneWidget);
      expect(find.text('Timber'), findsNWidgets(2));
      expect(find.byType(ResourceLabelInline), findsNWidgets(3));
      expect(find.byType(StrictAssetIcon), findsNWidgets(3));
    });
  });
}
