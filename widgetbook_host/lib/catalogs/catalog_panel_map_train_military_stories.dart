// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Military Train overlay stories (Refs #4769).
part of 'catalog.dart';

/// MAP20001 Military **Train** on the human capital. Refs #4769.
List<WidgetbookUseCase> get provinceOverlayTrainMilitaryUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Military Train enabled',
    builder: (context) =>
        _provinceOverlayTrainMilitaryStory(showTrainMilitaryControl: true),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Train hidden',
    builder: (context) =>
        _provinceOverlayTrainMilitaryStory(showTrainMilitaryControl: false),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Train 320 dp',
    builder: (context) => _provinceOverlayTrainMilitaryStory(
      showTrainMilitaryControl: true,
      size: const Size(320, 560),
    ),
  ),
];

Widget _provinceOverlayTrainMilitaryStory({
  required bool showTrainMilitaryControl,
  Size size = const Size(640, 520),
}) {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  return SizedBox(
    width: size.width,
    height: size.height,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      showTrainMilitaryControl: showTrainMilitaryControl,
      onTrainMilitaryTap: () {},
      onClose: () {},
    ),
  );
}
