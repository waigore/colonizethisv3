// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Civilian Counter-espionage (Refs #4528).
part of 'catalog.dart';

/// MAP20001 Civilian **Counter-espionage** use cases. Refs #4528.
List<WidgetbookUseCase> get provinceOverlayCounterEspionageUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Civilian Counter-espionage enabled',
    builder: (context) => _provinceOverlayCounterEspionageStory(
      showControl: true,
      enabled: true,
      gist: 'Protects the whole realm, not only this province.',
      tooltip: 'One Spy is enough; extra Spies do not add more.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Counter-espionage disabled (no idle Spy)',
    builder: (context) => _provinceOverlayCounterEspionageStory(
      showControl: true,
      enabled: false,
      tooltip: 'No idle Spy can take this post.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Counter-espionage disabled (already posted)',
    builder: (context) => _provinceOverlayCounterEspionageStory(
      showControl: true,
      enabled: false,
      tooltip: 'A Spy is already posted for the whole realm.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Counter-espionage hidden',
    builder: (context) => _provinceOverlayCounterEspionageStory(
      showControl: false,
      enabled: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Civilian Counter-espionage enabled (320 dp)',
    builder: (context) => _provinceOverlayCounterEspionageStory(
      showControl: true,
      enabled: true,
      gist: 'Protects the whole realm, not only this province.',
      tooltip: 'One Spy is enough; extra Spies do not add more.',
      width: 320,
    ),
  ),
];

Widget _provinceOverlayCounterEspionageStory({
  required bool showControl,
  required bool enabled,
  String tooltip = 'Counter-espionage',
  String gist = '',
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
      counterEspionage: (
        showControl: showControl,
        enabled: enabled,
        tooltip: tooltip,
        gist: gist,
        onTap: () {},
      ),
      onClose: () {},
    ),
  );
}
