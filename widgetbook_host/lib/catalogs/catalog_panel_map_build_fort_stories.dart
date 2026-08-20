// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build fort overlay stories (Refs #4280).
part of 'catalog.dart';

/// MAP20001 Military **Build fort** inline-action use cases. Refs #4280.
List<WidgetbookUseCase> get provinceOverlayBuildFortUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — tile Build fort enabled',
    builder: (context) => _provinceOverlayBuildFortStory(
      showIcon: true,
      enabled: true,
      hasMatchingUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build fort disabled',
    builder: (context) => _provinceOverlayBuildFortStory(
      showIcon: true,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build fort hidden',
    builder: (context) => _provinceOverlayBuildFortStory(
      showIcon: false,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
];

/// MAP20001 Military **Build fort** inline-action variants. Refs #4280.
Widget _provinceOverlayBuildFortStory({
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
        buildFort: (
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
        onBuildFortTap: () {},
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}
