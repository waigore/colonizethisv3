// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Blockade/Beachhead
// overlay stories (Refs #4413).
part of 'catalog.dart';

/// MAP20001 Naval **Blockade** / **Beachhead** use cases. Refs #4413.
List<WidgetbookUseCase> get provinceOverlayNavalMissionUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Blockade enabled',
    builder: (context) => _provinceOverlayNavalMissionStory(
      showBlockade: true,
      blockadeEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Blockade disabled',
    builder: (context) => _provinceOverlayNavalMissionStory(
      showBlockade: true,
      blockadeEnabled: false,
      blockadeTooltip:
          'A fleet must be at sea beside this coast. Fleets in port cannot take missions.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Blockade hidden',
    builder: (context) => _provinceOverlayNavalMissionStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Beachhead enabled',
    builder: (context) => _provinceOverlayNavalMissionStory(
      showBeachhead: true,
      beachheadEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Beachhead disabled',
    builder: (context) => _provinceOverlayNavalMissionStory(
      showBeachhead: true,
      beachheadEnabled: false,
      beachheadTooltip:
          'A fleet must be at sea beside this coast. Fleets in port cannot take missions.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Beachhead hidden',
    builder: (context) => _provinceOverlayNavalMissionStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Blockade/Beachhead 320 dp',
    builder: (context) => _provinceOverlayNavalMissionStory(
      showBlockade: true,
      blockadeEnabled: true,
      showBeachhead: true,
      beachheadEnabled: true,
      width: 320,
    ),
  ),
];

/// MAP20001 Naval **Blockade** / **Beachhead** variants. Refs #4413.
Widget _provinceOverlayNavalMissionStory({
  bool showBlockade = false,
  bool blockadeEnabled = false,
  bool showBeachhead = false,
  bool beachheadEnabled = false,
  String blockadeTooltip = 'Blockade',
  String beachheadTooltip = 'Beachhead',
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
      navalMission: ProvinceNavalMissionOverlayControls(
        showBlockade: showBlockade,
        blockadeEnabled: blockadeEnabled,
        blockadeTooltip: blockadeTooltip,
        onBlockadeTap: () {},
        showBeachhead: showBeachhead,
        beachheadEnabled: beachheadEnabled,
        beachheadTooltip: beachheadTooltip,
        onBeachheadTap: () {},
      ),
      onClose: () {},
    ),
  );
}
