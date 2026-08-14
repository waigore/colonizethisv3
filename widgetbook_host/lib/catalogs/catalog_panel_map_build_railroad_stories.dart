// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Build railroad overlay stories (Refs #4383).
part of 'catalog.dart';

/// MAP20001 Tile **Build railroad** inline-action use cases. Refs #4383.
List<WidgetbookUseCase> get provinceOverlayBuildRailroadUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — tile Build railroad enabled',
    builder: (context) => _provinceOverlayBuildRailroadStory(
      showBuildRailroadActionIcon: true,
      buildRailroadActionEnabled: true,
      buildRailroadActionHasRailBuilderUnits: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build railroad disabled',
    builder: (context) => _provinceOverlayBuildRailroadStory(
      showBuildRailroadActionIcon: true,
      buildRailroadActionEnabled: false,
      buildRailroadActionHasRailBuilderUnits: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — tile Build railroad hidden',
    builder: (context) => _provinceOverlayBuildRailroadStory(
      showBuildRailroadActionIcon: false,
      buildRailroadActionEnabled: false,
      buildRailroadActionHasRailBuilderUnits: false,
    ),
  ),
];

/// MAP20001 Tile **Build railroad** inline-action variants. Refs #4383.
Widget _provinceOverlayBuildRailroadStory({
  required bool showBuildRailroadActionIcon,
  required bool buildRailroadActionEnabled,
  required bool buildRailroadActionHasRailBuilderUnits,
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
      showBuildRailroadActionIcon: showBuildRailroadActionIcon,
      buildRailroadActionEnabled: buildRailroadActionEnabled,
      buildRailroadActionHasRailBuilderUnits:
          buildRailroadActionHasRailBuilderUnits,
      onBuildRailroadTap: () {},
      onClose: () {},
    ),
  );
}
