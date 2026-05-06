part of 'catalog.dart';

List<WidgetbookNode> get provinceOverlayDirectories => [
  WidgetbookFolder(
    name: 'Province Overlay',
    children: [
      WidgetbookUseCase(
        name: 'Standalone — province',
        builder: (context) {
          final game = demoGameForOverlay;
          final region = demoRegionForOverlay;
          return SizedBox(
            width: 320,
            height: 400,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              onClose: () {},
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Standalone — sea zone',
        builder: (context) {
          final game = demoGameForOverlay;
          final region = demoRegionForOverlay;
          return SizedBox(
            width: 320,
            height: 280,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: sampleSeaZoneIdForOverlay,
              selectedTileKey: null,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              onClose: () {},
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Standalone (mobile)',
        builder: (context) => mobileViewport(
          context,
          Builder(
            builder: (context) {
              final game = demoGameForOverlay;
              final region = demoRegionForOverlay;
              return ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: sampleProvinceIdForOverlay,
                selectedTileKey: sampleTileKeyForProvinceOverlay,
                humanPlayerId: game.players.first.id,
                playerView: demoHumanPlayerViewForOverlay,
                onClose: () {},
              );
            },
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'With map — province selected',
        builder: (context) =>
            _MapWithOverlayStory(selectedId: sampleProvinceIdForOverlay),
      ),
      WidgetbookUseCase(
        name: 'With map — sea zone selected',
        builder: (context) =>
            _MapWithOverlayStory(selectedId: sampleSeaZoneIdForOverlay),
      ),
    ],
  ),
];

/// Production panel with local state for Widgetbook. SPEC/ui/production-panel.md.
class _ProductionPanelStory extends StatefulWidget {
  const _ProductionPanelStory({
    this.playerOverride,
    this.useFullAvailability = true,
  });

  /// When set, used instead of the full/partial demo player.
  final Player? playerOverride;

  /// When true, use full-availability demo player; when false, partial.
  final bool useFullAvailability;

  @override
  State<_ProductionPanelStory> createState() => _ProductionPanelStoryState();
}

class _ProductionPanelStoryState extends State<_ProductionPanelStory> {
  Map<String, int> _desiredOutputByRecipe = const {};

  @override
  Widget build(BuildContext context) {
    final game = demoGameForOverlay;
    final player =
        widget.playerOverride ??
        (widget.useFullAvailability
            ? fullAvailabilityProductionPlayer()
            : partialAvailabilityProductionPlayer());
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: _desiredOutputByRecipe,
        netDeltasByCommodity: const {},
        onDesiredOutputChanged: (next) =>
            setState(() => _desiredOutputByRecipe = next),
      ),
    );
  }
}

/// Civilian Units Panel + map in tandem. SPEC/ui/civilian-units-panel.md.
/// Demonstrates assign (order menu → valid tiles glow → tile click) and cancel with real game/map.
class _CivilianPanelWithMapStory extends StatefulWidget {
  const _CivilianPanelWithMapStory();

  @override
  State<_CivilianPanelWithMapStory> createState() =>
      _CivilianPanelWithMapStoryState();
}

class _CivilianPanelWithMapStoryState
    extends State<_CivilianPanelWithMapStory> {
  late Game _game;
  late AppEventBus _panelBus;
  final List<StreamSubscription<dynamic>> _sessionCommandSubs = [];
  Orders _orders = const Orders();
  int _regionIndex = 0;
  String? _secondaryHighlightTileKey;
  String? _centerOnTileKey;
  ({Unit unit, String workTarget})? _workTargetSelection;
  CtMapVisibilityMode _visibilityMode = CtMapVisibilityMode.full;
  bool _showProvinceNames = true;
  Set<String>? _cachedValidTileKeys;
  String? _cachedWorkTargetSelection;

  @override
  void initState() {
    super.initState();
    _game = getDebugInitGameResult().game;
    _panelBus = AppEventBus.create();
    _sessionCommandSubs.addAll([
      _panelBus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
        if (!mounted) return;
        setState(() {
          _orders = removePendingWorkOrderAt(_orders, e.playerId, e.index);
        });
      }),
      _panelBus.on<CancelInProgressCivilianWorkRequestedEvent>().listen((e) {
        if (!mounted) return;
        setState(() {
          _game = clearUnitCurrentWork(_game, e.unitId);
        });
      }),
    ]);
  }

  @override
  void dispose() {
    for (final sub in _sessionCommandSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  String get _humanPlayerId =>
      _game.players.isNotEmpty ? _game.players.first.id : 'gp1';

  String? get _validTileKeysCacheKey {
    if (_workTargetSelection == null) return null;
    return '${_workTargetSelection!.unit.id}|${_workTargetSelection!.workTarget}|$_visibilityMode';
  }

  Set<String>? get _validTileKeys {
    if (_workTargetSelection == null) return null;
    final cacheKey = _validTileKeysCacheKey;
    if (_cachedWorkTargetSelection == cacheKey &&
        _cachedValidTileKeys != null) {
      return _cachedValidTileKeys;
    }
    final result = getDebugInitGameResult();

    Set<String> valid;
    if (_visibilityMode == CtMapVisibilityMode.playerConstrained) {
      final view = buildPlayerView(
        _game,
        result.combinedTopology,
        _humanPlayerId,
      );
      valid = getValidWorkOrderTileKeysWithVisibility(
        game: _game,
        topology: result.combinedTopology,
        view: view,
        unitId: _workTargetSelection!.unit.id,
        workTarget: _workTargetSelection!.workTarget,
        currentOrders: _orders,
        tileMapByRegion: result.tileMapByRegion,
      );
    } else {
      valid = getValidWorkOrderTileKeys(
        _game,
        result.combinedTopology,
        _humanPlayerId,
        _workTargetSelection!.unit.id,
        _workTargetSelection!.workTarget,
        _orders,
        tileMapByRegion: result.tileMapByRegion,
      );
    }

    _cachedValidTileKeys = valid;
    _cachedWorkTargetSelection = cacheKey;
    return valid;
  }

  void _onTileSelectedForWork(String tileKey) {
    final sel = _workTargetSelection;
    if (sel == null) {
      return;
    }
    final target = sel.workTarget;
    String targetTileKey = tileKey;
    if (target == kWorkTargetExplore ||
        target == kWorkTargetStealTech ||
        target == kWorkTargetCounterSpy) {
      final parts = tileKey.split('|');
      if (parts.length >= 2) {
        targetTileKey = '${parts[0]}|${parts[1]}|0|0';
      }
    }
    final workOrder = WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    setState(() {
      final existing =
          _orders.workOrdersByPlayerId[_humanPlayerId] ?? const <WorkOrder>[];
      final list = <WorkOrder>[...existing, workOrder];
      _orders = _orders.copyWith(
        workOrdersByPlayerId: {
          ..._orders.workOrdersByPlayerId,
          _humanPlayerId: list,
        },
      );
      _workTargetSelection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseResult = getDebugInitGameResult();
    final mapViewData = _visibilityMode == CtMapVisibilityMode.playerConstrained
        ? debugMapViewDataWithVisibilityForFirstPlayer()
        : baseResult.mapViewData;
    final region = _regionIndex == 0
        ? mapViewData.oldWorld
        : mapViewData.newWorld;
    // Panel at bottom, like province overlay "With map" story. SPEC/ui/civilian-units-panel.md.
    const panelHeight = 220.0;
    return civilianUnitsPanelWithRiverpod(
      game: _game,
      child: SizedBox(
        width: 900,
        height: 550,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  CtChoiceChip(
                    label: Text(appL10n(context).region_oldWorld),
                    selected: _regionIndex == 0,
                    onSelected: (_) => setState(() => _regionIndex = 0),
                  ),
                  CtChoiceChip(
                    label: Text(appL10n(context).region_newWorld),
                    selected: _regionIndex == 1,
                    onSelected: (_) => setState(() => _regionIndex = 1),
                  ),
                  CtChoiceChip(
                    label: Text(appL10n(context).mapDebug_fullVisibility),
                    selected: _visibilityMode == CtMapVisibilityMode.full,
                    onSelected: (_) => setState(
                      () => _visibilityMode = CtMapVisibilityMode.full,
                    ),
                  ),
                  CtChoiceChip(
                    label: Text(appL10n(context).mapDebug_playerConstrained),
                    selected:
                        _visibilityMode ==
                        CtMapVisibilityMode.playerConstrained,
                    onSelected: (_) => setState(
                      () => _visibilityMode =
                          CtMapVisibilityMode.playerConstrained,
                    ),
                  ),
                  CtChoiceChip(
                    label: Text(
                      appL10n(context).map_displayOptions_showProvinceNames,
                    ),
                    selected: _showProvinceNames,
                    onSelected: (_) =>
                        setState(() => _showProvinceNames = true),
                  ),
                  CtChoiceChip(
                    label: Text(appL10n(context).mapDebug_hideProvinceNames),
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
                visibilityMode: _visibilityMode,
                playerViewForResources:
                    _visibilityMode == CtMapVisibilityMode.playerConstrained
                    ? debugPlayerViewForFirstPlayer()
                    : null,
                showProvinceNamesLayer: _showProvinceNames,
                onProvinceSelected: (_) {},
                secondaryHighlightTileKey: _secondaryHighlightTileKey,
                centerOnTileKey: _centerOnTileKey,
                validTileKeys: _validTileKeys,
                onTileSelected: _workTargetSelection != null
                    ? _onTileSelectedForWork
                    : null,
                onWorkTargetSelectionCancelled: _workTargetSelection != null
                    ? () => setState(() => _workTargetSelection = null)
                    : null,
              ),
            ),
            SizedBox(
              height: panelHeight,
              child: CivilianUnitsPanel(
                game: _game,
                humanPlayerId: _humanPlayerId,
                currentOrders: _orders,
                bus: _panelBus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Civilian Units Panel opened as bottom sheet (slide up from bottom). SPEC/ui/civilian-units-panel.md.
class _CivilianPanelAsBottomSheetStory extends StatelessWidget {
  const _CivilianPanelAsBottomSheetStory();

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final game = result.game;
    final humanPlayerId = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
    return civilianUnitsPanelWithRiverpod(
      game: game,
      child: _CivilianPanelBottomSheetDemoLayout(
        game: game,
        humanPlayerId: humanPlayerId,
      ),
    );
  }
}

class _CivilianPanelBottomSheetDemoLayout extends StatelessWidget {
  const _CivilianPanelBottomSheetDemoLayout({
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: CtNinePatchButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final maxHeight = MediaQuery.sizeOf(ctx).height * 0.5;
                    return civilianUnitsPanelWithRiverpod(
                      game: game,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        child: CivilianUnitsPanel(
                          game: game,
                          humanPlayerId: humanPlayerId,
                          bus: AppEventBus(),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(appL10n(context).civilian_units_title),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFE0E0E0),
              child: Center(
                child: Text(
                  appL10n(context).widgetbook_openPanelHint,
                  style: const TextStyle(color: Color(0xFF616161)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Military Units Panel + map in tandem. SPEC/ui/military-units-panel.md.
class _MilitaryPanelWithMapStory extends StatefulWidget {
  const _MilitaryPanelWithMapStory();

  @override
  State<_MilitaryPanelWithMapStory> createState() =>
      _MilitaryPanelWithMapStoryState();
}

class _MilitaryPanelWithMapStoryState
    extends State<_MilitaryPanelWithMapStory> {
  int _regionIndex = 0;
  String? _secondaryHighlightTileKey;
  String? _centerOnTileKey;
  bool _showProvinceNames = true;

  @override
  Widget build(BuildContext context) {
    final result = getDebugInitGameResult();
    final game = result.game;
    final mapViewData = result.mapViewData;
    final humanPlayerId = game.players.isNotEmpty
        ? game.players.first.id
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
            child: MilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: result.combinedTopology,
              draftOrders: const Orders(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Train Military Dialog stories. SPEC/ui/train-military-dialog.md.
