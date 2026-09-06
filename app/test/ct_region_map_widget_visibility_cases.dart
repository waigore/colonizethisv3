import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show
        CtMapVisibilityMode,
        isCellUnderFleetRevealHalo,
        visibilityForTerrainForMapCell;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeExplorer;
import 'package:flutter_test/flutter_test.dart';

void registerCtRegionMapVisibilityHelperTests() {
  group('CtRegionMap visibility helpers (#1756)', () {
    test(
      'visibilityForTerrainForMapCell leaves cell visibility in full map mode',
      () {
        const cell = CellViewData(
          x: 1,
          y: 2,
          regionCellId: 's1',
          isSea: true,
          visibility: TileVisibility.unrevealed,
        );
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.full,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: const [],
          ),
          TileVisibility.unrevealed,
        );
      },
    );

    test(
      'visibilityForTerrainForMapCell keeps unrevealed sea centroid hidden when constrained and no halo',
      () {
        const cell = CellViewData(
          x: 1,
          y: 0,
          regionCellId: 'sz',
          isSea: true,
          visibility: TileVisibility.unrevealed,
        );
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: const [],
          ),
          TileVisibility.unrevealed,
        );
      },
    );

    test(
      'visibilityForTerrainForMapCell reveals unrevealed centroid under fleet move-draft halo',
      () {
        const cell = CellViewData(
          x: 1,
          y: 0,
          regionCellId: 'sz',
          isSea: true,
          visibility: TileVisibility.unrevealed,
        );
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: [
              FleetTileMarkerView(
                tileKey: 'oldWorld|sz|1|0',
                x: 1,
                y: 0,
                locationScopeKey: 'sea:oldWorld|sz',
                fleetIds: const ['f1'],
                stackCount: 1,
                applyFleetRevealHalo: true,
              ),
            ],
            civilianTileMarkers: const [],
          ),
          TileVisibility.visible,
        );
      },
    );

    test(
      'visibilityForTerrainForMapCell reveals unrevealed tile under civilian assignment halo',
      () {
        const cell = CellViewData(
          x: 4,
          y: 2,
          regionCellId: 'p1',
          isSea: false,
          visibility: TileVisibility.fogged,
        );
        expect(
          visibilityForTerrainForMapCell(
            visibilityMode: CtMapVisibilityMode.playerConstrained,
            cell: cell,
            fleetTileMarkers: const [],
            civilianTileMarkers: [
              CivilianTileMarkerView(
                tileKey: 'oldWorld|p1|4|2',
                x: 4,
                y: 2,
                localProvinceId: 'p1',
                unitIds: const ['u1'],
                unitTypes: const {'u1': kUnitTypeExplorer},
                representativeUnitType: kUnitTypeExplorer,
                stackCount: 1,
                applyCivilianRevealHalo: true,
              ),
            ],
          ),
          TileVisibility.visible,
        );
      },
    );

    test(
      'isCellUnderFleetRevealHalo ignores markers without applyFleetRevealHalo',
      () {
        expect(
          isCellUnderFleetRevealHalo(
            x: 1,
            y: 0,
            fleetTileMarkers: [
              FleetTileMarkerView(
                tileKey: 'k',
                x: 1,
                y: 0,
                locationScopeKey: 'sea:x',
                fleetIds: const ['f1'],
                stackCount: 1,
                applyFleetRevealHalo: false,
              ),
            ],
          ),
          isFalse,
        );
      },
    );
  });
}
