import 'package:colonizethis_data/colonizethis_data.dart' show TerrainType;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show Player;
import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart';

/// One-cell MAP10001 improvement-mark proof (Refs #4408).
RegionMapViewData improvementHeadroomMarkRegion({
  required int improvementLevel,
  int? improvementTechCap,
  String? resourceId = 'grain',
  String ownerFactionId = 'gp1',
  TileVisibility visibility = TileVisibility.visible,
}) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 64,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        terrainTypeId: 'plains',
        terrainType: TerrainType.plains,
        resourceId: resourceId,
        ownerFactionId: ownerFactionId,
        provinceDisplayName: 'Wessex',
        improvementLevel: improvementLevel,
        improvementTechCap: improvementTechCap,
        visibility: visibility,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {'gp1': (160, 120, 80), 'gp2': (80, 120, 160)},
    greatPowerFactionIds: const {'gp1', 'gp2'},
    terrainColors: const {},
  );
}

const PlayerView improvementHeadroomHiddenMineralView = PlayerView(
  playerId: 'gp1',
  player: Player(id: 'gp1', displayName: 'Story', isHuman: true),
  ownUnitsById: {},
  provincesById: {},
  visibilityByTile: {'oldWorld|p1|0|0': VisibilityLevel.fullyVisible},
  prospectedTiles: {},
  diplomacyByOtherId: {},
);

/// Isolated MAP10001 improvement-mark proof for Widgetbook (Refs #4408).
class ImprovementHeadroomMarkStory extends StatelessWidget {
  const ImprovementHeadroomMarkStory({
    super.key,
    required this.region,
    this.playerConstrained = false,
    this.showImprovements = true,
    this.narrow = false,
    this.playerView,
  });

  final RegionMapViewData region;
  final bool playerConstrained;
  final bool showImprovements;
  final bool narrow;
  final PlayerView? playerView;

  @override
  Widget build(BuildContext context) {
    final map = SizedBox(
      width: region.width * region.cellSize.toDouble(),
      height: region.height * region.cellSize.toDouble() + 8,
      child: CtRegionMap(
        region: region,
        cellSizePx: region.cellSize.toDouble(),
        visibilityMode: playerConstrained
            ? CtMapVisibilityMode.playerConstrained
            : CtMapVisibilityMode.full,
        playerViewForResources: playerConstrained
            ? (playerView ?? improvementHeadroomHiddenMineralView)
            : null,
        showPoliticalOverlay: false,
        showProvinceOverlay: false,
        showProvinceNamesLayer: false,
        showCapitalLinkDisconnectedHighlight: false,
        baseLayerDisplayMode: showImprovements
            ? BaseLayerDisplayMode.terrainAndResourcesImprovementLabels
            : BaseLayerDisplayMode.terrainAndResources,
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
