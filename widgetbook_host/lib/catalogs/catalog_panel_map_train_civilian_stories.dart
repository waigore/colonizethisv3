// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Train {type} overlay stories (Refs #4752).
part of 'catalog.dart';

/// MAP20001 Tile **Train Explorer** variants. Refs #4752.
List<WidgetbookUseCase> get provinceOverlayTrainCivilianUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Train Explorer missing-unit',
    builder: (context) => _provinceOverlayTrainExplorerStory(
      showIcon: true,
      enabled: false,
      hasMatchingUnits: false,
      offerTrain: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Train Explorer units exist',
    builder: (context) => _provinceOverlayTrainExplorerStory(
      showIcon: true,
      enabled: true,
      hasMatchingUnits: true,
      offerTrain: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Train Explorer Consulate omit',
    builder: (context) => _provinceOverlayTrainExplorerStory(
      showIcon: true,
      enabled: false,
      hasMatchingUnits: false,
      offerTrain: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Train Explorer 320 dp',
    builder: (context) => SizedBox(
      width: 320,
      child: _provinceOverlayTrainExplorerStory(
        showIcon: true,
        enabled: false,
        hasMatchingUnits: false,
        offerTrain: true,
      ),
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Train Builder Upgrade town missing-unit',
    builder: (context) => _provinceOverlayTrainBuilderUpgradeTownStory(),
  ),
];

Widget _provinceOverlayTrainExplorerStory({
  required bool showIcon,
  required bool enabled,
  required bool hasMatchingUnits,
  required bool offerTrain,
}) {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  return SizedBox(
    width: 400,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      civilianInlineActions: provinceOverlayInlineActions(
        explore: (
          showIcon: showIcon,
          enabled: enabled,
          hasMatchingUnits: hasMatchingUnits,
        ),
      ),
      inlineActionCallbacks: (
        onExploreWithExplorerTap: enabled ? () {} : null,
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: null,
        onBuildRoadTap: null,
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
        onTrainCivilianTap: offerTrain ? () {} : null,
      ),
      onClose: () {},
    ),
  );
}

Game _trainBuilderBureaucracyGame() {
  final base = demoGameForOverlay;
  final human = base.players.first;
  return base.copyWith(
    players: [
      human.copyWith(
        techUnlocked: {
          ...?human.techUnlocked,
          kTechIdNationalBureaucracy: true,
        },
      ),
      ...base.players.skip(1),
    ],
  );
}

Widget _provinceOverlayTrainBuilderUpgradeTownStory() {
  final game = _trainBuilderBureaucracyGame();
  return SizedBox(
    width: 400,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      showUpgradeTownControl: true,
      upgradeTownHasBuilderUnits: false,
      upgradeTownTargetTileKey: sampleTileKeyForProvinceOverlay,
      inlineActionCallbacks: (
        onExploreWithExplorerTap: null,
        onProspectWithExplorerTap: null,
        onBuildImprovementTap: null,
        onBuildRoadTap: null,
        onBuildFortTap: null,
        onBuildPortTap: null,
        onBuildRailroadTap: null,
        onPurchaseLandTap: null,
        onTrainCivilianTap: () {},
      ),
      onClose: () {},
    ),
  );
}
