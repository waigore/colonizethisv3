// coverage:ignore-file
// Dev-only Widgetbook catalog part; excluded from app coverage gate via
// instrumentation (matches catalog.dart). Story builders are only exercised
// in the developer-facing Widgetbook app, not in widget unit tests.
part of 'catalog.dart';

class _InlineYarnAssetBundle extends AssetBundle {
  _InlineYarnAssetBundle(this._text);

  final String _text;

  @override
  Future<ByteData> load(String key) {
    final bytes = Uint8List.fromList(utf8.encode(_text));
    return Future.value(
      ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value(_text);
  }
}

const String _kCtDialogueViewStorySource = '''
title: ctdv_story
---
The story begins with a single archaic line.
The narrator pauses, then offers a choice.
-> Continue the tale.
-> Cut the tale short.
===
''';

/// CtDialogueView stories. SPEC/ui/ct-dialogue-view.md.
List<WidgetbookNode> get ctDialogueViewDirectories => [
  WidgetbookFolder(
    name: 'Dialogue Engine',
    children: [
      WidgetbookUseCase(
        name: 'Lines and choice trace',
        builder: (context) => MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: const Scaffold(body: _CtDialogueViewStoryHarness()),
        ),
      ),
    ],
  ),
];

class _CtDialogueViewStoryHarness extends StatefulWidget {
  const _CtDialogueViewStoryHarness();

  @override
  State<_CtDialogueViewStoryHarness> createState() =>
      _CtDialogueViewStoryHarnessState();
}

class _CtDialogueViewStoryHarnessState
    extends State<_CtDialogueViewStoryHarness> {
  CtDialogueView? _view;
  DialogueRunner? _runner;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startDialogue();
  }

  Future<void> _startDialogue() async {
    final project = YarnProject();
    project.parse(_kCtDialogueViewStorySource);
    final view = CtDialogueView();
    final runner = DialogueRunner(
      yarnProject: project,
      dialogueViews: [view],
    );
    view.onStateChanged = (_, _) {
      if (mounted) setState(() {});
    };
    setState(() {
      _view = view;
      _runner = runner;
    });
    await runner.startDialogue('ctdv_story');
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    if (view == null || _runner == null) {
      return const CtLoadingIndicator();
    }
    if (_finished) {
      return const Center(child: Icon(Icons.check_circle, size: 32));
    }
    final line = view.currentLine;
    final choice = view.currentChoice;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line != null) ...[
            Text(line.text),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: view.advanceLine,
              child: const Icon(Icons.arrow_forward),
            ),
          ] else if (choice != null) ...[
            for (var i = 0; i < choice.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () => view.selectOption(i),
                  child: Text(choice.options[i].text),
                ),
              ),
          ] else
            const CtLoadingIndicator(),
        ],
      ),
    );
  }
}

const String _kGameStartIntroOverlayStorySource = '''
title: game_start_intro
---
The age of imperialism draweth nigh.
-> I shall.
===
''';

/// Game Start Intro Overlay stories. SPEC/ui/game-start-intro-overlay.md.
List<WidgetbookNode> get gameStartIntroOverlayDirectories => [
  WidgetbookFolder(
    name: 'Game Start Intro Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Default — single-line intro',
        builder: (context) => MaterialApp(
          theme: AppThemes.editorialMonocle,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GameStartIntroOverlay(
              onDismissed: () {},
              assetBundle: _InlineYarnAssetBundle(
                _kGameStartIntroOverlayStorySource,
              ),
              child: const Placeholder(),
            ),
          ),
        ),
      ),
    ],
  ),
];

Game _overtureStoryGame() {
  return const Game(
    id: 'wb_overture',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_player',
        displayName: 'Player',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

/// Overture Dialogue Overlay stories. SPEC/ui/overture-dialogue-overlay.md.
List<WidgetbookNode> get overtureDialogueOverlayDirectories => [
  WidgetbookFolder(
    name: 'Overture Dialogue Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Default — two pending overtures',
        builder: (context) => MaterialApp(
          theme: AppThemes.editorialMonocle,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OvertureDialogueOverlay(
              game: _overtureStoryGame(),
              pendingOvertures: const [
                OvertureOffer(
                  offererGpId: 'gp_spain',
                  targetFactionId: 'gp_player',
                  stage: OvertureStage.tradeConsulate,
                ),
                OvertureOffer(
                  offererGpId: 'gp_portugal',
                  targetFactionId: 'gp_player',
                  stage: OvertureStage.embassy,
                ),
              ],
              skipIntroForTest: true,
              onDecisions: (_) {},
              child: Center(
                child: Text(appL10n(context).widgetbook_gameShell),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
];

Game _callToArmsStoryGame() {
  return const Game(
    id: 'wb_cta',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp_spain', displayName: 'Spain', isHuman: false, treasury: 0),
      Player(
        id: 'gp_portugal',
        displayName: 'Portugal',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_france',
        displayName: 'France',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_england',
        displayName: 'England',
        isHuman: false,
        treasury: 0,
      ),
      Player(
        id: 'gp_player',
        displayName: 'Player',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

/// Call to Arms Dialogue Overlay stories. SPEC/ui/call-to-arms-dialogue-overlay.md.
List<WidgetbookNode> get callToArmsDialogueOverlayDirectories => [
  WidgetbookFolder(
    name: 'Call to Arms Dialogue Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Default — two pending calls',
        builder: (context) => MaterialApp(
          theme: AppThemes.editorialMonocle,
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CallToArmsDialogueOverlay(
              game: _callToArmsStoryGame(),
              pending: const [
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_portugal',
                  aggressorGpId: 'gp_spain',
                ),
                CallToArmsPending(
                  allyGpId: 'gp_player',
                  defenderGpId: 'gp_france',
                  aggressorGpId: 'gp_england',
                ),
              ],
              onDecisions: (_) {},
              child: Center(
                child: Text(appL10n(context).widgetbook_gameShell),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
];

MaterialApp _moveDialogStoryFrame({required Widget Function(BuildContext) open}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
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
                      barrierColor: EditorialMonoclePalette.dialogScrim,
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
