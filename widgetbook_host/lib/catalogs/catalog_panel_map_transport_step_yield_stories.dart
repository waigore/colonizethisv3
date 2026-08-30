// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 transport-step payoff (Refs #4663).
part of 'catalog.dart';

List<WidgetbookUseCase> get provinceOverlayTransportStepYieldUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — transport step yield raise',
    builder: (context) => _provinceOverlayTransportStepYieldStory(
      kind: TransportStepYieldKind.raise,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — transport step yield road cap',
    builder: (context) => _provinceOverlayTransportStepYieldStory(
      kind: TransportStepYieldKind.roadPathLimit,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — transport step yield town cap',
    builder: (context) => _provinceOverlayTransportStepYieldStory(
      kind: TransportStepYieldKind.townDevelopmentLimit,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — transport step yield disconnected',
    builder: (context) => _provinceOverlayTransportStepYieldStory(
      kind: TransportStepYieldKind.disconnected,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — transport step yield binds capital',
    builder: (context) => _provinceOverlayTransportStepYieldStory(
      kind: TransportStepYieldKind.bindsToCapital,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — transport step yield port on coast',
    builder: (context) => _provinceOverlayTransportStepYieldStory(
      kind: TransportStepYieldKind.portOnCoast,
      useBuildPort: true,
    ),
  ),
];

Widget _provinceOverlayTransportStepYieldStory({
  required TransportStepYieldKind kind,
  bool useBuildPort = false,
}) {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final preview = TransportStepYieldPreview(
    commodityId: kind == TransportStepYieldKind.roadPathLimit
        ? 'timber'
        : (kind == TransportStepYieldKind.portOnCoast ||
                kind == TransportStepYieldKind.bindsToCapital
            ? null
            : 'grain'),
    currentEffective: kind == TransportStepYieldKind.raise ? 0 : 2,
    nextEffective: kind == TransportStepYieldKind.raise ? 1 : 2,
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
        buildRoad: useBuildPort
            ? null
            : (
                showIcon: true,
                enabled: true,
                hasMatchingUnits: true,
              ),
        buildPort: useBuildPort
            ? (
                showIcon: true,
                enabled: true,
                hasMatchingUnits: true,
              )
            : null,
      ),
      tileConnectivity: ProvinceTileConnectivityDisplay(
        capitalConnected: kind != TransportStepYieldKind.disconnected,
        extractionEffective: preview.currentEffective,
        extractionFull: kind == TransportStepYieldKind.raise ? 0 : 2,
        nextBuildRoadYield: useBuildPort ? null : preview,
        nextBuildPortYield: useBuildPort ? preview : null,
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: null,
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: null,
        onBuildRoadTap: useBuildPort ? null : () {},
        onBuildFortTap: null,
        onBuildPortTap: useBuildPort ? () {} : null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
      ),
      onClose: () {},
    ),
  );
}
