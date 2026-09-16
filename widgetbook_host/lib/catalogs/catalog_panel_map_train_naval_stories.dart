// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Train overlay stories (Refs #4776).
part of 'catalog.dart';

/// MAP20001 Naval **Train** on the human capital. Refs #4776.
List<WidgetbookUseCase> get provinceOverlayTrainNavalUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Train enabled',
    builder: (context) =>
        _provinceOverlayTrainNavalStory(showTrainNavalControl: true),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Train hidden',
    builder: (context) =>
        _provinceOverlayTrainNavalStory(showTrainNavalControl: false),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Train 320 dp',
    builder: (context) => _provinceOverlayTrainNavalStory(
      showTrainNavalControl: true,
      size: const Size(320, 560),
    ),
  ),
];

Widget _provinceOverlayTrainNavalStory({
  required bool showTrainNavalControl,
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
      showTrainNavalControl: showTrainNavalControl,
      onTrainNavalTap: () {},
      onClose: () {},
    ),
  );
}
