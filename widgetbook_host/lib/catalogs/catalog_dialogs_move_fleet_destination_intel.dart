// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate.
// SPEC/ui/move-fleet-dialog.md (#4573).
part of 'catalog.dart';

({
  Game game,
  MapTopology topology,
  Fleet fleet,
  PlayerView? playerView,
}) _moveFleetDestinationIntelStoryFixture({
  required bool fullIntel,
  required FleetMission hostileMission,
}) {
  const playerId = 'gp_move_fleet_intel_story';
  const rivalId = 'gp_move_fleet_intel_rival';
  const originSea = 'oldWorld|sea_origin_intel';
  const destSea = 'oldWorld|sea_dest_intel';
  const destTile = 'oldWorld|sea_dest_intel|0|0';

  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: originSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: destSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: originSea, id2: destSea),
    ],
  );

  final visibility = fullIntel
      ? const {destTile: 'fullyVisible'}
      : const <String, String>{};

  final game = Game(
    id: 'g_move_fleet_intel_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'f_move_intel_self',
          ownerId: playerId,
          regionId: 'oldWorld',
          seaZoneId: originSea,
          ships: const [ShipInstance(id: 's_self', typeId: 'carrack')],
        ),
        Fleet(
          id: 'f_move_intel_hostile',
          ownerId: rivalId,
          regionId: 'oldWorld',
          seaZoneId: destSea,
          mission: hostileMission,
          ships: const [ShipInstance(id: 's_host', typeId: 'carrack')],
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {destSea: [destTile]},
      },
      playerVisibilityByTile: {playerId: visibility},
      seaZoneDisplayNameById: const {
        originSea: 'Origin Intel Sea',
        destSea: 'Hostile Intel Sea',
      },
    ),
    players: const [
      Player(id: playerId, displayName: 'Catalog Admiral', isHuman: true),
      Player(id: rivalId, displayName: 'Rival Navy', isHuman: false),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: playerId,
        factionId2: rivalId,
        state: RelationState.atWar,
      ),
    ],
  );

  final playerView = fullIntel ? buildPlayerView(game, topology, playerId) : null;

  return (
    game: game,
    topology: topology,
    fleet: game.worldState.fleets.firstWhere((f) => f.id == 'f_move_intel_self'),
    playerView: playerView,
  );
}

/// Hostile destination gist use cases for DLG30001. Refs #4573.
List<WidgetbookUseCase> get moveFleetDestinationIntelDialogUseCases => [
  WidgetbookUseCase(
    name: 'Hostile patrol destination',
    builder: (context) {
      final fixture = _moveFleetDestinationIntelStoryFixture(
        fullIntel: true,
        hostileMission: FleetMission.patrol,
      );
      return _moveDialogStoryFrame(
        open: (innerContext) {
          return ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: innerContext,
                builder: (_) => MoveFleetDialog(
                  game: fixture.game,
                  topology: fixture.topology,
                  humanPlayerId: 'gp_move_fleet_intel_story',
                  fleet: fixture.fleet,
                  bus: AppEventBus.create(),
                  playerView: fixture.playerView,
                ),
              );
            },
            // ignore: avoid_hardcoded_strings_in_widgets
            child: const Text('Open Move Fleet (hostile patrol)'),
          );
        },
      );
    },
  ),
  WidgetbookUseCase(
    name: 'Unknown intel destination',
    builder: (context) {
      final fixture = _moveFleetDestinationIntelStoryFixture(
        fullIntel: false,
        hostileMission: FleetMission.patrol,
      );
      return _moveDialogStoryFrame(
        open: (innerContext) {
          return ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: innerContext,
                builder: (_) => MoveFleetDialog(
                  game: fixture.game,
                  topology: fixture.topology,
                  humanPlayerId: 'gp_move_fleet_intel_story',
                  fleet: fixture.fleet,
                  bus: AppEventBus.create(),
                  playerView: fixture.playerView,
                ),
              );
            },
            // ignore: avoid_hardcoded_strings_in_widgets
            child: const Text('Open Move Fleet (fleets unknown)'),
          );
        },
      );
    },
  ),
];
