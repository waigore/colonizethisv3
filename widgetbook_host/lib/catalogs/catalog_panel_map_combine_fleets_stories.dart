// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Combine overlay stories (Refs #4659).
part of 'catalog.dart';

/// MAP20001 Naval **Combine** use cases. Refs #4659.
List<WidgetbookUseCase> get provinceOverlayCombineFleetsUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Combine enabled',
    builder: (context) => _provinceOverlayFleetCombineStory(
      show: true,
      enabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Combine Home Fleet target',
    builder: (context) => _provinceOverlayFleetCombineStory(
      show: true,
      enabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Combine sea-zone enabled',
    builder: (context) => _provinceOverlayFleetCombineStory(
      show: true,
      enabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Combine pending-order disabled',
    builder: (context) => _provinceOverlayFleetCombineStory(
      show: true,
      enabled: false,
      tooltip:
          'Cancel the pending sail or mission before combining these fleets.',
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Combine Home + non-transfer-eligible source',
    builder: (context) => _provinceOverlayFleetCombineStory(
      show: true,
      enabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Combine hidden',
    builder: (context) => _provinceOverlayFleetCombineStory(
      show: false,
      enabled: false,
    ),
  ),
];

Widget _provinceOverlayFleetCombineStory({
  required bool show,
  required bool enabled,
  String tooltip = 'Combine',
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
      navalCombine: ProvinceNavalCombineOverlayControls(
        showCombineFleets: show,
        combineFleetsEnabled: enabled,
        combineFleetsTooltip: tooltip,
        onCombineFleetsTap: () {},
      ),
      onClose: () {},
    ),
  );
}
