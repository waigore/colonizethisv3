part of 'catalog.dart';

MaterialApp _moveDialogStoryFrame({required Widget Function(BuildContext) open}) {
  return MaterialApp(
    theme: AppThemes.colonial,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: Builder(builder: open),
      ),
    ),
  );
}

({Game game, MapTopology topology, Army army}) _moveArmyStoryFixture() {
  const playerId = 'gp_move_story';
  const otherFactionId = 'gp_other_story';
  const from = 'oldWorld|p_from';
  const playerDest = 'oldWorld|p_player_dest';
  const invasionDest = 'oldWorld|p_invasion_dest';

  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: from,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: playerDest,
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
      TopologyEdge(id1: from, id2: playerDest),
      TopologyEdge(id1: from, id2: invasionDest),
    ],
  );

  final game = Game(
    id: 'g_move_story',
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
            id: playerDest,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Friendly Port',
          ),
          Province(
            id: invasionDest,
            regionId: 'oldWorld',
            ownerId: otherFactionId,
            displayName: 'Rival City',
          ),
        ],
        units: [
          Unit(
            id: 'u_story',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: from,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: const [
        Army(
          id: 'astory',
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: from,
          regimentUnitIds: ['u_story'],
          isHomeArmy: false,
        ),
      ],
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          from: ['oldWorld|p_from|0|0'],
          playerDest: ['oldWorld|p_player_dest|0|0'],
          invasionDest: ['oldWorld|p_invasion_dest|0|0'],
        },
      },
      playerVisibilityByTile: const {
        playerId: {
          'oldWorld|p_from|0|0': 'fullyVisible',
          'oldWorld|p_player_dest|0|0': 'fullyVisible',
          'oldWorld|p_invasion_dest|0|0': 'fullyVisible',
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

  return (game: game, topology: topology, army: game.worldState.armies.first);
}

({Game game, MapTopology topology, Fleet fleet}) _moveFleetStoryFixture() {
  const playerId = 'gp_move_fleet_story';
  const originSea = 'oldWorld|sea_origin';
  const adjacentSea = 'oldWorld|sea_adjacent';
  const crossSea = 'newWorld|sea_cross';
  const capitalProvince = 'oldWorld|p_capital';

  const topology = MapTopology(
    nodes: [
      TopologyNode(
        id: originSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: adjacentSea,
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: crossSea,
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: originSea, id2: adjacentSea),
      TopologyEdge(id1: originSea, id2: crossSea),
    ],
  );

  final game = Game(
    id: 'g_move_fleet_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: capitalProvince,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Capital Port',
          ),
        ],
      ),
      newWorld: const RegionData(),
      portsByProvinceSeaboard: const {
        'oldWorld|p_capital|sea_origin': 'oldWorld|p_capital|0|0',
      },
      seaZoneDisplayNameById: const {
        'oldWorld|sea_origin': 'Origin Sea',
        'oldWorld|sea_adjacent': 'Adjacent Sea',
        'newWorld|sea_cross': 'Cross Sea',
      },
    ),
    players: const [
      Player(
        id: playerId,
        displayName: 'Catalog Admiral',
        isHuman: true,
        capitalProvinceId: capitalProvince,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: capitalProvince,
          x: 0,
          y: 0,
        ),
      ),
    ],
  );

  final fleet = Fleet(
    id: 'fstory',
    ownerId: playerId,
    regionId: 'oldWorld',
    seaZoneId: originSea,
    ships: const [ShipInstance(id: 'ship_story', typeId: 'carrack')],
  );

  return (game: game, topology: topology, fleet: fleet);
}

/// Move Army Dialog stories. SPEC/ui/move-army-dialog.md.
List<WidgetbookNode> get moveArmyDialogDirectories => [
  WidgetbookFolder(
    name: 'Move Army Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — grouped destinations',
        builder: (context) {
          final fixture = _moveArmyStoryFixture();
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => MoveArmyDialog(
                      army: fixture.army,
                      game: fixture.game,
                      humanPlayerId: 'gp_move_story',
                      bus: AppEventBus.create(),
                      topology: fixture.topology,
                      draftOrders: const Orders(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Move Army'),
              );
            },
          );
        },
      ),
    ],
  ),
];

/// Move Fleet Dialog stories. SPEC/ui/move-fleet-dialog.md.
List<WidgetbookNode> get moveFleetDialogDirectories => [
  WidgetbookFolder(
    name: 'Move Fleet Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — sea zones + dock',
        builder: (context) {
          final fixture = _moveFleetStoryFixture();
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => MoveFleetDialog(
                      game: fixture.game,
                      topology: fixture.topology,
                      humanPlayerId: 'gp_move_fleet_story',
                      fleet: fixture.fleet,
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Move Fleet'),
              );
            },
          );
        },
      ),
    ],
  ),
];

