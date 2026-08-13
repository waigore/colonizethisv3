// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

({Game game, MapTopology topology, Fleet fleet}) _navalMissionMenuStoryFixture() {
  const playerId = 'gp_naval_mission_story';
  const originSea = 'oldWorld|sea_origin';
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: originSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [],
  );
  final game = Game(
    id: 'g_naval_mission_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: playerId,
        displayName: 'Catalog Admiral',
        isHuman: true,
      ),
    ],
  );
  final fleet = Fleet(
    id: 'f_mission_story',
    ownerId: playerId,
    regionId: 'oldWorld',
    seaZoneId: originSea,
    ships: const [ShipInstance(id: 'ship_mission', typeId: 'carrack')],
  );
  return (game: game, topology: topology, fleet: fleet);
}

({
  Game game,
  MapTopology topology,
  Fleet fleet,
  List<String> targetProvinceIds,
}) _navalMissionTargetStoryFixture() {
  const playerId = 'gp_naval_target_story';
  const enemyId = 'gp_naval_target_enemy';
  const originSea = 'oldWorld|sea_origin';
  const ownProvince = 'oldWorld|p_own';
  const enemyProvince = 'oldWorld|p_enemy';
  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: originSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: ownProvince,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: enemyProvince,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [
      TopologyEdge(id1: originSea, id2: ownProvince),
      TopologyEdge(id1: originSea, id2: enemyProvince),
    ],
  );
  final game = Game(
    id: 'g_naval_target_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: ownProvince,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Friendly Port',
          ),
          Province(
            id: enemyProvince,
            regionId: 'oldWorld',
            ownerId: enemyId,
            displayName: 'Enemy Coast',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: playerId,
        factionId2: enemyId,
        state: RelationState.atWar,
      ),
    ],
    players: const [
      Player(
        id: playerId,
        displayName: 'Catalog Admiral',
        isHuman: true,
      ),
      Player(
        id: enemyId,
        displayName: 'Enemy Power',
        isHuman: false,
      ),
    ],
  );
  final fleet = Fleet(
    id: 'f_target_story',
    ownerId: playerId,
    regionId: 'oldWorld',
    seaZoneId: originSea,
    ships: const [ShipInstance(id: 'ship_target', typeId: 'carrack')],
  );
  return (
    game: game,
    topology: topology,
    fleet: fleet,
    targetProvinceIds: [enemyProvince],
  );
}

({Game game, List<String> fleetIds}) _navalMissionFleetPickerStoryFixture() {
  const playerId = 'gp_naval_picker_story';
  final game = Game(
    id: 'g_naval_picker_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: playerId,
        displayName: 'Catalog Admiral',
        isHuman: true,
      ),
    ],
  );
  return (
    game: game,
    fleetIds: const ['f_picker_a', 'f_picker_b'],
  );
}

/// Naval mission assign dialogs. SPEC/ui/naval-mission-*-dialog.md (Refs #4213).
List<WidgetbookNode> get navalMissionDialogDirectories => [
  WidgetbookFolder(
    name: 'Naval Mission Menu Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — patrol available',
        builder: (context) {
          final fixture = _navalMissionMenuStoryFixture();
          final availability = navalMissionAvailabilityForFleet(
            game: fixture.game,
            topology: fixture.topology,
            playerId: fixture.fleet.ownerId,
            fleet: fixture.fleet,
            currentOrders: const Orders(),
          );
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => NavalMissionMenuDialog(
                      game: fixture.game,
                      fleet: fixture.fleet,
                      availability: availability,
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Naval Mission Menu'),
              );
            },
          );
        },
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Naval Mission Target Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — blockade target',
        builder: (context) {
          final fixture = _navalMissionTargetStoryFixture();
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => NavalMissionTargetDialog(
                      game: fixture.game,
                      mission: FleetMission.blockade,
                      fleet: fixture.fleet,
                      targetProvinceIds: fixture.targetProvinceIds,
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Naval Mission Target (Blockade)'),
              );
            },
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Beachhead — coastal target caption',
        builder: (context) {
          final fixture = _navalMissionTargetStoryFixture();
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => NavalMissionTargetDialog(
                      game: fixture.game,
                      mission: FleetMission.beachhead,
                      fleet: fixture.fleet,
                      targetProvinceIds: fixture.targetProvinceIds,
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Naval Mission Target (Beachhead)'),
              );
            },
          );
        },
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Naval Mission Fleet Picker Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — two fleets',
        builder: (context) {
          final fixture = _navalMissionFleetPickerStoryFixture();
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<String>(
                    context: innerContext,
                    builder: (_) => NavalMissionFleetPickerDialog(
                      game: fixture.game,
                      humanPlayerId: 'gp_naval_picker_story',
                      fleetIds: fixture.fleetIds,
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Naval Mission Fleet Picker'),
              );
            },
          );
        },
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Overlay Army Move Picker Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — two armies',
        builder: (context) {
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<String>(
                    context: innerContext,
                    builder: (_) => OverlayArmyMovePickerDialog(
                      game: demoGameForOverlay,
                      humanPlayerId: demoGameForOverlay.players.first.id,
                      armyIds: const ['army_a', 'army_b'],
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Overlay Army Move Picker'),
              );
            },
          );
        },
      ),
    ],
  ),
];
