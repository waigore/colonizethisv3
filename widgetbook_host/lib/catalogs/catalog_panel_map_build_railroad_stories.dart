// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build railroad overlay stories (Refs #4383).
part of 'catalog.dart';

/// MAP20001 Tile **Build railroad** inline-action use cases. Refs #4383.
List<WidgetbookUseCase> get provinceOverlayBuildRailroadUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — tile Build railroad enabled',
    builder: (context) => _provinceOverlayBuildRailroadStory(
      showIcon: true,
      enabled: true,
      hasMatchingUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build railroad disabled',
    builder: (context) => _provinceOverlayBuildRailroadStory(
      showIcon: true,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build railroad hidden',
    builder: (context) => _provinceOverlayBuildRailroadStory(
      showIcon: false,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
];

/// MAP20001 Tile **Build railroad** inline-action variants. Refs #4383.
Widget _provinceOverlayBuildRailroadStory({
  required bool showIcon,
  required bool enabled,
  required bool hasMatchingUnits,
}) {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  return SizedBox(
    width: 640,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      civilianInlineActions: provinceOverlayInlineActions(
        buildRail: (
          showIcon: showIcon,
          enabled: enabled,
          hasMatchingUnits: hasMatchingUnits,
        ),
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: null,
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: null,
        onBuildRoadTap: null,
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: () {},
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}
