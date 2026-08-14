import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart';

/// Isolated MAP10001 army stack-marker states (Refs #4384).
enum ArmyTileMarkerStoryKind {
  defaultField,
  stacked,
  grayscale,
  homeOnly,
  emptyHome,
  mixedHomePlusField,
}

/// Widgetbook use-case names. SPEC/ui/map-widget.md § Widgetbook debug mode.
abstract final class ArmyTileMarkerStoryNames {
  static const defaultField = 'Army stack marker — default field army';
  static const stacked = 'Army stack marker — stacked field armies';
  static const grayscale = 'Army stack marker — grayscale pending move';
  static const homeOnly = 'Army stack marker — Home Army only';
  static const emptyHome = 'Army stack marker — empty Home Army';
  static const mixedHomePlusField = 'Army stack marker — mixed Home plus field';

  static const all = <String>[
    defaultField,
    stacked,
    grayscale,
    homeOnly,
    emptyHome,
    mixedHomePlusField,
  ];
}

/// Catalog registration pairs for the **Map Widget** folder.
const armyTileMarkerCatalogEntries = <(String, ArmyTileMarkerStoryKind)>[
  (ArmyTileMarkerStoryNames.defaultField, ArmyTileMarkerStoryKind.defaultField),
  (ArmyTileMarkerStoryNames.stacked, ArmyTileMarkerStoryKind.stacked),
  (ArmyTileMarkerStoryNames.grayscale, ArmyTileMarkerStoryKind.grayscale),
  (ArmyTileMarkerStoryNames.homeOnly, ArmyTileMarkerStoryKind.homeOnly),
  (ArmyTileMarkerStoryNames.emptyHome, ArmyTileMarkerStoryKind.emptyHome),
  (
    ArmyTileMarkerStoryNames.mixedHomePlusField,
    ArmyTileMarkerStoryKind.mixedHomePlusField,
  ),
];

/// One town cell with a human army stack marker (Refs #4384).
RegionMapViewData armyTileMarkerRegion(ArmyTileMarkerStoryKind kind) {
  final (armyIds, fieldArmyIds, hasHomeArmy, grayscale) = switch (kind) {
    ArmyTileMarkerStoryKind.defaultField => (
      const ['army_field'],
      const ['army_field'],
      false,
      false,
    ),
    ArmyTileMarkerStoryKind.stacked => (
      const ['army_a', 'army_b', 'army_c'],
      const ['army_a', 'army_b', 'army_c'],
      false,
      false,
    ),
    ArmyTileMarkerStoryKind.grayscale => (
      const ['army_field'],
      const ['army_field'],
      false,
      true,
    ),
    ArmyTileMarkerStoryKind.homeOnly || ArmyTileMarkerStoryKind.emptyHome => (
      const ['army_home'],
      const <String>[],
      true,
      false,
    ),
    ArmyTileMarkerStoryKind.mixedHomePlusField => (
      const ['army_field', 'army_home'],
      const ['army_field'],
      true,
      false,
    ),
  };
  final showCapital =
      kind == ArmyTileMarkerStoryKind.homeOnly ||
      kind == ArmyTileMarkerStoryKind.emptyHome ||
      kind == ArmyTileMarkerStoryKind.mixedHomePlusField;
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 64,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'pArmy',
        isSea: false,
        terrainTypeId: 'plains',
        terrainType: TerrainType.plains,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Army Town',
      ),
    ],
    capitalMarkers: [
      if (showCapital)
        const CapitalMarkerView(
          factionId: 'gp1',
          displayName: 'Army Town',
          x: 0,
          y: 0,
        ),
    ],
    portMarkers: const [],
    factionColors: const {'gp1': (160, 120, 80)},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
    townMarkers: const [
      TownMarkerView(
        x: 0,
        y: 0,
        provinceId: 'pArmy',
        isCoastal: false,
        isPort: false,
        touchesSea: false,
        townDevelopmentLevel: 2,
        townIconStyle: 'euro',
      ),
    ],
    armyTileMarkers: [
      ArmyTileMarkerView(
        tileKey: 'oldWorld|pArmy|0|0',
        x: 0,
        y: 0,
        provinceId: 'oldWorld|pArmy',
        armyIds: armyIds,
        fieldArmyIds: fieldArmyIds,
        stackCount: armyIds.length,
        hasHomeArmy: hasHomeArmy,
        renderGrayscale: grayscale,
      ),
    ],
  );
}

/// Widgetbook / golden host for one army stack-marker state.
class ArmyTileMarkerStory extends StatelessWidget {
  const ArmyTileMarkerStory({super.key, required this.kind});

  final ArmyTileMarkerStoryKind kind;

  @override
  Widget build(BuildContext context) {
    final region = armyTileMarkerRegion(kind);
    return SizedBox(
      width: region.width * region.cellSize.toDouble(),
      height: region.height * region.cellSize.toDouble() + 8,
      child: CtRegionMap(
        region: region,
        cellSizePx: region.cellSize.toDouble(),
        visibilityMode: CtMapVisibilityMode.full,
        showPoliticalOverlay: false,
        showProvinceOverlay: false,
        showProvinceNamesLayer: false,
        onProvinceSelected: (_) {},
      ),
    );
  }
}
