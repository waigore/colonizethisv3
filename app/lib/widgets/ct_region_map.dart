import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../core/services/region_map/region_map_widget_bindings.dart';
import 'ct_region_map_state.dart';

/// Flutter wrapper for the region map; renders via Flame. SPEC/ui/map-widget.md.
class CtRegionMap extends StatefulWidget {
  const CtRegionMap({
    super.key,
    required this.region,
    this.showPoliticalOverlay = true,
    this.showProvinceOverlay = true,
    this.showProvinceOwnershipTint = false,
    this.showProvinceNamesLayer = true,
    this.cellSizePx = 32,
    this.visibilityMode = CtMapVisibilityMode.full,
    this.baseLayerDisplayMode,
    this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    this.onRegionViewChanged,
    this.onProvinceHovered,
    this.onTileHovered,
    this.onCivilianTileStateChanged,
    this.onCivilianTileSelectionCleared,
    this.selectedTileKey,
    this.selectedCivilianTileKey,
    this.secondaryHighlightTileKey,
    this.secondaryHighlightTileKeys,
    this.centerOnTileKey,
    this.validTileKeys,
    this.onTileSelected,
    this.onWorkTargetSelectionCancelled,
    this.bus,
    this.playerViewForResources,
    this.onViewportSnapshotChanged,
    this.zoomMultiplier,
    this.showPlayerTerritoryOutline = false,
    this.playerTerritoryTileKeys,
  });

  final RegionMapViewData region;
  final bool showPoliticalOverlay;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;
  final double cellSizePx;
  final CtMapVisibilityMode visibilityMode;

  /// When null, full detail (terrain + resources + improvements + roads) for backward compatibility.
  final BaseLayerDisplayMode? baseLayerDisplayMode;
  final void Function(String provinceId)? onProvinceSelected;
  final void Function(String tileKey)? onMapTileTappedForDetail;
  final VoidCallback? onRegionViewChanged;
  final void Function(String? provinceId)? onProvinceHovered;
  final void Function(String? tileKey)? onTileHovered;
  final void Function(String tileKey)? onCivilianTileStateChanged;
  final VoidCallback? onCivilianTileSelectionCleared;
  final String? selectedTileKey;
  final String? selectedCivilianTileKey;
  final String? secondaryHighlightTileKey;
  final Set<String>? secondaryHighlightTileKeys;
  final String? centerOnTileKey;
  final Set<String>? validTileKeys;
  final void Function(String tileKey)? onTileSelected;
  final VoidCallback? onWorkTargetSelectionCancelled;

  /// Optional event bus for emitting town icon tap events.
  /// When provided, tapping a town/port icon emits OpenProvinceDetailPanelEvent.
  final AppEventBus? bus;

  /// Required when [visibilityMode] is [CtMapVisibilityMode.playerConstrained].
  final PlayerView? playerViewForResources;

  /// Optional: notified when the camera viewport changes (for region minimap sync).
  final void Function(RegionMapViewportSnapshot viewport)?
  onViewportSnapshotChanged;
  final double? zoomMultiplier;
  final bool showPlayerTerritoryOutline;
  final Set<String>? playerTerritoryTileKeys;

  @override
  State<CtRegionMap> createState() => CtRegionMapState();
}
