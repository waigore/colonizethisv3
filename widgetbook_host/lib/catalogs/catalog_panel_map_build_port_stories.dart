// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build port overlay stories (Refs #4332).
part of 'catalog.dart';

/// MAP20001 Tile **Build port** inline-action use cases. Refs #4332.
List<WidgetbookUseCase> get provinceOverlayBuildPortUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — tile Build port enabled',
    builder: (context) => _provinceOverlayBuildPortStory(
      showBuildPortActionIcon: true,
      buildPortActionEnabled: true,
      buildPortActionHasEngineerUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build port disabled',
    builder: (context) => _provinceOverlayBuildPortStory(
      showBuildPortActionIcon: true,
      buildPortActionEnabled: false,
      buildPortActionHasEngineerUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build port hidden',
    builder: (context) => _provinceOverlayBuildPortStory(
      showBuildPortActionIcon: false,
      buildPortActionEnabled: false,
      buildPortActionHasEngineerUnits: false,
    ),
  ),
];

/// MAP20001 Tile **Build port** inline-action variants. Refs #4332.
Widget _provinceOverlayBuildPortStory({
  required bool showBuildPortActionIcon,
  required bool buildPortActionEnabled,
  required bool buildPortActionHasEngineerUnits,
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
      showBuildPortActionIcon: showBuildPortActionIcon,
      buildPortActionEnabled: buildPortActionEnabled,
      buildPortActionHasEngineerUnits: buildPortActionHasEngineerUnits,
      onBuildPortTap: () {},
      onClose: () {},
    ),
  );
}
