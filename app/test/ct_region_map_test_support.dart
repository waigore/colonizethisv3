import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show AppEventBus, Player;
import 'package:flutter/material.dart';

import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Minimal view for map tests in [CtMapVisibilityMode.playerConstrained].
const ctRegionMapTestPlayerView = PlayerView(
  playerId: 'ct_region_map_test',
  player: Player(id: 'ct_region_map_test', displayName: 'Test', isHuman: false),
  ownUnitsById: {},
  provincesById: {},
  visibilityByTile: {},
  prospectedTiles: {},
  diplomacyByOtherId: {},
);

RegionMapViewData ctRegionMapTestOldWorldRegion() =>
    getDebugInitGameResult().mapViewData.oldWorld;

RegionMapViewData ctRegionMapTestNewWorldRegion() =>
    getDebugInitGameResult().mapViewData.newWorld;

Widget ctRegionMapTestHarness({
  required RegionMapViewData region,
  double width = 400,
  double height = 320,
  double cellSizePx = 24,
  bool showPoliticalOverlay = true,
  bool showProvinceOverlay = true,
  bool showProvinceOwnershipTint = false,
  bool showProvinceNamesLayer = true,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
  BaseLayerDisplayMode? baseLayerDisplayMode,
  String? centerOnTileKey,
  void Function(String)? onProvinceSelected,
  void Function(String?)? onProvinceHovered,
  void Function(String?)? onTileHovered,
  void Function(String)? onMapTileTappedForDetail,
  void Function(String)? onCivilianTileStateChanged,
  VoidCallback? onCivilianTileSelectionCleared,
  String? selectedTileKey,
  String? selectedCivilianTileKey,
  String? secondaryHighlightTileKey,
  VoidCallback? onRegionViewChanged,
  PlayerView? playerViewForResources,
  AppEventBus? bus,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: CtRegionMap(
            region: region,
            cellSizePx: cellSizePx,
            showPoliticalOverlay: showPoliticalOverlay,
            showProvinceOverlay: showProvinceOverlay,
            showProvinceOwnershipTint: showProvinceOwnershipTint,
            showProvinceNamesLayer: showProvinceNamesLayer,
            visibilityMode: visibilityMode,
            playerViewForResources: playerViewForResources,
            baseLayerDisplayMode: baseLayerDisplayMode,
            centerOnTileKey: centerOnTileKey,
            onProvinceSelected: onProvinceSelected,
            onProvinceHovered: onProvinceHovered,
            onTileHovered: onTileHovered,
            onMapTileTappedForDetail: onMapTileTappedForDetail,
            onCivilianTileStateChanged: onCivilianTileStateChanged,
            onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
            selectedTileKey: selectedTileKey,
            selectedCivilianTileKey: selectedCivilianTileKey,
            secondaryHighlightTileKey: secondaryHighlightTileKey,
            onRegionViewChanged: onRegionViewChanged,
            bus: bus,
          ),
        ),
      ),
    ),
  );
}
