// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

/// Pause menu panel stories. SPEC/ui/pause-menu-panel.md.
///
/// Renders [PauseMenuPanel] inside a plain [Scaffold] body so the catalog can
/// preview the row layout without the modal bottom-sheet scrim that
/// [AppEventHandler] uses in production.
class _PauseMenuPanelStoryHost extends StatefulWidget {
  const _PauseMenuPanelStoryHost();

  @override
  State<_PauseMenuPanelStoryHost> createState() =>
      _PauseMenuPanelStoryHostState();
}

class _PauseMenuPanelStoryHostState extends State<_PauseMenuPanelStoryHost> {
  late final AppEventBus _bus;

  @override
  void initState() {
    super.initState();
    _bus = AppEventBus.create();
  }

  @override
  void dispose() {
    _bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PauseMenuPanel(bus: _bus),
          ),
        ),
      ),
    );
  }
}

/// Pause menu panel stories. SPEC/ui/pause-menu-panel.md.
List<WidgetbookNode> get pauseMenuPanelDirectories => [
  WidgetbookFolder(
    name: 'Pause Menu Panel',
    children: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) => const _PauseMenuPanelStoryHost(),
      ),
    ],
  ),
];

/// Hosts [GameSideMenu] in a [Stack] so the [Positioned] body has bounded
/// constraints, matching how [GameMapArea] mounts the drawer in production.
class _GameSideMenuStoryHost extends StatefulWidget {
  const _GameSideMenuStoryHost({required this.initialOpen});

  final bool initialOpen;

  @override
  State<_GameSideMenuStoryHost> createState() => _GameSideMenuStoryHostState();
}

class _GameSideMenuStoryHostState extends State<_GameSideMenuStoryHost> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black12),
            ),
            GameSideMenu(
              sideMenuOpen: _open,
              onClose: () => setState(() => _open = false),
            ),
          ],
        ),
      ),
    );
  }
}

ProviderScope _gameSideMenuProviderScope({required bool initialOpen}) {
  final game = getDebugInitGameResult().game;
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    ],
    child: _GameSideMenuStoryHost(initialOpen: initialOpen),
  );
}

/// Game side menu stories. SPEC/ui/game-side-menu.md.
List<WidgetbookNode> get gameSideMenuDirectories => [
  WidgetbookFolder(
    name: 'Game Side Menu',
    children: [
      WidgetbookUseCase(
        name: 'Default — open',
        builder: (context) => _gameSideMenuProviderScope(initialOpen: true),
      ),
      WidgetbookUseCase(
        name: 'Closed',
        builder: (context) => _gameSideMenuProviderScope(initialOpen: false),
      ),
    ],
  ),
];

/// Hosts [GameMapNarrowDetailOverlaySlot] with the map panel provider opened on a
/// sample tile. SPEC/ui/game-map-narrow-detail-overlay-slot.md.
class _GameMapNarrowDetailOverlaySlotStoryHost extends ConsumerStatefulWidget {
  const _GameMapNarrowDetailOverlaySlotStoryHost();

  @override
  ConsumerState<_GameMapNarrowDetailOverlaySlotStoryHost> createState() =>
      _GameMapNarrowDetailOverlaySlotStoryHostState();
}

class _GameMapNarrowDetailOverlaySlotStoryHostState
    extends ConsumerState<_GameMapNarrowDetailOverlaySlotStoryHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(mapProvincePanelProvider.notifier)
          .reportMapTileTapped(sampleTileKeyForProvinceOverlay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    return MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 600)),
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.black12)),
              Align(
                alignment: Alignment.bottomCenter,
                child: GameMapNarrowDetailOverlaySlot(
                  game: game,
                  region: region,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                  workTargetSelectionCache:
                      PerPlayerWorkTargetSelectionCache(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ProviderScope _gameMapNarrowDetailOverlaySlotProviderScope() {
  return ProviderScope(
    child: const _GameMapNarrowDetailOverlaySlotStoryHost(),
  );
}

/// Game map narrow detail overlay slot stories.
List<WidgetbookNode> get gameMapNarrowDetailOverlaySlotDirectories => [
  WidgetbookFolder(
    name: 'Game Map Narrow Detail Overlay Slot',
    children: [
      WidgetbookUseCase(
        name: 'Default — province open',
        builder: (context) => _gameMapNarrowDetailOverlaySlotProviderScope(),
      ),
    ],
  ),
];

Game _diplomacyDetailStoryGame() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  return Game(
    id: 'wb_diplomacy_detail',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: humanId,
        displayName: 'England',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: rivalId,
        displayName: 'Spain',
        isHuman: false,
        treasury: 0,
      ),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: humanId,
        factionId2: rivalId,
        score: 70,
        state: RelationState.atPeace,
      ),
    ],
    diplomaticHistoryEvents: [
      DiplomaticEvent(
        turn: 2,
        intraTurnIndex: 0,
        type: DiplomaticEventType.overtureAccepted,
        participants: {humanId, rivalId},
        fromFactionId: humanId,
        toFactionId: rivalId,
        overtureStage: OvertureStage.embassy,
      ),
    ],
    dossierEvidenceEntries: [
      DossierEvidenceEntry(
        observerId: humanId,
        subjectId: rivalId,
        agendaType: 'trade_focus',
        turnNumber: 2,
        description: 'Favoured trade over military buildup.',
      ),
    ],
  );
}

ProviderScope _diplomacyDetailScreenProviderScope() {
  const humanId = 'gp_human';
  const rivalId = 'gp_rival';
  final game = _diplomacyDetailStoryGame();
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ],
    child: MaterialApp(
      theme: AppThemes.colonial,
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DiplomacyDetailScreen(
        game: game,
        humanPlayerId: humanId,
        factionId: rivalId,
        factionDisplayName: 'Spain',
        kind: FactionKind.greatPower,
        relation: game.diplomacyRelations.first,
      ),
    ),
  );
}

/// Diplomacy detail screen stories. SPEC/ui/diplomacy-detail-screen.md.
List<WidgetbookNode> get diplomacyDetailScreenDirectories => [
  WidgetbookFolder(
    name: 'Diplomacy Detail Screen',
    children: [
      WidgetbookUseCase(
        name: 'Default — GP with history and dossier',
        builder: (context) => _diplomacyDetailScreenProviderScope(),
      ),
    ],
  ),
];

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
