import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show Player;
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart';

/// Two owned land tiles: left connected, right capital-disconnected (Refs #4370).
RegionMapViewData capitalLinkDisconnectedHighlightRegion({
  TileVisibility disconnectedVisibility = TileVisibility.visible,
}) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 2,
    height: 1,
    cellSize: 64,
    cells: [
      const CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'pConnected',
        isSea: false,
        terrainTypeId: 'plains',
        terrainType: TerrainType.plains,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Connected',
      ),
      CellViewData(
        x: 1,
        y: 0,
        regionCellId: 'pCutOff',
        isSea: false,
        terrainTypeId: 'plains',
        terrainType: TerrainType.plains,
        ownerFactionId: 'gp1',
        provinceDisplayName: 'Cut off',
        capitalLinkDisconnected: true,
        visibility: disconnectedVisibility,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {'gp1': (160, 120, 80)},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

const PlayerView _storyPlayerView = PlayerView(
  playerId: 'gp1',
  player: Player(id: 'gp1', displayName: 'Story', isHuman: true),
  ownUnitsById: {},
  provincesById: {},
  visibilityByTile: {},
  prospectedTiles: {},
  diplomacyByOtherId: {},
);

/// Isolated MAP10001 hatch proof for Widgetbook (Refs #4370).
class CapitalLinkDisconnectedHighlightStory extends StatelessWidget {
  const CapitalLinkDisconnectedHighlightStory({
    super.key,
    this.showHighlight = true,
    this.disconnectedVisibility = TileVisibility.visible,
    this.playerConstrained = false,
    this.narrow = false,
  });

  final bool showHighlight;
  final TileVisibility disconnectedVisibility;
  final bool playerConstrained;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final region = capitalLinkDisconnectedHighlightRegion(
      disconnectedVisibility: disconnectedVisibility,
    );
    final map = SizedBox(
      width: region.width * region.cellSize.toDouble(),
      height: region.height * region.cellSize.toDouble() + 8,
      child: CtRegionMap(
        region: region,
        cellSizePx: region.cellSize.toDouble(),
        visibilityMode: playerConstrained
            ? CtMapVisibilityMode.playerConstrained
            : CtMapVisibilityMode.full,
        playerViewForResources: playerConstrained ? _storyPlayerView : null,
        showPoliticalOverlay: false,
        showProvinceOverlay: false,
        showProvinceNamesLayer: false,
        showCapitalLinkDisconnectedHighlight: showHighlight,
        onProvinceSelected: (_) {},
      ),
    );
    if (!narrow) {
      return map;
    }
    return SizedBox(
      width: kMinViewportWidth,
      height: 120,
      child: ColoredBox(
        color: const Color(0xFF1A1612),
        child: Align(alignment: Alignment.centerLeft, child: map),
      ),
    );
  }
}
