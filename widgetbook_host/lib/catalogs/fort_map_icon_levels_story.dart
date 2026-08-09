import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart';

/// Synthetic map with three town tiles showing fort glyphs L1–L3. Refs #4280.
RegionMapViewData fortMapIconLevelsRegion() {
  const cells = <CellViewData>[
    CellViewData(
      x: 0,
      y: 0,
      regionCellId: 'p1',
      isSea: false,
      ownerFactionId: 'gp1',
      provinceDisplayName: 'Wood fort',
    ),
    CellViewData(
      x: 1,
      y: 0,
      regionCellId: 'p2',
      isSea: false,
      ownerFactionId: 'gp1',
      provinceDisplayName: 'Stone fort',
    ),
    CellViewData(
      x: 2,
      y: 0,
      regionCellId: 'p3',
      isSea: false,
      ownerFactionId: 'gp1',
      provinceDisplayName: 'Modern fort',
    ),
  ];
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 3,
    height: 1,
    cellSize: 64,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {'gp1': (160, 120, 80)},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
    townMarkers: const [
      TownMarkerView(
        x: 0,
        y: 0,
        provinceId: 'p1',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 2,
        townIconStyle: 'euro',
        worldFortLevel: 1,
        mapVisibleFortLevel: 1,
      ),
      TownMarkerView(
        x: 1,
        y: 0,
        provinceId: 'p2',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 2,
        townIconStyle: 'euro',
        worldFortLevel: 2,
        mapVisibleFortLevel: 2,
      ),
      TownMarkerView(
        x: 2,
        y: 0,
        provinceId: 'p3',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 2,
        townIconStyle: 'euro',
        worldFortLevel: 3,
        mapVisibleFortLevel: 3,
      ),
    ],
  );
}

/// Widgetbook story: three fort glyphs beside town icons (wood / stone / modern).
class FortMapIconLevelsStory extends StatelessWidget {
  const FortMapIconLevelsStory({super.key});

  @override
  Widget build(BuildContext context) {
    final region = fortMapIconLevelsRegion();
    return SizedBox(
      width: region.width * region.cellSize.toDouble(),
      height: region.height * region.cellSize.toDouble() + 8,
      child: CtRegionMap(
        region: region,
        cellSizePx: region.cellSize.toDouble(),
        visibilityMode: CtMapVisibilityMode.full,
        showPoliticalOverlay: false,
        showProvinceNamesLayer: false,
        onProvinceSelected: (_) {},
      ),
    );
  }
}
