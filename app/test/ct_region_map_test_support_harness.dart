import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show AppEventBus;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode, RegionMapViewportSnapshot;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;

import 'app_shell_harness.dart';
import 'ct_region_map_test_support_core.dart';

Widget ctRegionMapTestHarness({
  required RegionMapViewData region,
  double width = 400,
  double height = 320,
  double cellSizePx = 24,
  bool showPoliticalOverlay = true,
  bool showProvinceOverlay = true,
  bool showProvinceOwnershipTint = false,
  bool showProvinceNamesLayer = true,
  bool showCapitalLinkDisconnectedHighlight = true,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
  BaseLayerDisplayMode? baseLayerDisplayMode,
  String? centerOnTileKey,
  void Function(String)? onProvinceSelected,
  void Function(String?)? onProvinceHovered,
  void Function(String?)? onTileHovered,
  void Function(String)? onMapTileTappedForDetail,
  void Function(String tileKey, Offset localPosition)?
  onMapTileSecondaryForRadial,
  void Function(String)? onCivilianTileStateChanged,
  VoidCallback? onCivilianTileSelectionCleared,
  String? selectedTileKey,
  String? selectedCivilianTileKey,
  String? secondaryHighlightTileKey,
  Set<String>? secondaryHighlightTileKeys,
  VoidCallback? onRegionViewChanged,
  PlayerView? playerViewForResources,
  AppEventBus? bus,
  Set<String>? validTileKeys,
  String? lastTurnPulseTileKey,
  void Function(String)? onTileSelected,
  VoidCallback? onWorkTargetSelectionCancelled,
  void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged,
  double? zoomMultiplier,

  /// When non-null, replaces the default `Center > SizedBox > CtRegionMap` body
  /// (Refs #4035 — Flame-map suites that need [StatefulBuilder] / custom layout).
  Widget? scaffoldBody,

  /// When set (and [scaffoldBody] is null), wraps the default map host in a
  /// [RepaintBoundary] for `matchesGoldenFile` capture (Refs #4035).
  Key? repaintBoundaryKey,

  /// When false, omit [Scaffold] so golden hosts keep bare
  /// `buildAppShellMaterialApp(home:)` composition (no editorial theme) and
  /// stay pixel-stable (Refs #4035).
  bool useScaffold = true,
}) {
  final Widget mapHost = SizedBox(
    width: width,
    height: height,
    child: CtRegionMap(
      region: region,
      cellSizePx: cellSizePx,
      showPoliticalOverlay: showPoliticalOverlay,
      showProvinceOverlay: showProvinceOverlay,
      showProvinceOwnershipTint: showProvinceOwnershipTint,
      showProvinceNamesLayer: showProvinceNamesLayer,
      showCapitalLinkDisconnectedHighlight:
          showCapitalLinkDisconnectedHighlight,
      visibilityMode: visibilityMode,
      playerViewForResources: playerViewForResources,
      baseLayerDisplayMode: baseLayerDisplayMode,
      centerOnTileKey: centerOnTileKey,
      onProvinceSelected: onProvinceSelected,
      onProvinceHovered: onProvinceHovered,
      onTileHovered: onTileHovered,
      onMapTileTappedForDetail: onMapTileTappedForDetail,
      onMapTileSecondaryForRadial: onMapTileSecondaryForRadial,
      onCivilianTileStateChanged: onCivilianTileStateChanged,
      onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
      selectedTileKey: selectedTileKey,
      selectedCivilianTileKey: selectedCivilianTileKey,
      secondaryHighlightTileKey: secondaryHighlightTileKey,
      secondaryHighlightTileKeys: secondaryHighlightTileKeys,
      onRegionViewChanged: onRegionViewChanged,
      bus: bus,
      validTileKeys: validTileKeys,
      lastTurnPulseTileKey: lastTurnPulseTileKey,
      onTileSelected: onTileSelected,
      onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
      onViewportSnapshotChanged: onViewportSnapshotChanged,
      zoomMultiplier: zoomMultiplier,
    ),
  );
  final Widget body =
      scaffoldBody ??
      Center(
        child: repaintBoundaryKey == null
            ? mapHost
            : RepaintBoundary(key: repaintBoundaryKey, child: mapHost),
      );
  return buildAppShellMaterialApp(
    applyEditorialTheme: false,
    home: useScaffold ? Scaffold(body: body) : body,
  );
}

