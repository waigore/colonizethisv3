// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

({
  Game game,
  MapTopology topology,
  Army army,
  PlayerView playerView,
}) _moveArmyInvasionIntelStoryFixture({
  required bool fullIntelOnInvasionDest,
}) {
  const playerId = 'gp_move_intel_story';
  const otherFactionId = 'gp_other_intel_story';
  const from = 'oldWorld|p_from_intel';
  const invasionDest = 'oldWorld|p_invasion_intel';

  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: from,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: invasionDest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: from, id2: invasionDest),
    ],
  );

  final invasionTileVisibility =
      fullIntelOnInvasionDest ? 'fullyVisible' : 'fogged';

  final game = Game(
    id: 'g_move_intel_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: from,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Origin',
          ),
          Province(
            id: invasionDest,
            regionId: 'oldWorld',
            ownerId: otherFactionId,
            displayName: 'Rival City',
            fortLevel: 2,
          ),
        ],
        units: [
          Unit(
            id: 'u_story_mover',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: from,
          ),
          Unit(
            id: 'u_story_def1',
            type: 'musketeers',
            ownerId: otherFactionId,
            locationProvinceId: invasionDest,
          ),
          Unit(
            id: 'u_story_def2',
            type: 'pikemen',
            ownerId: otherFactionId,
            locationProvinceId: invasionDest,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'astory_intel',
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: from,
          regimentUnitIds: ['u_story_mover'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          from: ['oldWorld|p_from_intel|0|0'],
          invasionDest: ['oldWorld|p_invasion_intel|0|0'],
        },
      },
      playerVisibilityByTile: {
        playerId: {
          'oldWorld|p_from_intel|0|0': 'fullyVisible',
          'oldWorld|p_invasion_intel|0|0': invasionTileVisibility,
        },
      },
    ),
    players: const [
      Player(
        id: playerId,
        displayName: 'Catalog Player',
        isHuman: true,
        capitalProvinceId: from,
      ),
      Player(
        id: otherFactionId,
        displayName: 'Rival Power',
        isHuman: false,
        capitalProvinceId: invasionDest,
      ),
    ],
  );

  final playerView = buildPlayerView(game, topology, playerId);

  return (
    game: game,
    topology: topology,
    army: game.worldState.armies.first,
    playerView: playerView,
  );
}

/// Invasion-intel Move Army Dialog use cases. SPEC/ui/move-army-dialog.md (Refs #4216).
List<WidgetbookUseCase> get moveArmyInvasionIntelDialogUseCases => [
  WidgetbookUseCase(
    name: 'Invasion intel — full visibility (#4216)',
    builder: (context) {
      final fixture = _moveArmyInvasionIntelStoryFixture(
        fullIntelOnInvasionDest: true,
      );
      return _moveDialogStoryFrame(
        open: (innerContext) {
          return ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: innerContext,
                builder: (_) => MoveArmyDialog(
                  army: fixture.army,
                  game: fixture.game,
                  humanPlayerId: 'gp_move_intel_story',
                  bus: AppEventBus.create(),
                  topology: fixture.topology,
                  draftOrders: const Orders(),
                  playerView: fixture.playerView,
                ),
              );
            },
            // ignore: avoid_hardcoded_strings_in_widgets
            child: const Text('Open Move Army (full intel)'),
          );
        },
      );
    },
  ),
  WidgetbookUseCase(
    name: 'Invasion intel — defenders unknown (#4216)',
    builder: (context) {
      final fixture = _moveArmyInvasionIntelStoryFixture(
        fullIntelOnInvasionDest: false,
      );
      return _moveDialogStoryFrame(
        open: (innerContext) {
          return ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: innerContext,
                builder: (_) => MoveArmyDialog(
                  army: fixture.army,
                  game: fixture.game,
                  humanPlayerId: 'gp_move_intel_story',
                  bus: AppEventBus.create(),
                  topology: fixture.topology,
                  draftOrders: const Orders(),
                  playerView: fixture.playerView,
                ),
              );
            },
            // ignore: avoid_hardcoded_strings_in_widgets
            child: const Text('Open Move Army (unknown intel)'),
          );
        },
      );
    },
  ),
];
