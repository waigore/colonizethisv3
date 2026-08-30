// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Military Move/Invade overlay stories (Refs #4350).
part of 'catalog.dart';

/// MAP20001 Military **Move** / **Invade** use cases. Refs #4350.
List<WidgetbookUseCase> get provinceOverlayMoveInvadeUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Military Move enabled',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: true,
      moveArmyEnabled: true,
      showInvadeArmyControl: false,
      invadeArmyEnabled: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Move detach enabled',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: true,
      moveArmyEnabled: true,
      showInvadeArmyControl: false,
      invadeArmyEnabled: false,
      moveArmyTooltip:
          'Detach a field army from the Home Army, then choose where it marches.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Move disabled',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: true,
      moveArmyEnabled: false,
      showInvadeArmyControl: false,
      invadeArmyEnabled: false,
      moveArmyTooltip:
          'The Home Army cannot leave the capital. Split a field army first.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Move hidden',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: false,
      moveArmyEnabled: false,
      showInvadeArmyControl: false,
      invadeArmyEnabled: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Invade enabled',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: false,
      moveArmyEnabled: false,
      showInvadeArmyControl: true,
      invadeArmyEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Invade disabled',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: false,
      moveArmyEnabled: false,
      showInvadeArmyControl: true,
      invadeArmyEnabled: false,
      invadeArmyTooltip: 'No field army can reach this province this turn.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Invade hidden',
    builder: (context) => _provinceOverlayMoveInvadeStory(
      showMoveArmyControl: false,
      moveArmyEnabled: false,
      showInvadeArmyControl: false,
      invadeArmyEnabled: false,
    ),
  ),
];

/// MAP20001 Military **Move** / **Invade** variants. Refs #4350.
Widget _provinceOverlayMoveInvadeStory({
  required bool showMoveArmyControl,
  required bool moveArmyEnabled,
  required bool showInvadeArmyControl,
  required bool invadeArmyEnabled,
  String moveArmyTooltip = 'Move',
  String invadeArmyTooltip = 'Invade',
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
      omniscientDetail: true,
      showMoveArmyControl: showMoveArmyControl,
      moveArmyEnabled: moveArmyEnabled,
      moveArmyTooltip: moveArmyTooltip,
      onMoveArmyTap: () {},
      showInvadeArmyControl: showInvadeArmyControl,
      invadeArmyEnabled: invadeArmyEnabled,
      invadeArmyTooltip: invadeArmyTooltip,
      onInvadeArmyTap: () {},
      onClose: () {},
    ),
  );
}
