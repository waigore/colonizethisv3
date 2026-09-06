// RegionMapViewData fixtures for province shortcut host-emit and golden suites.
// Refs #4450 Slice C; map/topology fixtures in province_shortcut_host_emit_map_fixtures.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'province_shortcut_host_emit_map_fixtures.dart';

export 'province_shortcut_host_emit_map_fixtures.dart';

RegionMapViewData provinceShortcutHostRegionView({
  String ownerFactionId = kProvinceShortcutHostHumanPlayerId,
  String provinceDisplayName = 'Test Province',
  String greatPowerId = kProvinceShortcutHostHumanPlayerId,
}) => RegionMapViewData(
  regionId: 'oldWorld',
  width: 1,
  height: 1,
  cellSize: 16,
  cells: [
    CellViewData(
      x: 0,
      y: 0,
      regionCellId: kProvinceShortcutHostOldWorldLocalProvinceId,
      isSea: false,
      terrainType: TerrainType.plains,
      resourceId: 'grain',
      ownerFactionId: ownerFactionId,
      provinceDisplayName: provinceDisplayName,
      visibility: TileVisibility.visible,
    ),
  ],
  capitalMarkers: const [],
  portMarkers: const [],
  factionColors: const {},
  greatPowerFactionIds: {greatPowerId},
  terrainColors: const {},
  provincePoliticalOwnerByPrefixedProvinceId: {
    kProvinceShortcutHostOldWorldProvinceId: ownerFactionId,
  },
);

RegionMapViewData provinceShortcutHostTwoTileRegionView({
  String ownerFactionId = kProvinceShortcutHostHumanPlayerId,
  String provinceDisplayName = 'Home',
}) => RegionMapViewData(
  regionId: 'oldWorld',
  width: 2,
  height: 1,
  cellSize: 16,
  cells: [
    CellViewData(
      x: 0,
      y: 0,
      regionCellId: kProvinceShortcutHostOldWorldLocalProvinceId,
      isSea: false,
      terrainType: TerrainType.plains,
      resourceId: 'grain',
      ownerFactionId: ownerFactionId,
      provinceDisplayName: provinceDisplayName,
      visibility: TileVisibility.visible,
    ),
    CellViewData(
      x: 1,
      y: 0,
      regionCellId: kProvinceShortcutHostOldWorldLocalProvinceId,
      isSea: false,
      terrainType: TerrainType.plains,
      resourceId: 'grain',
      ownerFactionId: ownerFactionId,
      provinceDisplayName: provinceDisplayName,
      visibility: TileVisibility.visible,
    ),
  ],
  capitalMarkers: const [],
  portMarkers: const [],
  factionColors: const {},
  greatPowerFactionIds: {kProvinceShortcutHostHumanPlayerId},
  terrainColors: const {},
  provincePoliticalOwnerByPrefixedProvinceId: {
    kProvinceShortcutHostOldWorldProvinceId: ownerFactionId,
  },
);
