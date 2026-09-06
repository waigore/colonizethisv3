// Economic multi-resource label pins for province overlay resource rows.

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';

import 'province_sea_zone_resource_labels_test_support.dart';

void main() {
  suppressLogsForTests();

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
}
