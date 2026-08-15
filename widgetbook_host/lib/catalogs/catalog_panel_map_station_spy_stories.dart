// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Civilian Station spy stories (Refs #4439).
part of 'catalog.dart';

/// MAP20001 Civilian **Station spy** use cases. Refs #4439.
List<WidgetbookUseCase> get provinceOverlayStationSpyUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Civilian Station spy enabled',
    builder: (context) =>
        _provinceOverlayStationSpyStory(showControl: true, enabled: true),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Station spy disabled (no idle Spy)',
    builder: (context) => _provinceOverlayStationSpyStory(
      showControl: true,
      enabled: false,
      tooltip: 'No idle Spy can relocate here.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Station spy disabled (not occupiable)',
    builder: (context) => _provinceOverlayStationSpyStory(
      showControl: true,
      enabled: false,
      tooltip: 'This tile cannot be occupied.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Station spy hidden',
    builder: (context) =>
        _provinceOverlayStationSpyStory(showControl: false, enabled: false),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Station spy enabled (320 dp)',
    builder: (context) => _provinceOverlayStationSpyStory(
      showControl: true,
      enabled: true,
      width: 320,
    ),
  ),
];

Widget _provinceOverlayStationSpyStory({
  required bool showControl,
  required bool enabled,
  String tooltip = 'Station spy',
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
      stationSpy: (
        showControl: showControl,
        enabled: enabled,
        tooltip: tooltip,
        onTap: () {},
      ),
      onClose: () {},
    ),
  );
}
