part of 'game_map_area.dart';

/// State lifecycle for [GameMapArea]: bus-subscription wiring in [initState],
/// observe-mode listeners, teardown in [dispose], and the per-game reset /
/// work-target refresh in [didUpdateWidget] (Refs #3699 Theme 3).
mixin _GameMapAreaLifecycle
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaSelection,
        _GameMapAreaView,
        _GameMapAreaEvents {
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
      bus.on<ct_models.AppSpyCaughtEvent>().listen(_onAppSpyCaughtEvent),
      bus.on<ct_models.AppSpyDefectedEvent>().listen(_onAppSpyDefectedEvent),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeAutoCenterOnShellEntry();
    });
  }

  @override
  void dispose() {
    _turnResolutionProgressSub?.cancel();
    _turnResolutionProgressSub = null;
    _busSubscriptions.cancelAll();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      ref.read(mapProvincePanelProvider.notifier).reset();
      ref.read(regionMinimapVisibleProvider.notifier).reset();
      setState(() {
        _refreshWorkTargetSelectionCache(widget.game);
        _mapViewState = widget.game.mapViewState;
        _regionViewportSnapshot = null;
        _pendingRegionViewport = null;
        _regionViewportFrameScheduled = false;
        _didAutoCenterOnEntry = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeAutoCenterOnShellEntry();
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
}
