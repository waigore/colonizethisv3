// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Establish Embassy overlay
// stories (Refs #4739).
part of 'catalog.dart';

/// MAP20001 Political **Establish Embassy** shortcut use cases. Refs #4739.
List<WidgetbookUseCase> get provinceOverlayEstablishEmbassyUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Embassy enabled',
    builder: (context) =>
        _provinceOverlayEstablishEmbassyStory(showControl: true, enabled: true),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Embassy disabled',
    builder: (context) => _provinceOverlayEstablishEmbassyStory(
      showControl: true,
      enabled: false,
      rejectionReason:
          'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Embassy pending',
    builder: (context) => _provinceOverlayEstablishEmbassyStory(
      showControl: true,
      enabled: true,
      pending: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Embassy hidden',
    builder: (context) => _provinceOverlayEstablishEmbassyStory(
      showControl: false,
      enabled: false,
    ),
  ),
];

/// MAP20001 Political **Establish Embassy** shortcut variants. Refs #4739.
Widget _provinceOverlayEstablishEmbassyStory({
  required bool showControl,
  required bool enabled,
  bool pending = false,
  String? rejectionReason,
}) {
  final game = demoGameForOverlay;
  return SizedBox(
    width: 640,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      showEstablishEmbassyControl: showControl,
      establishEmbassyEnabled: enabled,
      establishEmbassyPending: pending,
      establishEmbassyRejectionReason: rejectionReason,
      onEstablishEmbassyTap: () {},
      onClose: () {},
    ),
  );
}
