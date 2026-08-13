// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Establish Consulate overlay
// stories (Refs #4346).
part of 'catalog.dart';

/// MAP20001 Political **Establish Consulate** shortcut use cases. Refs #4346.
List<WidgetbookUseCase> get provinceOverlayEstablishConsulateUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Consulate enabled',
    builder: (context) => _provinceOverlayEstablishConsulateStory(
      showControl: true,
      enabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Consulate disabled',
    builder: (context) => _provinceOverlayEstablishConsulateStory(
      showControl: true,
      enabled: false,
      rejectionReason:
          'Diplomatic Expertise tech required for overtures with Minor Nations and Tribes',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Consulate pending',
    builder: (context) => _provinceOverlayEstablishConsulateStory(
      showControl: true,
      enabled: true,
      pending: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Political Establish Consulate hidden',
    builder: (context) => _provinceOverlayEstablishConsulateStory(
      showControl: false,
      enabled: false,
    ),
  ),
];

/// MAP20001 Political **Establish Consulate** shortcut variants. Refs #4346.
Widget _provinceOverlayEstablishConsulateStory({
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
      showEstablishConsulateControl: showControl,
      establishConsulateEnabled: enabled,
      establishConsulatePending: pending,
      establishConsulateRejectionReason: rejectionReason,
      onEstablishConsulateTap: () {},
      onClose: () {},
    ),
  );
}
