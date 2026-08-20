// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Purchase land overlay stories (Refs #4274).
part of 'catalog.dart';

/// MAP20001 Tile **Purchase land** inline-action use cases. Refs #4274.
List<WidgetbookUseCase> get provinceOverlayPurchaseLandUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — tile Purchase land enabled',
    builder: (context) => _provinceOverlayPurchaseLandStory(
      showIcon: true,
      enabled: true,
      hasMatchingUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Purchase land disabled',
    builder: (context) => _provinceOverlayPurchaseLandStory(
      showIcon: true,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Purchase land hidden',
    builder: (context) => _provinceOverlayPurchaseLandStory(
      showIcon: false,
      enabled: false,
      hasMatchingUnits: false,
    ),
  ),
];

/// MAP20001 Tile **Purchase land** inline-action variants. Refs #4274.
Widget _provinceOverlayPurchaseLandStory({
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
        purchaseLand: (
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
        onBuildRailroadTap: null,
        onPurchaseLandTap: () {},
      ),
      onClose: () {},
    ),
  );
}
