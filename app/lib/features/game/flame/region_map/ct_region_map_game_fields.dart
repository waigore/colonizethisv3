import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show visibleForTesting, VoidCallback;
import 'package:flutter/material.dart' show Offset;

import 'ct_region_map_game_state.dart';
import 'region_map_component.dart';
import 'region_map_viewport_snapshot.dart' show RegionMapViewportSnapshot;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

// ignore_for_file: deprecated_member_use

/// Mutable session fields for de-parted [CtRegionMapGame] libraries (Refs #4117).
mixin CtRegionMapGameFields on FlameGame {
  final CtRegionMapGameState state = CtRegionMapGameState();

  late RegionMapViewData region;
  late double cellSizePx;
  late bool showPoliticalOverlay;
  late bool showProvinceOverlay;
  late bool showProvinceOwnershipTint;
  late bool showProvinceNamesLayer;
  bool showCapitalLinkDisconnectedHighlight = true;
  late CtMapVisibilityMode visibilityMode;
  late MapBaseLayerFlags mapBaseLayerFlags;
  late BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  void Function(String tileKey, Offset localPosition)?
  onMapTileSecondaryForRadial;
  bool suppressNextPrimaryTap = false;
  VoidCallback? onRegionViewChanged;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  void Function(String tileKey)? onCivilianTileTapped;
  void Function(
    String locationScopeKey,
    List<String> fleetIds,
    String markerTileKey,
  )?
  onFleetMarkerTapped;
  void Function(ArmyTileMarkerView marker)? onArmyMarkerTapped;
  VoidCallback? onCivilianTileSelectionCleared;
  String? selectedTileKey;
  String? selectedCivilianTileKey;
  String? secondaryHighlightTileKey;
  Set<String>? secondaryHighlightTileKeys;
  Set<String>? validTileKeys;
  String? lastTurnPulseTileKey;
  void Function(String tileKey)? onTileSelected;
  VoidCallback? onWorkTargetSelectionCancelled;
  void Function(String provinceId)? onTownIconTapped;
  PlayerView? playerViewForResources;
  void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged;
  bool showPlayerTerritoryOutline = false;
  Set<String>? playerTerritoryTileKeys;

  @visibleForTesting
  CtRegionMapComponent get debugMapComponentForTest => state.mapComponent;

  double get zoomMultiplier => state.zoomMultiplier;
}
