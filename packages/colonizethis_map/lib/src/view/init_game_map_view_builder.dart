/// Builder for InitGameMapViewData from game + tile maps + topology.
/// SPEC/program/map-visualization.md § Map view model for tools.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../combine_region_topologies.dart';
import '../region_constants.dart';
import 'init_game_map_view_builder_assembly.dart';
import 'init_game_map_view_data.dart';

final _log = packageLogger();

InitGameMapViewData buildInitGameMapViewData({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required int cellSize,
  int? seed,
  String? configSummary,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,

  /// Optional per-tile visibility for the current player view, keyed by tile
  /// key `regionId|provinceId|x|y`. When omitted, all tiles are treated as
  /// [TileVisibility.visible] in the view data.
  Map<String, TileVisibility>? visibilityByTile,

  /// Optional warp links for rendering warp zone indicators.
  List<WarpLink>? warpLinks,

  /// Optional per-tile extraction units for map overlays, keyed by tile key
  /// `regionId|provinceId|x|y`.
  Map<String, int>? resourceExtractionUnitsByTile,

  /// Optional per-tile effective transported extraction units for map overlays.
  Map<String, int>? resourceExtractionEffectiveUnitsByTile,

  /// Optional per-tile transport-blocked extraction units for map overlays.
  Map<String, int>? resourceExtractionBlockedUnitsByTile,

  /// Optional explicit owner set for civilian tile markers. When null, the
  /// builder falls back to `Player.isHuman` players (legacy single-player
  /// behavior). When provided, only civilians owned by ids in this set get
  /// markers; pass all faction ids in global observe and the observed GP id in
  /// player observe per SPEC/ui/observe-mode.md.
  Set<String>? civilianMarkerOwnerIds,
}) {
  _log.i('buildInitGameMapViewData start gameId=${game.id}');
  final viewByRegion = <String, RegionMapViewData>{};
  for (final regionId in const [kRegionOldWorld, kRegionNewWorld]) {
    viewByRegion[regionId] = buildRegionViewData(
      regionId: regionId,
      tileMap: tileMapByRegion[regionId]!,
      topology: topologyByRegion[regionId]!,
      game: game,
      cellSize: cellSize,
      greatPowerColorOverride: greatPowerColorOverride,
      visibilityByTile: visibilityByTile,
      warpLinks: warpLinks,
      resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
      resourceExtractionEffectiveUnitsByTile:
          resourceExtractionEffectiveUnitsByTile,
      resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
      civilianMarkerOwnerIds: civilianMarkerOwnerIds,
    );
  }

  _log.i('buildInitGameMapViewData end');
  final combinedTopology = combineRegionTopologies(
    topologyByRegion: topologyByRegion,
    warpLinks: warpLinks ?? const [],
  );
  return InitGameMapViewData(
    oldWorld: viewByRegion[kRegionOldWorld]!,
    newWorld: viewByRegion[kRegionNewWorld]!,
    combinedTopology: combinedTopology,
    seed: seed,
    configSummary: configSummary,
  );
}

/// Builds [RegionMapViewData] for one region without assembling the full
/// dual-region [InitGameMapViewData] (lighter path for panel minimaps).
RegionMapViewData buildInitGameMapRegionViewData({
  required String regionId,
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required int cellSize,
  Map<String, TileVisibility>? visibilityByTile,
}) {
  return buildRegionViewData(
    regionId: regionId,
    tileMap: tileMapByRegion[regionId]!,
    topology: topologyByRegion[regionId]!,
    game: game,
    cellSize: cellSize,
    visibilityByTile: visibilityByTile,
  );
}
