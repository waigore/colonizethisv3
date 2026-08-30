// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build fort overlay stories (Refs #4280).
part of 'catalog.dart';

/// MAP20001 Military **Build fort** inline-action use cases. Refs #4280, #4668.
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
  WidgetbookUseCase(
    name: 'Standalone — Build fort payoff open to wood',
    builder: (context) => _provinceOverlayBuildFortPayoffStory(fortLevel: 0),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Build fort payoff wood to stone',
    builder: (context) => _provinceOverlayBuildFortPayoffStory(fortLevel: 1),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Build fort payoff stone to modern',
    builder: (context) => _provinceOverlayBuildFortPayoffStory(fortLevel: 2),
  ),
];

/// MAP20001 Military **Build fort** inline-action variants. Refs #4280, #4668.
Widget _provinceOverlayBuildFortStory({
  required bool showIcon,
  required bool enabled,
  required bool hasMatchingUnits,
  Game? game,
}) {
  final overlayGame = game ?? demoGameForOverlay;
  final region = demoRegionForOverlay;
  return SizedBox(
    width: 640,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: overlayGame,
      region: region,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: overlayGame.players.first.id,
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

Widget _provinceOverlayBuildFortPayoffStory({required int fortLevel}) {
  final base = demoGameForOverlay;
  final oldWorld = base.worldState.oldWorld;
  final provinces = [
    for (final p in oldWorld.provinces)
      p.id == sampleProvinceIdForOverlay
          ? p.copyWith(fortLevel: fortLevel)
          : p,
  ];
  final game = base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: RegionData(provinces: provinces, units: oldWorld.units),
    ),
  );
  return _provinceOverlayBuildFortStory(
    showIcon: true,
    enabled: true,
    hasMatchingUnits: true,
    game: game,
  );
}
