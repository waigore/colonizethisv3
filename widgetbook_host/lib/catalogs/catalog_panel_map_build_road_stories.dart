// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build road overlay stories (Refs #4260).
part of 'catalog.dart';

/// MAP20001 Tile **Build road** inline-action use cases. Refs #4260.
List<WidgetbookUseCase> get provinceOverlayBuildRoadUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — tile Build road enabled',
    builder: (context) => _provinceOverlayBuildRoadStory(
      showIcon: true,
      enabled: true,
      hasMatchingUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build road disabled',
    builder: (context) => _provinceOverlayBuildRoadStory(
      showIcon: true,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build road hidden',
    builder: (context) => _provinceOverlayBuildRoadStory(
      showIcon: false,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
];

/// MAP20001 Tile **Build road** inline-action variants. Refs #4260.
Widget _provinceOverlayBuildRoadStory({
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
        buildRoad: (
          showIcon: showIcon,
          enabled: enabled,
          hasMatchingUnits: hasMatchingUnits,
        ),
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: null,
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: null,
        onBuildRoadTap: () {},
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}
