// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build improvement next-yield (Refs #4627).
part of 'catalog.dart';

List<WidgetbookUseCase> get provinceOverlayBuildImprovementYieldUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Build improvement next yield raise',
    builder: (context) => _provinceOverlayBuildImprovementYieldStory(
      kind: BuildImprovementYieldKind.raise,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Build improvement next yield road cap',
    builder: (context) => _provinceOverlayBuildImprovementYieldStory(
      kind: BuildImprovementYieldKind.roadPathLimit,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Build improvement next yield town cap',
    builder: (context) => _provinceOverlayBuildImprovementYieldStory(
      kind: BuildImprovementYieldKind.townDevelopmentLimit,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Build improvement next yield disconnected',
    builder: (context) => _provinceOverlayBuildImprovementYieldStory(
      kind: BuildImprovementYieldKind.disconnected,
    ),
  ),
];

Widget _provinceOverlayBuildImprovementYieldStory({
  required BuildImprovementYieldKind kind,
}) {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final preview = BuildImprovementYieldPreview(
    commodityId: kind == BuildImprovementYieldKind.roadPathLimit
        ? 'timber'
        : 'grain',
    currentEffective: kind == BuildImprovementYieldKind.raise ? 0 : 2,
    nextEffective: kind == BuildImprovementYieldKind.raise ? 1 : 2,
    kind: kind,
  );
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
        buildImprovement: (
          showIcon: true,
          enabled: true,
          hasMatchingUnits: true,
        ),
      ),
      tileConnectivity: ProvinceTileConnectivityDisplay(
        capitalConnected: kind != BuildImprovementYieldKind.disconnected,
        extractionEffective: preview.currentEffective,
        extractionFull: kind == BuildImprovementYieldKind.raise ? 0 : 2,
        nextImproveYield: preview,
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: null,
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: () {},
        onBuildRoadTap: null,
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}
