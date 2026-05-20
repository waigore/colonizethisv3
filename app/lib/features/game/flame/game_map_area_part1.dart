part of 'game_map_area.dart';

mixin _GameMapAreaStatePart1 on ConsumerState<GameMapArea> {
  int _regionIndex = 0;
  RegionMapViewportSnapshot? _regionViewportSnapshot;
  RegionMapViewportSnapshot? _pendingRegionViewport;
  bool _regionViewportFrameScheduled = false;
  String? _centerOnTileKey;
  String? _selectedCivilianTileKey;
  ({ct_models.Unit unit, String workTarget})? _workTargetSelection;
  Set<String>? _cachedValidTileKeys;
  final PerPlayerWorkTargetSelectionCache _workTargetSelectionCache =
      PerPlayerWorkTargetSelectionCache();
  bool _sideMenuOpen = false;
  bool _debugConsoleOpen = false;
  final SubscriptionTracker _busSubscriptions = SubscriptionTracker();
  ct_models.MapViewState _mapViewState = ct_models.MapViewState.defaults;
  final List<ct_models.GameToUIEvent> _pendingPlayerTurnEvents = [];
  List<ct_models.GameToUIEvent> _resolvedPlayerTurnEvents = const [];
  bool _isTurnResolving = false;
  StreamSubscription<TurnResolutionProgressEvent>? _turnResolutionProgressSub;

  /// Base layer display mode for map letters. SPEC/ui/empire-overview.md § Base layer display cycle.
  BaseLayerDisplayMode _baseLayerDisplayMode =
      BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads;
  @override
  void initState() {
    super.initState();
    _mapViewState = widget.game.mapViewState;
    _refreshWorkTargetSelectionCache(widget.game);
    final bus = ref.read(appEventBusProvider);
    for (final subscription in [
      bus.on<ct_models.OpenProvinceDetailPanelEvent>().listen((_) {
        if (!mounted) return;
        setState(() {
          // Town icon tap will be handled by the province panel provider
        });
      }),
      bus.on<ct_models.LocateMapTileEvent>().listen(
        (e) => _locateTile(e.tileKey, e.regionId),
      ),
      bus.on<ct_models.StartCivilianWorkTargetSelectionEvent>().listen(
        (e) => _startWorkTargetSelection(e.unitId, e.workTarget),
      ),
      bus.on<ct_models.UnitsPanelClosedEvent>().listen((_) {
        ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(null);
      }),
      bus.on<ct_models.OpenMapTileDetailEvent>().listen(
        (e) => _openMapTileDetail(e.tileKey),
      ),
      bus.on<ct_models.AppCombatResultEvent>().listen(_onAppCombatResultEvent),
      bus.on<ct_models.AppNavalCombatResultEvent>().listen(
        _onAppNavalCombatResultEvent,
      ),
      bus.on<ct_models.AppProvinceCapturedEvent>().listen(
        _onAppProvinceCapturedEvent,
      ),
      bus.on<ct_models.AppDiplomacyChangeEvent>().listen(
        _onAppDiplomacyChangeEvent,
      ),
      bus.on<ct_models.AppResearchCompleteEvent>().listen(
        _onAppResearchCompleteEvent,
      ),
      bus.on<ct_models.AppOrderRejectedEvent>().listen(
        _onAppOrderRejectedEvent,
      ),
      bus.on<ct_models.AppWorkOrderCompletedEvent>().listen(
        _onAppWorkOrderCompletedEvent,
      ),
      bus.on<ct_models.AppPlayerProvinceDiscoveredEvent>().listen(
        _onAppPlayerProvinceDiscoveredEvent,
      ),
      bus.on<ct_models.AppPlayerSeaZoneDiscoveredEvent>().listen(
        _onAppPlayerSeaZoneDiscoveredEvent,
      ),
      bus.on<ct_models.AppOvertureAdvancedEvent>().listen(
        _onAppOvertureAdvancedEvent,
      ),
      bus.on<ct_models.TurnResolutionCompleteEvent>().listen(
        _onTurnResolutionCompleteEvent,
      ),
      bus.on<ct_models.OpenDebugConsolePanelEvent>().listen((_) {
        if (!mounted || !ref.read(debugConsoleEnabledProvider)) return;
        setState(() => _debugConsoleOpen = true);
      }),
      bus.on<ct_models.CloseDebugConsolePanelEvent>().listen((_) {
        if (!mounted) return;
        setState(() => _debugConsoleOpen = false);
      }),
      bus.on<ct_models.ToggleDebugConsolePanelEvent>().listen((_) {
        if (!mounted || !ref.read(debugConsoleEnabledProvider)) return;
        setState(() => _debugConsoleOpen = !_debugConsoleOpen);
      }),
    ]) {
      _busSubscriptions.track(subscription);
    }
    ref.listenManual(observeSessionProvider, (previous, next) {
      if (!mounted) return;
      final enteredObserve =
          next.isObserving && !(previous?.isObserving ?? false);
      final switchedMode =
          next.isObserving && previous?.mode != next.mode;
      if (enteredObserve || switchedMode) {
        _cancelWorkTargetSelection();
      }
    });
  }

  void _onTurnResolutionCompleteEvent(
    ct_models.TurnResolutionCompleteEvent event,
  ) {
    if (event.gameId != widget.game.id || !mounted) {
      return;
    }
    setState(() {
      _refreshWorkTargetSelectionCache(widget.game);
      _resolvedPlayerTurnEvents = List<ct_models.GameToUIEvent>.from(
        _pendingPlayerTurnEvents,
      );
      _pendingPlayerTurnEvents.clear();
    });
  }

  void _refreshWorkTargetSelectionCache(ct_models.Game game) {
    final view = buildPlayerView(
      game,
      widget.mapViewData.combinedTopology,
      _mapPlayerId,
    );
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    _workTargetSelectionCache.refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: _mapPlayerId,
        playerView: view,
        topology: widget.mapViewData.combinedTopology,
        currentOrders: const ct_models.Orders(),
        tileMapByRegion: mapData?.tileMapByRegion,
      ),
    );
  }

  void _onAppCombatResultEvent(ct_models.AppCombatResultEvent event) {
    if (event.attackerId != _mapPlayerId &&
        event.defenderId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppNavalCombatResultEvent(ct_models.AppNavalCombatResultEvent event) {
    if (event.side1OwnerId != _mapPlayerId &&
        event.side2OwnerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppProvinceCapturedEvent(ct_models.AppProvinceCapturedEvent event) {
    if (event.previousOwnerId != _mapPlayerId &&
        event.newOwnerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppDiplomacyChangeEvent(ct_models.AppDiplomacyChangeEvent event) {
    if (event.actorId != _mapPlayerId && event.targetId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppResearchCompleteEvent(ct_models.AppResearchCompleteEvent event) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppOrderRejectedEvent(ct_models.AppOrderRejectedEvent event) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppWorkOrderCompletedEvent(
    ct_models.AppWorkOrderCompletedEvent event,
  ) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppPlayerProvinceDiscoveredEvent(
    ct_models.AppPlayerProvinceDiscoveredEvent event,
  ) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppPlayerSeaZoneDiscoveredEvent(
    ct_models.AppPlayerSeaZoneDiscoveredEvent event,
  ) {
    if (event.playerId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  void _onAppOvertureAdvancedEvent(ct_models.AppOvertureAdvancedEvent event) {
    if (event.offererGpId != _mapPlayerId &&
        event.targetFactionId != _mapPlayerId) {
      return;
    }
    _pendingPlayerTurnEvents.add(event);
  }

  @override
  void dispose() {
    _turnResolutionProgressSub?.cancel();
    _turnResolutionProgressSub = null;
    _busSubscriptions.cancelAll();
    super.dispose();
  }

  String get _mapPlayerId =>
      ref.read(shellPlayerContextProvider).mapPlayerIdFor(widget.game);

  String? get _debugConsolePlayerId =>
      ref.read(shellPlayerContextProvider).debugCommandTargetPlayerId ??
      _mapPlayerId;

  RegionMapViewData get _currentRegion => _regionIndex == 0
      ? widget.mapViewData.oldWorld
      : widget.mapViewData.newWorld;

  Set<String>? get _validTileKeysForSelection => _cachedValidTileKeys;

  int? _preferredRegionIndexForValidSelection(Set<String> validTileKeys) {
    if (validTileKeys.isEmpty) {
      return null;
    }
    final currentRegionId = _currentRegion.regionId;
    final hasCurrent = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$currentRegionId|'),
    );
    if (hasCurrent) {
      return null;
    }
    final hasOldWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionOldWorld|'),
    );
    final hasNewWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionNewWorld|'),
    );
    if (hasOldWorld && !hasNewWorld) {
      return 0;
    }
    if (hasNewWorld && !hasOldWorld) {
      return 1;
    }
    return null;
  }

  void _computeValidTileKeysForSelection() {
    if (_workTargetSelection == null) {
      _cachedValidTileKeys = null;
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) {
      _cachedValidTileKeys = null;
      return;
    }
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, _mapPlayerId);
    final workTarget = _workTargetSelection!.workTarget;
    _cachedValidTileKeys =
        GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
          workTarget: workTarget,
          workTargetSelectionCache: _workTargetSelectionCache,
          humanPlayerId: _mapPlayerId,
          selectedUnitId: _workTargetSelection!.unit.id,
          game: game,
          currentOrders: orders,
          playerView: view,
          topology: topology,
          tileMapByRegion: mapData?.tileMapByRegion,
        );
  }

  void _cycleBaseLayerDisplayMode() {
    setState(() {
      _baseLayerDisplayMode = switch (_baseLayerDisplayMode) {
        BaseLayerDisplayMode.terrainOnly =>
          BaseLayerDisplayMode.terrainAndResources,
        BaseLayerDisplayMode.terrainAndResources =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
        BaseLayerDisplayMode.terrainAndResourcesImprovementLabels =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads =>
          BaseLayerDisplayMode.terrainOnly,
      };
    });
  }

  void _setMapViewState(ct_models.MapViewState next) {
    if (_mapViewState == next) {
      return;
    }
    setState(() {
      _mapViewState = next;
    });
    final current = ref.read(currentGameProvider);
    if (current != null && current.id == widget.game.id) {
      ref
          .read(currentGameProvider.notifier)
          .setGame(current.copyWith(mapViewState: next));
    }
  }

  void _togglePlayerTurnEventsFeedVisibility() {
    _setMapViewState(
      _mapViewState.copyWith(
        showPlayerTurnEventsFeed: !_mapViewState.showPlayerTurnEventsFeed,
      ),
    );
  }

  void _centerOnHumanCapital() {
    final shell = ref.read(shellPlayerContextProvider);
    final playerId =
        shell.debugCommandTargetPlayerId ?? _mapPlayerId;
    final player =
        widget.game.playerById(playerId) ?? widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    final tileKey = capital.toTileKey();
    final regionId = capital.regionId;
    ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(tileKey);
    setState(() {
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _centerOnTileKey = null;
      });
    });
  }

  void _locateTile(String tileKey, String regionId) {
    ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(tileKey);
    setState(() {
      _centerOnTileKey = tileKey;
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  void _openMapTileDetail(String tileKey) {
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    ref.read(mapProvincePanelProvider.notifier).reportMapTileTapped(tileKey);
    setState(() {
      if (regionId == 'newWorld') {
        _regionIndex = 1;
      } else if (regionId == 'oldWorld') {
        _regionIndex = 0;
      }
    });
  }

  /// Integration tests only ([kCtE2EEnabled]). Same effect as tapping the capital map cell.
  void _e2eOpenHumanCapitalTileDetail() {
    final shell = ref.read(shellPlayerContextProvider);
    final playerId =
        shell.debugCommandTargetPlayerId ?? _mapPlayerId;
    final player =
        widget.game.playerById(playerId) ?? widget.game.players.first;
    final capital = player.capitalTile;
    if (capital == null) {
      return;
    }
    _openMapTileDetail(capital.toTileKey());
  }

  ct_models.Unit? _findUnitById(String unitId) {
    for (final unit in widget.game.worldState.oldWorld.units) {
      if (unit.id == unitId) return unit;
    }
    for (final unit in widget.game.worldState.newWorld.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  void _startWorkTargetSelection(String unitId, String workTarget) {
    final unit = _findUnitById(unitId);
    if (unit == null) return;
    setState(() {
      _workTargetSelection = (unit: unit, workTarget: workTarget);
      _computeValidTileKeysForSelection();
      final validTileKeys = _cachedValidTileKeys;
      if (validTileKeys != null) {
        final preferredRegionIndex = _preferredRegionIndexForValidSelection(
          validTileKeys,
        );
        if (preferredRegionIndex != null) {
          _regionIndex = preferredRegionIndex;
        }
      }
    });
  }

  void _cancelWorkTargetSelection() {
    if (_workTargetSelection == null) {
      return;
    }
    setState(() {
      _workTargetSelection = null;
      _cachedValidTileKeys = null;
    });
  }

  void _onTileSelectedForWork(String tileKey) {
    if (!ref.read(shellPlayerContextProvider).canMutateViaUi) {
      return;
    }
    final sel = _workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    final targetTileKey = GameMapAreaStateLogic.translateWorkTargetTileKey(
      tileKey: tileKey,
      workTarget: target,
    );
    final workOrder = ct_models.WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    final orders = ref.read(currentOrdersProvider);
    ref
        .read(currentOrdersProvider.notifier)
        .replaceAll(
          GameMapAreaStateLogic.addHumanWorkOrder(
            orders: orders,
            humanPlayerId: _mapPlayerId,
            workOrder: workOrder,
          ),
        );
    setState(() {
      _selectedCivilianTileKey =
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: _selectedCivilianTileKey,
            assignedTileKey: targetTileKey,
          );
      _workTargetSelection = null;
      _cachedValidTileKeys = null;
    });
  }

  Future<void> _onNextTurn() async {
    if (_isTurnResolving) {
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) return;
    if (!GameMapAreaStateLogic.allowsFullTurnResolution(game)) {
      return;
    }

    final currentTurn = game.worldState.turnState.turnNumber;
    final ok = await showNextTurnConfirmationDialog(
      context,
      currentTurn: currentTurn,
    );
    if (ok != true) return;
    if (!mounted) return;

    final service = ref.read(gameServiceProvider);
    final runner = ref.read(turnResolutionRunnerProvider);
    final failureMessage = appL10n(context).game_turnResolutionFailedMessage;
    final messenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final orders = ref.read(currentOrdersProvider);
    final mapData = service.getMapData(game.id);
    if (mapData == null) {
      throw StateError('Missing required map data for gameId=${game.id}');
    }

    final phaseNotifier = ValueNotifier<String>('Resolving turn...');
    var processingDialogOpen = true;
    final uiStopwatch = Stopwatch()..start();
    setState(() {
      _isTurnResolving = true;
    });
    ref.read(turnResolutionBlockingProvider.notifier).setBlocking(true);
    _gameMapNextTurnUiLog.i(
      'logic: next_turn_ui_map started gameId=${game.id} turn=$currentTurn '
      'turnTraceEnabled=${service.isTurnTraceEnabled}',
    );
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => ValueListenableBuilder<String>(
          valueListenable: phaseNotifier,
          builder: (_, text, _) =>
              TurnResolutionProcessingDialog(phaseText: text),
        ),
      ).whenComplete(() {
        processingDialogOpen = false;
      }),
    );
    await awaitTurnResolutionProcessingDialogFirstPaint();
    _gameMapNextTurnUiLog.i(
      'logic: next_turn_ui_map processing_dialog_painted gameId=${game.id} '
      'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
    );
    try {
      final session = runner.startResolution(
        game: game,
        orders: orders,
        topology: mapData.combinedTopology,
        tileMapByRegion: mapData.tileMapByRegion,
        turnTraceEnabled: service.isTurnTraceEnabled,
        turnTraceRootDirectory: service.turnTraceRootDirectory,
      );
      final activeSessionId = session.sessionId;
      _gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map session_started gameId=${game.id} '
        'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      await _turnResolutionProgressSub?.cancel();
      _turnResolutionProgressSub = session.progress.listen((event) {
        if (!mounted ||
            event.sessionId != activeSessionId ||
            event.marker != 'start') {
          return;
        }
        phaseNotifier.value = turnResolutionProgressPhaseLabel(event.phase);
        _gameMapNextTurnUiLog.d(
          'logic: next_turn_ui_map phase gameId=${game.id} sessionId=$activeSessionId '
          'phase=${event.phase} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
        );
      });
      final terminal = await session.done;
      _gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map session_done gameId=${game.id} sessionId=$activeSessionId '
        'terminalType=${terminal.runtimeType} elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      if (!mounted) {
        return;
      }
      if (processingDialogOpen) {
        rootNavigator.pop();
        processingDialogOpen = false;
      }
      switch (terminal) {
        case TurnResolutionTerminalComplete c:
          final handleStopwatch = Stopwatch()..start();
          service.handleExternallyResolvedTurnResult(c.result);
          _gameMapNextTurnUiLog.i(
            'logic: next_turn_ui_map external_result_handled gameId=${game.id} '
            'sessionId=$activeSessionId handleMs=${handleStopwatch.elapsedMilliseconds} '
            'resultType=${c.result.runtimeType}',
          );
          if (service.isTurnTraceEnabled &&
              c.result is TurnResolutionComplete &&
              c.turnTracePhases != null &&
              c.turnTraceStartedAtUtc != null) {
            final complete = c.result as TurnResolutionComplete;
            service.exportTurnTraceForExternallyResolvedTurn(
              gameAtResolutionStart: game,
              turnEndState: complete.game,
              phases: c.turnTracePhases!,
              ai: c.aiTraceSections ?? const <TurnTraceAiSection>[],
              turnStartAtUtc: c.turnTraceStartedAtUtc!,
            );
          }
          if (c.turnTraceExportPath != null) {
            _gameMapNextTurnUiLog.i(
              'logic: next_turn_ui_map worker_trace_export_path gameId=${game.id} '
              'sessionId=$activeSessionId path=${c.turnTraceExportPath}',
            );
          }
          final applyStopwatch = Stopwatch()..start();
          applyTurnResolutionResult(ref, c.result);
          _gameMapNextTurnUiLog.i(
            'logic: next_turn_ui_map result_applied gameId=${game.id} '
            'sessionId=$activeSessionId applyMs=${applyStopwatch.elapsedMilliseconds} '
            'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
          );
        case TurnResolutionTerminalError e:
          messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
          _gameMapNextTurnUiLog.e(
            'logic: next_turn_ui_map terminal_error gameId=${game.id} '
            'sessionId=$activeSessionId elapsedMs=${uiStopwatch.elapsedMilliseconds}',
            error: e.errorMessage,
            stackTrace: e.stackTrace.isEmpty
                ? null
                : StackTrace.fromString(e.stackTrace),
          );
          throw StateError(e.errorMessage);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
      }
      rethrow;
    } finally {
      clearTurnResolutionBlockingFlag();
      await _turnResolutionProgressSub?.cancel();
      _turnResolutionProgressSub = null;
      _gameMapNextTurnUiLog.i(
        'logic: next_turn_ui_map cleanup_complete gameId=${game.id} '
        'elapsedMs=${uiStopwatch.elapsedMilliseconds}',
      );
      if (mounted && processingDialogOpen) {
        rootNavigator.pop();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        phaseNotifier.dispose();
      });
      if (mounted) {
        setState(() {
          _isTurnResolving = false;
        });
      }
    }
  }

  void _e2eSelectFirstValidWorkTargetTile() {
    final keys = _cachedValidTileKeys;
    if (keys == null || keys.isEmpty) return;
    final sorted = keys.toList()..sort();
    _onTileSelectedForWork(sorted.first);
  }

  void _e2eOpenFirstCivilianMarkerPanel() {
    if (!mounted) return;
    final projected = ref.read(
          humanDraftProjectedRegionProvider(_currentRegion.regionId),
        ) ??
        _currentRegion;
    final markers = [...projected.civilianTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialUnitId = m.unitIds.isNotEmpty ? m.unitIds.first : null;
    setState(() => _selectedCivilianTileKey = m.tileKey);
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenCivilianUnitsPanelEvent(
            tileScopeTileKey: m.tileKey,
            initialSelectedUnitId: initialUnitId,
          ),
        );
  }

  void _e2eOpenFirstFleetMarkerPanel() {
    if (!mounted) return;
    final projected = ref.read(
          humanDraftProjectedRegionProvider(_currentRegion.regionId),
        ) ??
        _currentRegion;
    final markers = [...projected.fleetTileMarkers]
      ..sort((a, b) => a.tileKey.compareTo(b.tileKey));
    if (markers.isEmpty) return;
    final m = markers.first;
    final initialFleetId = m.fleetIds.isNotEmpty ? m.fleetIds.first : null;
    ref
        .read(appEventBusProvider)
        .emit(
          ct_models.OpenNavalUnitsPanelEvent(
            locationScopeKey: m.locationScopeKey,
            initialSelectedFleetId: initialFleetId,
            tileScopeTileKey: m.tileKey,
          ),
        );
  }

  String _factionLabel(String id) {
    for (final p in widget.game.players) {
      if (p.id == id) return p.displayName;
    }
    for (final m in widget.game.minorNations) {
      if (m.id == id) return m.displayName ?? m.id;
    }
    for (final t in widget.game.tribes) {
      if (t.id == id) return t.displayName ?? t.id;
    }
    return id;
  }

  String _provinceLabel(String fullProvinceId) {
    for (final region in [
      widget.game.worldState.oldWorld,
      widget.game.worldState.newWorld,
    ]) {
      for (final province in region.provinces) {
        final prefixed = ct_models.ProvinceId.isPrefixed(province.id)
            ? province.id
            : ct_models.ProvinceId.full(province.regionId, province.id);
        if (prefixed == fullProvinceId) {
          return province.displayName ?? prefixed;
        }
      }
    }
    return fullProvinceId;
  }

  String _seaZoneLabel(String seaZoneId) {
    return widget.game.worldState.seaZoneDisplayNameById[seaZoneId] ??
        seaZoneId;
  }

  String _diplomacyOutcomeLine({
    required String actorId,
    required String targetId,
    required String changeType,
  }) {
    final actor = _factionLabel(actorId);
    final target = _factionLabel(targetId);
    final normalized = changeType.toLowerCase();
    return switch (normalized) {
      'declare_war' => '$actor declared war on $target!',
      'peace' => '$actor and $target signed peace!',
      'alliance' => '$actor and $target formed an alliance!',
      'break_alliance' => '$actor and $target broke their alliance!',
      _ => '$actor and $target diplomacy changed! ${changeType.toUpperCase()}!',
    };
  }

  Set<String> _seaZoneRegionCandidates(String seaZoneId) {
    final regionFromPrefix = prefixedIdRegionSegment(seaZoneId);
    if (regionFromPrefix != null && regionFromPrefix.isNotEmpty) {
      return {regionFromPrefix};
    }
    final localSeaZoneId = prefixedIdLocalSegment(seaZoneId);
    final fromPorts = <String>{};
    for (final key in widget.game.worldState.portsByProvinceSeaboard.keys) {
      final parts = key.split('|');
      if (parts.length < 2) {
        continue;
      }
      if (parts.last == localSeaZoneId && parts.first.isNotEmpty) {
        fromPorts.add(parts.first);
      }
    }
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    final fromTopology = <String>{};
    if (mapData == null) {
      return fromPorts;
    }
    for (final entry in mapData.topologyByRegion.entries) {
      if (entry.value.nodes.any(
        (node) =>
            node.type == TopologyNodeType.seaZone && node.id == localSeaZoneId,
      )) {
        fromTopology.add(entry.key);
      }
    }
    return {...fromPorts, ...fromTopology};
  }

  String? _tileKeyForSeaZoneEvent(String seaZoneId) {
    final candidates = _seaZoneRegionCandidates(seaZoneId);
    if (candidates.length != 1) {
      return null;
    }
    final regionId = candidates.first;
    final mapData = ref.read(gameServiceProvider).getMapData(widget.game.id);
    return tileKeyForNavalFleetAtSea(
      game: widget.game,
      regionId: regionId,
      seaZoneId: seaZoneId,
      tileMap: mapData?.tileMapByRegion[regionId],
      regionTopology: mapData?.topologyByRegion[regionId],
    );
  }

  ct_models.Province? _provinceByPrefixedId(String prefixedProvinceId) {
    for (final region in [
      widget.game.worldState.oldWorld,
      widget.game.worldState.newWorld,
    ]) {
      for (final province in region.provinces) {
        final prefixed = ct_models.ProvinceId.isPrefixed(province.id)
            ? province.id
            : ct_models.ProvinceId.full(province.regionId, province.id);
        if (prefixed == prefixedProvinceId) {
          return province;
        }
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant GameMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      ref.read(mapProvincePanelProvider.notifier).reset();
      ref.read(regionMinimapVisibleProvider.notifier).resetToDefault();
      setState(() {
        _refreshWorkTargetSelectionCache(widget.game);
        _mapViewState = widget.game.mapViewState;
        _regionViewportSnapshot = null;
        _pendingRegionViewport = null;
        _regionViewportFrameScheduled = false;
      });
    } else if (oldWidget.game.mapViewState != widget.game.mapViewState) {
      _mapViewState = widget.game.mapViewState;
    }
    if (oldWidget.game.worldState.turnState.turnNumber !=
        widget.game.worldState.turnState.turnNumber) {
      setState(() {
        _refreshWorkTargetSelectionCache(widget.game);
      });
    }
  }

  void _onRegionViewportSnapshot(RegionMapViewportSnapshot snapshot) {
    final clampedMultiplier = snapshot.zoomMultiplier.clamp(0.5, 8.0);
    if ((clampedMultiplier - _mapViewState.zoomMultiplier).abs() > 0.001) {
      _setMapViewState(
        _mapViewState.copyWith(zoomMultiplier: clampedMultiplier),
      );
    }
    _pendingRegionViewport = snapshot;
    if (_regionViewportFrameScheduled) return;
    _regionViewportFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _regionViewportFrameScheduled = false;
      if (!mounted) return;
      final next = _pendingRegionViewport;
      _pendingRegionViewport = null;
      if (next == null) return;
      final cur = _regionViewportSnapshot;
      if (cur != null && cur.matches(next)) return;
      setState(() => _regionViewportSnapshot = next);
    });
  }
}
