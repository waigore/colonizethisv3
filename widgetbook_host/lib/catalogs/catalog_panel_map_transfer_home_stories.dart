// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Transfer to Home Fleet
// overlay stories (Refs #4625).
part of 'catalog.dart';

/// MAP20001 Naval **Transfer to Home Fleet** use cases. Refs #4625.
List<WidgetbookUseCase> get provinceOverlayTransferHomeUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Transfer to Home Fleet enabled',
    builder: (context) => _provinceOverlayTransferHomeStory(
      showTransfer: true,
      transferEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Transfer to Home Fleet disabled',
    builder: (context) => _provinceOverlayTransferHomeStory(
      showTransfer: true,
      transferEnabled: false,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Transfer to Home Fleet hidden',
    builder: (context) => _provinceOverlayTransferHomeStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Transfer to Home Fleet sea-zone enabled',
    builder: (context) => _provinceOverlayTransferHomeSeaStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Transfer to Home Fleet 320 dp',
    builder: (context) => _provinceOverlayTransferHomeStory(
      showTransfer: true,
      transferEnabled: true,
      width: 320,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Transfer fleet picker',
    builder: (context) {
      final game = demoGameForOverlay;
      final ids = game.worldState.fleets.map((f) => f.id).take(2).toList();
      return SizedBox(
        width: 420,
        height: 360,
        child: NavalMissionFleetPickerDialog(
          game: game,
          humanPlayerId: game.players.first.id,
          fleetIds: ids.isEmpty ? const ['fleet_a'] : ids,
        ),
      );
    },
  ),
];

Widget _provinceOverlayTransferHomeStory({
  bool showTransfer = false,
  bool transferEnabled = false,
  double width = 640,
}) {
  final game = demoGameForOverlay;
  return SizedBox(
    width: width,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: demoRegionForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      transferToHomeFleet: ProvinceTransferToHomeFleetOverlayControls(
        showTransferToHomeFleet: showTransfer,
        transferToHomeFleetEnabled: transferEnabled,
        transferToHomeFleetTooltip: transferEnabled
            ? 'Move hulls into the Home Fleet so cargo holds are available this turn.'
            : 'No sea-going fleet here can join the Home Fleet now.',
        onTransferToHomeFleetTap: () {},
      ),
      onClose: () {},
    ),
  );
}

Widget _provinceOverlayTransferHomeSeaStory() {
  final region = demoRegionForOverlay;
  final seaId = sampleSeaZoneIdForOverlay;
  final localSea = prefixedIdLocalSegment(seaId);
  final regionId = prefixedIdRegionSegment(seaId) ?? region.regionId;
  CellViewData? seaCell;
  for (final c in region.cells) {
    if (c.isSea && c.regionCellId == localSea) {
      seaCell = c;
      break;
    }
  }
  final tileKey = seaCell == null
      ? null
      : '$regionId|${seaCell.regionCellId}|${seaCell.x}|${seaCell.y}';
  return SizedBox(
    width: 640,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: demoGameForOverlay,
      region: region,
      displayId: seaId,
      selectedTileKey: tileKey,
      humanPlayerId: demoGameForOverlay.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      transferToHomeFleet: ProvinceTransferToHomeFleetOverlayControls(
        showTransferToHomeFleet: true,
        transferToHomeFleetEnabled: true,
        transferToHomeFleetTooltip:
            'Move hulls into the Home Fleet so cargo holds are available this turn.',
        onTransferToHomeFleetTap: () {},
      ),
      onClose: () {},
    ),
  );
}
