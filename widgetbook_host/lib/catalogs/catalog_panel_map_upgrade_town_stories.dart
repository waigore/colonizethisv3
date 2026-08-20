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
];

/// MAP20001 Political **Upgrade town** shortcut variants. Refs #4316.
Widget _provinceOverlayUpgradeTownStory({
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required bool upgradeTownHasBuilderUnits,
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
