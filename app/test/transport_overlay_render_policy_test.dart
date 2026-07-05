import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        isRailTransportLevel,
        shouldPaintTransportOverlayForCell,
        shouldRenderTransportOverlay;

CellViewData _cell({
  required bool isSea,
  int? roadLevel,
  TileVisibility visibility = TileVisibility.visible,
}) {
  return CellViewData(
    x: 0,
    y: 0,
    regionCellId: 'p0',
    isSea: isSea,
    terrainType: isSea ? null : TerrainType.plains,
    roadLevel: roadLevel,
    visibility: visibility,
  );
}

void main() {
  group('transport overlay render policy', () {
    test('renders only in terrainAndResourcesImprovementsRoads mode', () {
      expect(
        shouldRenderTransportOverlay(
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
        ),
        isFalse,
      );
      expect(
        shouldRenderTransportOverlay(
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
        ),
        isFalse,
      );
      expect(
        shouldRenderTransportOverlay(
          baseLayerDisplayMode:
              BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
        ),
        isFalse,
      );
      expect(
        shouldRenderTransportOverlay(
          baseLayerDisplayMode:
              BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        ),
        isTrue,
      );
    });

    test('uses rail family only for road level 4', () {
      expect(isRailTransportLevel(0), isFalse);
      expect(isRailTransportLevel(1), isFalse);
      expect(isRailTransportLevel(2), isFalse);
      expect(isRailTransportLevel(4), isTrue);
      expect(isRailTransportLevel(5), isFalse);
    });

    test('hides transport for sea and non-transport land cells', () {
      expect(
        shouldPaintTransportOverlayForCell(
          cell: _cell(isSea: true, roadLevel: 2),
          visibilityMode: CtMapVisibilityMode.full,
          tileVisibility: TileVisibility.visible,
        ),
        isFalse,
      );
      expect(
        shouldPaintTransportOverlayForCell(
          cell: _cell(isSea: false, roadLevel: 0),
          visibilityMode: CtMapVisibilityMode.full,
          tileVisibility: TileVisibility.visible,
        ),
        isFalse,
      );
      expect(
        shouldPaintTransportOverlayForCell(
          cell: _cell(isSea: false, roadLevel: 2),
          visibilityMode: CtMapVisibilityMode.full,
          tileVisibility: TileVisibility.visible,
        ),
        isTrue,
      );
    });

    test('hides unrevealed transport in player-constrained mode only', () {
      final landTransport = _cell(isSea: false, roadLevel: 2);
      expect(
        shouldPaintTransportOverlayForCell(
          cell: landTransport,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          tileVisibility: TileVisibility.unrevealed,
        ),
        isFalse,
      );
      expect(
        shouldPaintTransportOverlayForCell(
          cell: landTransport,
          visibilityMode: CtMapVisibilityMode.playerConstrained,
          tileVisibility: TileVisibility.fogged,
        ),
        isTrue,
      );
      expect(
        shouldPaintTransportOverlayForCell(
          cell: landTransport,
          visibilityMode: CtMapVisibilityMode.full,
          tileVisibility: TileVisibility.unrevealed,
        ),
        isTrue,
      );
    });
  });
}
