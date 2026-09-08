// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Upgrade town overlay stories (Refs #4316).
part of 'catalog.dart';

/// MAP20001 Political **Upgrade town** shortcut use cases. Refs #4316.
List<WidgetbookUseCase> get provinceOverlayUpgradeTownUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political Upgrade town enabled',
    builder: (context) => _provinceOverlayUpgradeTownStory(
      showUpgradeTownControl: true,
      upgradeTownEnabled: true,
      upgradeTownHasBuilderUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Upgrade town disabled',
    builder: (context) => _provinceOverlayUpgradeTownStory(
      showUpgradeTownControl: true,
      upgradeTownEnabled: false,
      upgradeTownHasBuilderUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Upgrade town hidden',
    builder: (context) => _provinceOverlayUpgradeTownStory(
      showUpgradeTownControl: false,
      upgradeTownEnabled: false,
      upgradeTownHasBuilderUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Upgrade town payoff start',
    builder: (context) => _provinceOverlayUpgradeTownPayoffStory(townLevel: 1),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Upgrade town payoff pause until 4',
    builder: (context) => _provinceOverlayUpgradeTownPayoffStory(townLevel: 2),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Upgrade town payoff 320 dp',
    builder: (context) => SizedBox(
      width: 320,
      child: _provinceOverlayUpgradeTownPayoffStory(townLevel: 2),
    ),
  ),
];

/// MAP20001 Political **Upgrade town** shortcut variants. Refs #4316.
Widget _provinceOverlayUpgradeTownStory({
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required bool upgradeTownHasBuilderUnits,
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
      showUpgradeTownControl: showUpgradeTownControl,
      upgradeTownEnabled: upgradeTownEnabled,
      upgradeTownHasBuilderUnits: upgradeTownHasBuilderUnits,
      upgradeTownTargetTileKey: showUpgradeTownControl
          ? sampleTileKeyForProvinceOverlay
          : null,
      onUpgradeTownTap: () {},
      onClose: () {},
    ),
  );
}

Widget _provinceOverlayUpgradeTownPayoffStory({required int townLevel}) {
  final base = demoGameForOverlay;
  final oldWorld = base.worldState.oldWorld;
  final provinces = [
    for (final p in oldWorld.provinces)
      p.id == sampleProvinceIdForOverlay
          ? p.copyWith(townDevelopmentLevel: townLevel)
          : p,
  ];
  final game = base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: RegionData(provinces: provinces, units: oldWorld.units),
    ),
  );
  return _provinceOverlayUpgradeTownStory(
    showUpgradeTownControl: true,
    upgradeTownEnabled: true,
    upgradeTownHasBuilderUnits: true,
    game: game,
  );
}