/// Pumps [ctRegionMapTestHarness] for one frame. Defaults [region] to the OW
/// seed-42 fixture. When [playerConstrained] is true and
/// [playerViewForResources] is null, uses [ctRegionMapTestPlayerView]
/// (Refs #4048 optional near-cap densify).
Future<void> pumpCtRegionMapTest(
  WidgetTester tester, {
  RegionMapViewData? region,
  double width = 400,
  double height = 320,
  double cellSizePx = 24,
  bool showPoliticalOverlay = true,
  bool showProvinceOverlay = true,
  bool showProvinceOwnershipTint = false,
  bool showProvinceNamesLayer = true,
  bool showCapitalLinkDisconnectedHighlight = true,
  CtMapVisibilityMode visibilityMode = CtMapVisibilityMode.full,
  BaseLayerDisplayMode? baseLayerDisplayMode,
  String? centerOnTileKey,
  void Function(String)? onProvinceSelected,
  void Function(String?)? onProvinceHovered,
  void Function(String?)? onTileHovered,
  void Function(String)? onMapTileTappedForDetail,
  void Function(String tileKey, Offset localPosition)?
  onMapTileSecondaryForRadial,
  void Function(String)? onCivilianTileStateChanged,
  VoidCallback? onCivilianTileSelectionCleared,
  String? selectedTileKey,
  String? selectedCivilianTileKey,
  String? secondaryHighlightTileKey,
  Set<String>? secondaryHighlightTileKeys,
  VoidCallback? onRegionViewChanged,
  PlayerView? playerViewForResources,
  bool playerConstrained = false,
  AppEventBus? bus,
  Set<String>? validTileKeys,
  String? lastTurnPulseTileKey,
  void Function(String)? onTileSelected,
  VoidCallback? onWorkTargetSelectionCancelled,
  void Function(RegionMapViewportSnapshot)? onViewportSnapshotChanged,
  double? zoomMultiplier,
  Widget? scaffoldBody,
  Key? repaintBoundaryKey,
  bool useScaffold = true,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: region ?? ctRegionMapTestOldWorldRegion(),
      width: width,
      height: height,
      cellSizePx: cellSizePx,
      showPoliticalOverlay: showPoliticalOverlay,
      showProvinceOverlay: showProvinceOverlay,
      showProvinceOwnershipTint: showProvinceOwnershipTint,
      showProvinceNamesLayer: showProvinceNamesLayer,
      showCapitalLinkDisconnectedHighlight:
          showCapitalLinkDisconnectedHighlight,
      visibilityMode: visibilityMode,
      baseLayerDisplayMode: baseLayerDisplayMode,
      centerOnTileKey: centerOnTileKey,
      onProvinceSelected: onProvinceSelected,
      onProvinceHovered: onProvinceHovered,
      onTileHovered: onTileHovered,
      onMapTileTappedForDetail: onMapTileTappedForDetail,
      onMapTileSecondaryForRadial: onMapTileSecondaryForRadial,
      onCivilianTileStateChanged: onCivilianTileStateChanged,
      onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
      selectedTileKey: selectedTileKey,
      selectedCivilianTileKey: selectedCivilianTileKey,
      secondaryHighlightTileKey: secondaryHighlightTileKey,
      secondaryHighlightTileKeys: secondaryHighlightTileKeys,
      onRegionViewChanged: onRegionViewChanged,
      playerViewForResources:
          playerViewForResources ??
          (playerConstrained ? ctRegionMapTestPlayerView : null),
      bus: bus,
      validTileKeys: validTileKeys,
      lastTurnPulseTileKey: lastTurnPulseTileKey,
      onTileSelected: onTileSelected,
      onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
      onViewportSnapshotChanged: onViewportSnapshotChanged,
      zoomMultiplier: zoomMultiplier,
      scaffoldBody: scaffoldBody,
      repaintBoundaryKey: repaintBoundaryKey,
      useScaffold: useScaffold,
    ),
  );
  await tester.pump();
}
