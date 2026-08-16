// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Detach and sail
// overlay stories (Refs #4448).
part of 'catalog.dart';

/// MAP20001 Naval **Detach and sail** use cases. Refs #4448.
List<WidgetbookUseCase> get provinceOverlayDetachAndSailUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Detach and sail enabled',
    builder: (context) => _provinceOverlayDetachAndSailStory(
      showDetachAndSail: true,
      detachAndSailEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Detach and sail hidden',
    builder: (context) => _provinceOverlayDetachAndSailStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Detach and sail 320 dp',
    builder: (context) => _provinceOverlayDetachAndSailStory(
      showDetachAndSail: true,
      detachAndSailEnabled: true,
      width: 320,
    ),
  ),
];

Widget _provinceOverlayDetachAndSailStory({
  bool showDetachAndSail = false,
  bool detachAndSailEnabled = false,
  double width = 640,
}) {
  final game = demoGameForOverlay;
  final region = demoRegionForOverlay;
  return SizedBox(
    width: width,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      detachAndSail: ProvinceDetachAndSailOverlayControls(
        showDetachAndSail: showDetachAndSail,
        detachAndSailEnabled: detachAndSailEnabled,
        detachAndSailTooltip:
            'Detach a squadron from the Home Fleet, then choose an adjacent sea.',
        onDetachAndSailTap: () {},
      ),
      onClose: () {},
    ),
  );
}
