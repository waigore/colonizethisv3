// coverage:ignore-file
// Dev-only Widgetbook catalog part; MAP20001 Naval Blockade/Beachhead
// overlay stories (Refs #4413).
part of 'catalog.dart';

/// MAP20001 Naval **Blockade** / **Beachhead** use cases. Refs #4413, #4516.
List<WidgetbookUseCase> get provinceOverlayNavalMissionUseCases => [
  WidgetbookUseCase(
    name: 'Standalone — Naval Blockade enabled',
    builder: (context) => _provinceOverlayNavalMissionStory(
      showBlockade: true,
      blockadeEnabled: true,
      blockadeTooltip: AppLocalizationsEn().naval_mission_effect_blockade,
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
      blockadeTooltip: AppLocalizationsEn().naval_mission_effect_blockade,
      width: 320,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Under blockade',
    builder: (context) => _provinceOverlayNavalMissionStory(
      blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval Under blockade capital',
    builder: (context) => _provinceOverlayNavalMissionStory(
      blockadeStatus: ProvinceBlockadeStatus.capitalBlockaded,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval sea-zone Patrol/Defend enabled',
    builder: (context) => _provinceOverlaySeaZoneStayMissionStory(
      showPatrol: true,
      patrolEnabled: true,
      showDefend: true,
      defendEnabled: true,
      patrolTooltip: AppLocalizationsEn().naval_mission_effect_patrol,
      defendTooltip: AppLocalizationsEn().naval_mission_effect_defend,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval sea-zone Patrol/Defend disabled',
    builder: (context) => _provinceOverlaySeaZoneStayMissionStory(
      showPatrol: true,
      patrolEnabled: false,
      showDefend: true,
      defendEnabled: false,
      patrolTooltip: AppLocalizationsEn().naval_mission_noMissionsAvailable,
      defendTooltip: AppLocalizationsEn().naval_mission_noMissionsAvailable,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval sea-zone Patrol/Defend hidden',
    builder: (context) => _provinceOverlaySeaZoneStayMissionStory(),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval sea-zone Patrol/Defend 320 dp',
    builder: (context) => _provinceOverlaySeaZoneStayMissionStory(
      showPatrol: true,
      patrolEnabled: true,
      showDefend: true,
      defendEnabled: true,
      patrolTooltip: AppLocalizationsEn().naval_mission_effect_patrol,
      defendTooltip: AppLocalizationsEn().naval_mission_effect_defend,
      width: 320,
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval sea-zone pending mission preview',
    builder: (context) => _provinceOverlaySeaZoneStayMissionStory(
      showPatrol: true,
      patrolEnabled: false,
      showDefend: true,
      defendEnabled: false,
      includeAtSeaFleet: true,
      draftOrders: Orders(
        navalMissionOrdersByPlayerId: {
          demoGameForOverlay.players.first.id: [
            NavalMissionOrder(
              fleetId: 'overlay_sea_fleet',
              mission: FleetMission.patrol.name,
            ),
          ],
        },
      ),
    ),
  ),
  WidgetbookUseCase(
    name: 'Standalone — Naval sea-zone pending move preview',
    builder: (context) => _provinceOverlaySeaZoneStayMissionStory(
      showPatrol: true,
      patrolEnabled: false,
      showDefend: true,
      defendEnabled: false,
      includeAtSeaFleet: true,
      draftOrders: Orders(
        navalMoveOrdersByPlayerId: {
          demoGameForOverlay.players.first.id: [
            NavalMoveOrder(
              fleetId: 'overlay_sea_fleet',
              destinationSeaZoneId: 'elsewhere',
            ),
          ],
        },
      ),
    ),
  ),
];

/// MAP20001 Naval **Blockade** / **Beachhead** variants. Refs #4413, #4516.
Widget _provinceOverlayNavalMissionStory({
  bool showBlockade = false,
  bool blockadeEnabled = false,
  bool showBeachhead = false,
  bool beachheadEnabled = false,
  String blockadeTooltip = 'Blockade',
  String beachheadTooltip = 'Beachhead',
  ProvinceBlockadeStatus blockadeStatus = ProvinceBlockadeStatus.none,
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
      blockadeStatus: blockadeStatus,
      onClose: () {},
    ),
  );
}

/// MAP20001 sea-zone Patrol/Defend variants. Refs #4605.
Widget _provinceOverlaySeaZoneStayMissionStory({
  bool showPatrol = false,
  bool patrolEnabled = false,
  bool showDefend = false,
  bool defendEnabled = false,
  String patrolTooltip = '',
  String defendTooltip = '',
  bool includeAtSeaFleet = false,
  Orders draftOrders = const Orders(),
  double width = 640,
}) {
  final region = demoRegionForOverlay;
  final base = demoGameForOverlay;
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
  final game = includeAtSeaFleet
      ? base.copyWith(
          worldState: base.worldState.copyWith(
            fleets: [
              ...base.worldState.fleets,
              Fleet(
                id: 'overlay_sea_fleet',
                ownerId: base.players.first.id,
                regionId: regionId,
                seaZoneId: localSea,
                ships: const [ShipInstance(id: 'os1', typeId: 'carrack')],
              ),
            ],
          ),
        )
      : base;
  return SizedBox(
    width: width,
    height: 520,
    child: ProvinceSeaZoneDetailOverlay(
      game: game,
      region: region,
      displayId: seaId,
      selectedTileKey: tileKey,
      humanPlayerId: game.players.first.id,
      playerView: demoHumanPlayerViewForOverlay,
      draftOrders: draftOrders,
      omniscientDetail: true,
      navalMission: ProvinceNavalMissionOverlayControls(
        showPatrol: showPatrol,
        patrolEnabled: patrolEnabled,
        patrolTooltip: patrolTooltip,
        onPatrolTap: () {},
        showDefend: showDefend,
        defendEnabled: defendEnabled,
        defendTooltip: defendTooltip,
        onDefendTap: () {},
      ),
      onClose: () {},
    ),
  );
}