({Game game, Fleet source, Fleet home}) _transferToHomeFleetStoryFixture() {
  const playerId = 'gp_transfer_story';
  const capitalProvince = 'oldWorld|p_transfer_capital';
  const sourceFleetId = 'f_transfer_source';
  const homeFleetId = 'f_transfer_home';

  final game = Game(
    id: 'g_transfer_story',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: capitalProvince,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Capital Port',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(
        id: playerId,
        displayName: 'Catalog Admiral',
        isHuman: true,
        capitalProvinceId: capitalProvince,
      ),
    ],
  );

  final source = Fleet(
    id: sourceFleetId,
    ownerId: playerId,
    regionId: 'oldWorld',
    inPortAtProvinceId: capitalProvince,
    ships: const [
      ShipInstance(id: 'ship_carrack_a', typeId: 'carrack'),
      ShipInstance(id: 'ship_carrack_b', typeId: 'carrack'),
      ShipInstance(id: 'ship_fluyte_a', typeId: 'fluyte'),
    ],
  );
  final home = Fleet(
    id: homeFleetId,
    ownerId: playerId,
    regionId: 'oldWorld',
    inPortAtProvinceId: capitalProvince,
    ships: const [ShipInstance(id: 'ship_carrack_c', typeId: 'carrack')],
  );

  return (game: game, source: source, home: home);
}

/// Transfer to Home Fleet Dialog stories. SPEC/ui/transfer-to-home-fleet-dialog.md.
List<WidgetbookNode> get transferToHomeFleetDialogDirectories => [
  WidgetbookFolder(
    name: 'Transfer to Home Fleet Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — source + home, mixed ship types',
        builder: (context) {
          final fixture = _transferToHomeFleetStoryFixture();
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => TransferToHomeFleetDialog(
                      sourceFleet: fixture.source,
                      homeFleet: fixture.home,
                      game: fixture.game,
                      humanPlayerId: 'gp_transfer_story',
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Transfer to Home Fleet'),
              );
            },
          );
        },
      ),
    ],
  ),
];

/// Production Commodity Breakdown Dialog stories.
/// SPEC/ui/production-commodity-breakdown-dialog.md.
List<WidgetbookNode> get productionCommodityBreakdownDialogDirectories => [
  WidgetbookFolder(
    name: 'Production Commodity Breakdown Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — debug game, mixed deltas',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.firstWhere((p) => p.isHuman).id
              : game.players.first.id;
          final player = game.playerById(humanPlayerId) ?? game.players.first;
          return ProviderScope(
            child: _moveDialogStoryFrame(
              open: (innerContext) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: innerContext,
                      builder: (_) => ProductionCommodityBreakdownDialog(
                        game: game,
                        player: player,
                        topology: result.combinedTopology,
                        tileMapByRegion: result.tileMapByRegion,
                        currentOrders: const Orders(),
                      ),
                    );
                  },
                  // ignore: avoid_hardcoded_strings_in_widgets
                  child: const Text('Open Commodity Breakdown'),
                );
              },
            ),
          );
        },
      ),
    ],
  ),
];

/// Grant or Subsidy Dialog stories. SPEC/ui/grant-or-subsidy-dialog.md.
List<WidgetbookNode> get grantOrSubsidyDialogDirectories => [
  WidgetbookFolder(
    name: 'Grant or Subsidy Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Grant mode — treasury sufficient',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.first.id;
          final targetFactionId = game.players.length >= 2
              ? game.players[1].id
              : (game.minorNations.isNotEmpty
                    ? game.minorNations.first.id
                    : 'm1');
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => GrantOrSubsidyDialog(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: false,
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Grant Aid'),
              );
            },
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Subsidy mode — below minimum',
        builder: (context) {
          final base = getDebugInitGameResult().game;
          final humanPlayerId = base.players.first.id;
          final targetFactionId = base.players.length >= 2
              ? base.players[1].id
              : (base.minorNations.isNotEmpty
                    ? base.minorNations.first.id
                    : 'm1');
          final game = base.copyWith(
            players: [
              base.players.first.copyWith(treasury: 0),
              ...base.players.skip(1),
            ],
          );
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => GrantOrSubsidyDialog(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: true,
                      bus: AppEventBus.create(),
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open Set Subsidy'),
              );
            },
          );
        },
      ),
    ],
  ),
];

/// New Game Leader Selection Dialog stories.
/// SPEC/ui/new-game-leader-selection-dialog.md.
List<WidgetbookNode> get newGameLeaderSelectionDialogDirectories => [
  WidgetbookFolder(
    name: 'New Game Leader Selection Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Default — six slots populated',
        builder: (context) {
          final base = GameSetupConfig.defaultConfig;
          final naming = defaultNamingConfig;
          final initial = <String, String>{};
          for (final gpId in base.selectedGreatPowerIds) {
            final gp = naming.gpById(gpId);
            if (gp != null && gp.leaderVariants.isNotEmpty) {
              initial[gpId] = gp.defaultLeaderVariantId;
            }
          }
          return _moveDialogStoryFrame(
            open: (innerContext) {
              return ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: innerContext,
                    builder: (_) => NewGameLeaderSelectionDialog(
                      baseConfig: base,
                      naming: naming,
                      initialLeaderByGpId: initial,
                      onCancel: () => Navigator.of(innerContext).pop(),
                      onConfirmed: (_, _, _, _, _) {},
                    ),
                  );
                },
                // ignore: avoid_hardcoded_strings_in_widgets
                child: const Text('Open New Game Leader Selection'),
              );
            },
          );
        },
      ),
    ],
  ),
];
