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
          final player = game.players.firstWhere((p) => p.id == humanPlayerId);
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
    final parts = tileKey.split('|');
    if (parts.length < 4) return null;
    return '${parts[0]}|${parts[1]}';
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
