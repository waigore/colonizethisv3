// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Military Combine overlay stories (Refs #4610).
part of 'catalog.dart';

/// MAP20001 Military **Combine** use cases. Refs #4610.
List<WidgetbookUseCase> get provinceOverlayCombineArmiesUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Military Combine enabled',
    builder: (context) => _provinceOverlayCombineStory(
      showCombineArmiesControl: true,
      combineArmiesEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Combine Home Army target',
    builder: (context) => _provinceOverlayCombineStory(
      showCombineArmiesControl: true,
      combineArmiesEnabled: true,
      combineArmiesTooltip: 'Combine',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Combine pending-move disabled',
    builder: (context) => _provinceOverlayCombineStory(
      showCombineArmiesControl: true,
      combineArmiesEnabled: false,
      combineArmiesTooltip:
          'Cancel the pending march before combining these armies.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Military Combine hidden',
    builder: (context) => _provinceOverlayCombineStory(
      showCombineArmiesControl: false,
      combineArmiesEnabled: false,
    ),
  ),
];

Widget _provinceOverlayCombineStory({
  required bool showCombineArmiesControl,
  required bool combineArmiesEnabled,
  String combineArmiesTooltip = 'Combine',
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
      showCombineArmiesControl: showCombineArmiesControl,
      combineArmiesEnabled: combineArmiesEnabled,
      combineArmiesTooltip: combineArmiesTooltip,
      onCombineArmiesTap: () {},
      onClose: () {},
    ),
  );
}
