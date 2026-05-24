part of 'catalog.dart';

List<WidgetbookNode> get trainMilitaryDialogDirectories => [
  WidgetbookFolder(
    name: 'Train Military Dialog',
    children: [
      WidgetbookUseCase(
        name: 'Standalone',
        builder: (context) {
          final result = getDebugInitGameResult();
          final game = result.game;
          final humanPlayerId = game.players.isNotEmpty
              ? game.players.firstWhere((p) => p.isHuman).id
              : game.players.first.id;
          final player = game.playerById(humanPlayerId) ?? game.players.first;
          final richGame = game.copyWith(
            players: [
              player.copyWith(
                treasury: 10000,
                workerPool: player.workerPool.copyWith(peasants: 20),
                stockpile: player.stockpile.merge(
                  const Stockpile(
                    quantities: {
                      'fabric': 50,
                      'castIron': 50,
                      'lumber': 50,
                      'horses': 50,
                      'steel': 50,
                      'bronze': 50,
                    },
                  ),
                ),
              ),
              ...game.players.where((p) => p.id != humanPlayerId),
            ],
          );
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: TrainMilitaryDialog(
                  game: richGame,
                  humanPlayerId: humanPlayerId,
                  currentOrders: const Orders(),
                  bus: AppEventBus.create(),
                ),
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Naval Units Panel + map in tandem. SPEC/ui/naval-units-panel.md.
class _NavalPanelWithMapStory extends StatefulWidget {
  const _NavalPanelWithMapStory();

  @override
  State<_NavalPanelWithMapStory> createState() =>
      _NavalPanelWithMapStoryState();
}

class _NavalPanelWithMapStoryState extends State<_NavalPanelWithMapStory> {
  int _regionIndex = 0;
  String? _secondaryHighlightTileKey;
  String? _centerOnTileKey;
  bool _showProvinceNames = true;
  late Game _game;
  late MapTopology _combinedTopology;
  late AppEventBus _navalBus;
  StreamSubscription<NavalFleetsUpdatedEvent>? _navalSub;
  StreamSubscription<NavalSplitFleetRequestedEvent>? _navalSplitSub;

  @override
  void initState() {
    super.initState();
    final result = getDebugInitGameResult();
    _game = result.game;
    _combinedTopology = result.combinedTopology;
    _navalBus = AppEventBus.create();
    _navalSub = _navalBus.on<NavalFleetsUpdatedEvent>().listen((e) {
      if (!mounted) return;
      setState(() => _game = e.game);
    });
    _navalSplitSub = _navalBus.on<NavalSplitFleetRequestedEvent>().listen((e) {
      final next = applyNavalSplitFleet(
        game: _game,
        humanPlayerId: e.humanPlayerId,
        originalFleetId: e.originalFleetId,
        shipInstanceIdsToNewFleet: e.shipInstanceIdsToNewFleet,
      );
      _navalBus.emit(NavalFleetsUpdatedEvent(game: next));
    });
  }

  @override
  void dispose() {
    _navalSub?.cancel();
    _navalSplitSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final mapViewData = result.mapViewData;
    final humanPlayerId = _game.players.isNotEmpty
        ? _game.players.first.id
        : 'gp1';
    final region = _regionIndex == 0
        ? mapViewData.oldWorld
        : mapViewData.newWorld;
    return SizedBox(
      width: 900,
      height: 550,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: Text(appL10n(context).region_oldWorld),
                        selected: _regionIndex == 0,
                        onSelected: (_) => setState(() => _regionIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(appL10n(context).region_newWorld),
                        selected: _regionIndex == 1,
                        onSelected: (_) => setState(() => _regionIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          appL10n(context).map_displayOptions_showProvinceNames,
                        ),
                        selected: _showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = true),
                      ),
                      ChoiceChip(
                        label: Text(appL10n(context).mapDebug_noNames),
                        selected: !_showProvinceNames,
                        onSelected: (_) =>
                            setState(() => _showProvinceNames = false),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CtRegionMap(
                    region: region,
                    cellSizePx: 24,
                    showProvinceNamesLayer: _showProvinceNames,
                    onProvinceSelected: (_) {},
                    secondaryHighlightTileKey: _secondaryHighlightTileKey,
                    centerOnTileKey: _centerOnTileKey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 360,
            child: NavalUnitsPanel(
              game: _game,
              humanPlayerId: humanPlayerId,
              bus: _navalBus,
              topology: _combinedTopology,
            ),
          ),
        ],
      ),
    );
  }
}

/// Map + overlay in tandem for Widgetbook. SPEC/ui/province-sea-zone-detail-overlay.md.
class _MapWithOverlayStory extends StatefulWidget {
  const _MapWithOverlayStory({required this.selectedId});

  final String selectedId;

  @override
  State<_MapWithOverlayStory> createState() => _MapWithOverlayStoryState();
}

class _MapWithOverlayStoryState extends State<_MapWithOverlayStory> {
  late String? _selectedTileKey;
  String? _secondaryHighlightTileKey;
  var _overlayOpen = true;
  CtMapVisibilityMode _visibilityMode = CtMapVisibilityMode.full;
  bool _showProvinceNames = true;

  String? _displayIdFromTile(String? tileKey) {
    if (tileKey == null) return null;
    return tryParseTileKey(tileKey)?.prefixedProvinceId;
  }

  @override
  void initState() {
    super.initState();
    final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
    final region = mapViewData.oldWorld;
    final game = getDebugInitGameResult().game;
    final tiles = game
        .worldState
        .tileKeysByRegionAndProvince[region.regionId]?[widget.selectedId];
    if (tiles != null && tiles.isNotEmpty) {
      _selectedTileKey = tiles.first;
    } else {
      final cell = region.cells.firstWhere(
        (c) => '${region.regionId}|${c.regionCellId}' == widget.selectedId,
      );
      _selectedTileKey =
          '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    }
  }

  @override
  void didUpdateWidget(covariant _MapWithOverlayStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
      final region = mapViewData.oldWorld;
      final game = getDebugInitGameResult().game;
      final tiles = game
          .worldState
          .tileKeysByRegionAndProvince[region.regionId]?[widget.selectedId];
      if (tiles != null && tiles.isNotEmpty) {
        _selectedTileKey = tiles.first;
      } else {
        final cell = region.cells.firstWhere(
          (c) => '${region.regionId}|${c.regionCellId}' == widget.selectedId,
        );
        _selectedTileKey =
            '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
      }
      _overlayOpen = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initResult = getDebugInitGameResult();
    final game = initResult.game;
    final playerView = buildPlayerView(
      game,
      initResult.combinedTopology,
      'gp1',
    );
    final mapViewData = debugMapViewDataWithVisibilityForFirstPlayer();
    final region = mapViewData.oldWorld;
    final displayId = _displayIdFromTile(_selectedTileKey) ?? widget.selectedId;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight > 0
            ? constraints.maxHeight
            : 500.0;
        final overlayHeight = totalHeight / 2;
        return SizedBox(
          width: 800,
          height: totalHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChoiceChip(
                      label: Text(appL10n(context).mapDebug_fullVisibility),
                      selected: _visibilityMode == CtMapVisibilityMode.full,
                      onSelected: (_) {
                        setState(() {
                          _visibilityMode = CtMapVisibilityMode.full;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(appL10n(context).mapDebug_playerConstrained),
                      selected:
                          _visibilityMode ==
                          CtMapVisibilityMode.playerConstrained,
                      onSelected: (_) {
                        setState(() {
                          _visibilityMode =
                              CtMapVisibilityMode.playerConstrained;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        appL10n(context).map_displayOptions_showProvinceNames,
                      ),
                      selected: _showProvinceNames,
                      onSelected: (_) =>
                          setState(() => _showProvinceNames = true),
                    ),
                    ChoiceChip(
                      label: Text(appL10n(context).mapDebug_noNames),
                      selected: !_showProvinceNames,
                      onSelected: (_) =>
                          setState(() => _showProvinceNames = false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CtRegionMap(
                        region: region,
                        cellSizePx: 28,
                        visibilityMode: _visibilityMode,
                        playerViewForResources:
                            _visibilityMode ==
                                CtMapVisibilityMode.playerConstrained
                            ? playerView
                            : null,
                        showProvinceNamesLayer: _showProvinceNames,
                        onProvinceSelected: null,
                        onMapTileTappedForDetail: (tk) => setState(() {
                          _selectedTileKey = tk;
                          _overlayOpen = true;
                        }),
                        selectedTileKey: _selectedTileKey,
                        secondaryHighlightTileKey: _secondaryHighlightTileKey,
                      ),
                    ),
                    if (_overlayOpen && _selectedTileKey != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: overlayHeight,
                          width: double.infinity,
                          child: ProvinceSeaZoneDetailOverlay(
                            game: game,
                            region: region,
                            displayId: displayId,
                            selectedTileKey: _selectedTileKey,
                            humanPlayerId: 'gp1',
                            playerView: playerView,
                            onHighlightTile: (k) =>
                                setState(() => _secondaryHighlightTileKey = k),
                            onClose: () => setState(() {
                              _overlayOpen = false;
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

VictoryState _sampleVictoryState(Game game) {
  return VictoryState(
    winnerPlayerId: game.players.first.id,
    type: VictoryType.military,
    turnNumber: 45,
  );
}

QuickBattleInput _sampleQuickBattleInput() {
  return const QuickBattleInput(
    attackerFactionId: 'castile',
    defenderFactionId: 'england',
    provinceId: 'oldWorld|p_lisbon',
    regionId: 'oldWorld',
    attackerDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: ['a1', 'a2', 'a3', 'a4'],
          cohesion: 3,
        ),
      ],
    ),
    defenderDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: ['d1', 'd2', 'd3'],
          cohesion: 3,
        ),
      ],
    ),
    maxRounds: 3,
    seed: 1,
  );
}

MaterialApp _victoryStoryFrame(Widget child) {
  return MaterialApp(
    theme: AppThemes.colonial,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

MaterialApp _combatStoryFrame(Widget child) {
  return MaterialApp(
    theme: AppThemes.colonial,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Victory overlay stories. SPEC/ui/victory-overlay.md.
List<WidgetbookNode> get victoryUiDirectories => [
  WidgetbookFolder(
    name: 'Victory',
    children: [
      WidgetbookUseCase(
        name: 'Victory panel — military',
        builder: (context) {
          final game = getDebugInitGameResult().game;
          final victory = _sampleVictoryState(game);
          return _victoryStoryFrame(
            VictoryPanel(
              game: game,
              victory: victory,
              bus: AppEventBus.create(),
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Victory overlay — full scrim',
        builder: (context) {
          final game = getDebugInitGameResult().game;
          final victory = _sampleVictoryState(game);
          return _victoryStoryFrame(
            SizedBox(
              width: 400,
              height: 560,
              child: Stack(
                children: [
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  VictoryOverlay(
                    game: game,
                    victory: victory,
                    bus: AppEventBus.create(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  ),
];

/// Combat UI stories.
/// SPEC/ui/quick-battle-screen.md, quick-battle-deployment-view.md,
/// quick-battle-action-selector.md, combat-mode-choice-dialog.md,
/// quick-battle-result-dialog.md.
List<WidgetbookNode> get combatUiDirectories => [
  WidgetbookFolder(
    name: 'Quick Battle',
    children: [
      WidgetbookUseCase(
        name: 'Quick Battle Screen — non-interactive',
        builder: (context) => _combatStoryFrame(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: QuickBattleScreen(
              input: _sampleQuickBattleInput(),
              onComplete: (_) {},
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Quick Battle Screen — interactive',
        builder: (context) => _combatStoryFrame(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: QuickBattleScreen(
              input: _sampleQuickBattleInput(),
              onComplete: (_) {},
              interactive: true,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Deployment view',
        builder: (context) => _combatStoryFrame(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: QuickBattleDeploymentView(
                attackerDeployment: QuickBattleDeployment(
                  groups: [
                    QuickBattleGroup(
                      lane: QuickBattleLane.center,
                      line: QuickBattleLine.front,
                      unitIds: ['a1', 'a2', 'a3', 'a4'],
                      cohesion: 3,
                    ),
                  ],
                ),
                defenderDeployment: QuickBattleDeployment(
                  groups: [
                    QuickBattleGroup(
                      lane: QuickBattleLane.center,
                      line: QuickBattleLine.front,
                      unitIds: ['d1', 'd2', 'd3'],
                      cohesion: 2,
                    ),
                  ],
                ),
                attackerName: 'Castile',
                defenderName: 'England',
              ),
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Action selector — full CP',
        builder: (context) => _combatStoryFrame(
          Padding(
            padding: const EdgeInsets.all(16),
            child: QuickBattleActionSelector(
              cpRemaining: 3,
              onActionSelected: (_) {},
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Action selector — 1 CP (assault disabled)',
        builder: (context) => _combatStoryFrame(
          Padding(
            padding: const EdgeInsets.all(16),
            child: QuickBattleActionSelector(
              cpRemaining: 1,
              onActionSelected: (_) {},
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Action selector — spent (0 CP)',
        builder: (context) => _combatStoryFrame(
          Padding(
            padding: const EdgeInsets.all(16),
            child: QuickBattleActionSelector(
              cpRemaining: 0,
              onActionSelected: (_) {},
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Combat mode choice — regular province',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Lisbon',
            isCapitalSiege: false,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Combat mode choice — capital siege',
        builder: (context) => _combatStoryFrame(
          CombatModeChoiceDialog(
            bus: AppEventBus.create(),
            provinceName: 'Madrid',
            isCapitalSiege: true,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Quick Battle result — attacker wins, province flips',
        builder: (context) => _combatStoryFrame(
          const QuickBattleResultDialog(
            result: QuickBattleResult(
              winner: QuickBattleWinner.attacker,
              attackerCasualties: ['a3'],
              defenderCasualties: ['d1', 'd2'],
              provinceFlips: true,
            ),
            attackerName: 'Castile',
            defenderName: 'England',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Quick Battle result — defender holds',
        builder: (context) => _combatStoryFrame(
          const QuickBattleResultDialog(
            result: QuickBattleResult(
              winner: QuickBattleWinner.defender,
              attackerCasualties: ['a1', 'a2', 'a3'],
              defenderCasualties: ['d1'],
              provinceFlips: false,
            ),
            attackerName: 'Castile',
            defenderName: 'England',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Quick Battle result — mutual exhaustion',
        builder: (context) => _combatStoryFrame(
          const QuickBattleResultDialog(
            result: QuickBattleResult(
              winner: QuickBattleWinner.mutualExhaustion,
              attackerCasualties: ['a1'],
              defenderCasualties: ['d1'],
              provinceFlips: false,
            ),
            attackerName: 'Castile',
            defenderName: 'England',
          ),
        ),
      ),
    ],
  ),
];

Widget _shellOrGameStoryFrame({required Widget child, Object? navigatorKey}) {
  return MaterialApp(
    navigatorKey: navigatorKey is GlobalKey<NavigatorState> ? navigatorKey : null,
    theme: AppThemes.colonial,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

ProviderScope _shellScreenProviderScope({required bool autoSaveAvailable}) {
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      mainMenuAutoSaveAvailableProvider.overrideWith((ref) => autoSaveAvailable),
    ],
    child: _shellOrGameStoryFrame(child: const ShellScreen()),
  );
}

/// Shell screen stories. SPEC/ui/shell-screen.md.
List<WidgetbookNode> get shellScreenDirectories => [
  WidgetbookFolder(
    name: 'Shell Screen',
    children: [
      WidgetbookUseCase(
        name: 'Default — no auto-save',
        builder: (context) =>
            _shellScreenProviderScope(autoSaveAvailable: false),
      ),
      WidgetbookUseCase(
        name: 'Auto-save available',
        builder: (context) =>
            _shellScreenProviderScope(autoSaveAvailable: true),
      ),
    ],
  ),
];

ProviderScope _gameScreenProviderScope({
  required Game game,
  required bool victory,
}) {
  final activeGame = victory
      ? game.copyWith(
          victory: VictoryState(
            winnerPlayerId: game.players.first.id,
            type: VictoryType.military,
            turnNumber: 45,
          ),
        )
      : game;
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
      currentGameProvider.overrideWith(() => CurrentGameNotifier(activeGame)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      mapViewDataProvider.overrideWith((ref) => null),
      gameIdsWithIntroShownProvider.overrideWith(
        () => GameIdsWithIntroShownNotifier({activeGame.id}),
      ),
    ],
    child: _shellOrGameStoryFrame(child: const GameScreen()),
  );
}

/// Game screen stories. SPEC/ui/game-screen.md.
List<WidgetbookNode> get gameScreenDirectories => [
  WidgetbookFolder(
    name: 'Game Screen',
    children: [
      WidgetbookUseCase(
        name: 'Default — no victory',
        builder: (context) {
          final game = getDebugInitGameResult().game;
          return _gameScreenProviderScope(game: game, victory: false);
        },
      ),
      WidgetbookUseCase(
        name: 'Victory',
        builder: (context) {
          final game = getDebugInitGameResult().game;
          return _gameScreenProviderScope(game: game, victory: true);
        },
      ),
    ],
  ),
];
