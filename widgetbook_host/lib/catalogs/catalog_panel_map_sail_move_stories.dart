// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Sail / Move
// overlay stories (Refs #4735).
part of 'catalog.dart';

/// MAP20001 Naval **Sail / Move** use cases. Refs #4735.
List<WidgetbookUseCase> get provinceOverlaySailMoveUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Sail / Move sea enabled',
    builder: (context) => _provinceOverlaySailMoveSeaStory(
      showSailMove: true,
      sailMoveEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Sail / Move multi-fleet',
    builder: (context) => _provinceOverlaySailMoveSeaStory(
      showSailMove: true,
      sailMoveEnabled: true,
      multiFleetLabel: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Sail / Move hidden',
    builder: (context) => _provinceOverlaySailMoveSeaStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Sail / Move in-port enabled',
    builder: (context) => _provinceOverlaySailMovePortStory(
      showSailMove: true,
      sailMoveEnabled: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Sail / Move capital with Transfer',
    builder: (context) => _provinceOverlaySailMovePortStory(
      showSailMove: true,
      sailMoveEnabled: true,
      showTransfer: true,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Sail / Move 320 dp',
    builder: (context) => _provinceOverlaySailMovePortStory(
      showSailMove: true,
      sailMoveEnabled: true,
      showTransfer: true,
      width: 320,
    ),
  ),
];

Widget _provinceOverlaySailMoveSeaStory({
  bool showSailMove = false,
  bool sailMoveEnabled = false,
  bool multiFleetLabel = false,
  double width = 640,
}) {
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
    width: width,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: demoGameForOverlay,
      region: region,
      displayId: seaId,
      selectedTileKey: tileKey,
      humanPlayerId: demoGameForOverlay.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      omniscientDetail: true,
      sailMove: ProvinceOverlaySailMoveOverlayControls(
        showSailMove: showSailMove,
        sailMoveEnabled: sailMoveEnabled,
        sailMoveTooltip: multiFleetLabel
            ? 'Move one of several fleets in this sea to an adjacent sea zone or owned port.'
            : 'Move this fleet to an adjacent sea zone or owned port.',
        onSailMoveTap: () {},
      ),
      onClose: () {},
    ),
  );
}

Widget _provinceOverlaySailMovePortStory({
  bool showSailMove = false,
  bool sailMoveEnabled = false,
  bool showTransfer = false,
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
        transferToHomeFleetEnabled: showTransfer,
        transferToHomeFleetTooltip: showTransfer
            ? 'Transfer ships from a sea-going fleet into the Home Fleet.'
            : '',
        onTransferToHomeFleetTap: () {},
      ),
      sailMove: ProvinceOverlaySailMoveOverlayControls(
        showSailMove: showSailMove,
        sailMoveEnabled: sailMoveEnabled,
        sailMoveTooltip:
            'Move this fleet to an adjacent sea zone or owned port.',
        onSailMoveTap: () {},
      ),
      onClose: () {},
    ),
  );
}
