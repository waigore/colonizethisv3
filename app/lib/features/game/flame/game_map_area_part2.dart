part of 'game_map_area.dart';

mixin _GameMapAreaStatePart2
    on _GameMapAreaStatePart1, ConsumerState<GameMapArea> {
  @override
  Widget build(BuildContext context) {
    final currentOrders = ref.watch(currentOrdersProvider);
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final mapTopology = widget.mapViewData.combinedTopology;
    final humanPlayerView = buildPlayerView(
      widget.game,
      mapTopology,
      _humanPlayerId,
    );
    final l10n = appL10n(context);
    final mapData = ref.watch(gameServiceProvider).getMapData(widget.game.id);
    var projectedRegion =
        GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
          region: _currentRegion,
          game: widget.game,
          orders: currentOrders,
          humanPlayerId: _humanPlayerId,
        );
    final tm = mapData?.tileMapByRegion;
    final tr = mapData?.topologyByRegion;
    final ct = mapData?.combinedTopology;
    if (tm != null && tr != null && ct != null) {
      projectedRegion = GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
        region: projectedRegion,
        game: widget.game,
        orders: currentOrders,
        humanPlayerId: _humanPlayerId,
        tileMapByRegion: tm,
        topologyByRegion: tr,
        combinedTopology: ct,
      );
    }
    final nextTurnText = l10n.game_nextTurnButton(
      widget.game.worldState.turnState.turnNumber,
      turnToYear(
        widget.game.worldState.turnState.turnNumber,
        widget.game.turnTimeMapping,
      ),
    );
    final cargoSummary = ref.watch(homeFleetCargoSummaryProvider);
    final treasurySummary = ref.watch(treasurySummaryProvider);
    final feedEntries = (this as _GameMapAreaState)._feedEntries();
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);
    return Column(
      children: [
        GameMapControls(
          sideMenuOpen: _sideMenuOpen,
          onToggleSideMenu: () =>
              setState(() => _sideMenuOpen = !_sideMenuOpen),
          onNextTurn: _onNextTurn,
          nextTurnEnabled:
              !_isTurnResolving &&
              GameMapAreaStateLogic.allowsFullTurnResolution(widget.game),
          regionIndex: _regionIndex,
          onRegionIndexChanged: (i) =>
              setState(() => _regionIndex = i == 0 ? 0 : 1),
          nextTurnText: nextTurnText,
          cargoUsed: cargoSummary.used,
          cargoCapacity: cargoSummary.capacity,
          isCargoUsedReliable: cargoSummary.isCargoUsedReliable,
          treasury: treasurySummary.treasury,
          treasuryDelta: treasurySummary.projectedDelta,
          playerTurnEventsFeedCount: feedEntries.length,
          showPlayerTurnEventsFeed: _mapViewState.showPlayerTurnEventsFeed,
          onTogglePlayerTurnEventsFeed: _togglePlayerTurnEventsFeedVisibility,
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _isTurnResolving,
                  child: Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (_workTargetSelection != null &&
                          event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        _cancelWorkTargetSelection();
                        return KeyEventResult.handled;
                      }
                      if (_sideMenuOpen &&
                          event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        setState(() => _sideMenuOpen = false);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Stack(
                      children: [
                        GameMapCanvasStack(
                          isNarrow: isNarrow,
                          game: widget.game,
                          region: projectedRegion,
                          baseLayerDisplayMode: _baseLayerDisplayMode,
                          showProvinceOverlay:
                              _mapViewState.showProvinceOverlay,
                          showProvinceOwnershipTint:
                              _mapViewState.showProvinceOwnershipTint,
                          showProvinceNamesLayer:
                              _mapViewState.showProvinceNamesLayer,
                          humanPlayerId: _humanPlayerId,
                          playerView: humanPlayerView,
                          workTargetSelectionCache: _workTargetSelectionCache,
                          centerOnTileKey: _centerOnTileKey,
                          validTileKeysForSelection: _validTileKeysForSelection,
                          selectedCivilianTileKey: _selectedCivilianTileKey,
                          onTileSelectedForWork: _workTargetSelection != null
                              ? _onTileSelectedForWork
                              : null,
                          onWorkTargetSelectionCancelled:
                              _workTargetSelection != null
                              ? _cancelWorkTargetSelection
                              : null,
                          onCivilianTileStateChanged: (tileKey) {
                            setState(() {
                              _selectedCivilianTileKey = tileKey;
                            });
                          },
                          onCivilianTileSelectionCleared: () {
                            if (_selectedCivilianTileKey == null) return;
                            setState(() {
                              _selectedCivilianTileKey = null;
                            });
                          },
                          bus: ref.read(appEventBusProvider),
                          onRegionViewportSnapshot: _onRegionViewportSnapshot,
                          zoomMultiplier: _mapViewState.zoomMultiplier,
                        ),
                        if (!_sideMenuOpen)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: kEdgeSwipeStripWidth,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) {
                                if (details.delta.dx > 20) {
                                  setState(() => _sideMenuOpen = true);
                                }
                              },
                            ),
                          ),
                        Positioned(
                          left: kEdgeSwipeStripWidth,
                          top: 0,
                          child: GameMapEmpireLeftRail(
                            game: widget.game,
                            humanPlayerId: _humanPlayerId,
                            onIconTappedWhileSelectionMode:
                                _workTargetSelection != null
                                ? _cancelWorkTargetSelection
                                : null,
                          ),
                        ),
                        Positioned(
                          left: kMapOverlayEdgeInset,
                          bottom: kMapOverlayEdgeInset,
                          child: GameMapCornerControls(
                            onCycleBaseLayerDisplayMode:
                                _cycleBaseLayerDisplayMode,
                            onCenterOnHomeCapital: _centerOnHumanCapital,
                            onOpenMapDisplayOptions: () {
                              showDialog<void>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(l10n.map_displayOptions_title),
                                    content: Consumer(
                                      builder: (context, ref, child) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SwitchListTile(
                                              title: Text(
                                                l10n.map_displayOptions_showProvinceOverlay,
                                              ),
                                              value: _mapViewState
                                                  .showProvinceOverlay,
                                              onChanged: (value) {
                                                _setMapViewState(
                                                  _mapViewState.copyWith(
                                                    showProvinceOverlay: value,
                                                  ),
                                                );
                                              },
                                            ),
                                            SwitchListTile(
                                              title: Text(
                                                l10n.map_displayOptions_showProvinceOwnership,
                                              ),
                                              value: _mapViewState
                                                  .showProvinceOwnershipTint,
                                              onChanged: (value) {
                                                _setMapViewState(
                                                  _mapViewState.copyWith(
                                                    showProvinceOwnershipTint:
                                                        value,
                                                  ),
                                                );
                                              },
                                            ),
                                            SwitchListTile(
                                              title: Text(
                                                l10n.map_displayOptions_showProvinceNames,
                                              ),
                                              value: _mapViewState
                                                  .showProvinceNamesLayer,
                                              onChanged: (value) {
                                                _setMapViewState(
                                                  _mapViewState.copyWith(
                                                    showProvinceNamesLayer:
                                                        value,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        child: Text(l10n.common_close),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        if (kCtE2EEnabled) ...[
                          Positioned(
                            right: kMapOverlayEdgeInset,
                            top: kMapOverlayEdgeInset,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: kCtE2EOpenCapitalProvinceDetailKey,
                                  onTap: _e2eOpenHumanCapitalTileDetail,
                                ),
                              ),
                            ),
                          ),
                          if (_workTargetSelection != null &&
                              _cachedValidTileKeys != null &&
                              _cachedValidTileKeys!.isNotEmpty)
                            Positioned(
                              right: kMapOverlayEdgeInset,
                              top: kMapOverlayEdgeInset + 48,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: kCtE2ESelectFirstValidWorkTileKey,
                                    onTap: _e2eSelectFirstValidWorkTargetTile,
                                  ),
                                ),
                              ),
                            ),
                          if (projectedRegion.civilianTileMarkers.isNotEmpty)
                            Positioned(
                              right: kMapOverlayEdgeInset,
                              top: kMapOverlayEdgeInset + 96,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: kCtE2EOpenFirstCivilianMarkerPanelKey,
                                    onTap: _e2eOpenFirstCivilianMarkerPanel,
                                  ),
                                ),
                              ),
                            ),
                          if (projectedRegion.fleetTileMarkers.isNotEmpty)
                            Positioned(
                              right: kMapOverlayEdgeInset,
                              top: kMapOverlayEdgeInset + 144,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: kCtE2EOpenFirstFleetMarkerPanelKey,
                                    onTap: _e2eOpenFirstFleetMarkerPanel,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        if (_sideMenuOpen) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  setState(() => _sideMenuOpen = false),
                              child: Container(color: Colors.black54),
                            ),
                          ),
                          GameSideMenu(
                            sideMenuOpen: _sideMenuOpen,
                            onClose: () =>
                                setState(() => _sideMenuOpen = false),
                          ),
                        ],
                        Consumer(
                          builder: (context, ref, _) {
                            final panelOpen = ref
                                .watch(mapProvincePanelProvider)
                                .overlayOpen;
                            final rightInset = !isNarrow
                                ? gameMapWideOverlayRightInset(
                                    provincePanelOpen: panelOpen,
                                  )
                                : kGameMapWideStackRightGutter;
                            return Positioned(
                              right: rightInset,
                              bottom: 8,
                              child: GameRegionMinimap(
                                region: projectedRegion,
                                viewportSnapshot: _regionViewportSnapshot,
                                bus: ref.read(appEventBusProvider),
                                cellSizePx: _currentRegion.cellSize.toDouble(),
                              ),
                            );
                          },
                        ),
                        if (!isNarrow)
                          Consumer(
                            builder: (context, ref, _) {
                              final panelOpen = ref
                                  .watch(mapProvincePanelProvider)
                                  .overlayOpen;
                              final rightInset = gameMapWideOverlayRightInset(
                                provincePanelOpen: panelOpen,
                              );
                              if (!_mapViewState.showPlayerTurnEventsFeed) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                right: rightInset,
                                top: 56,
                                child: PlayerTurnEventFeedCard(
                                  entries: feedEntries,
                                  emptyLabel: 'No player events last turn.',
                                ),
                              );
                            },
                          ),
                        if (isNarrow && _mapViewState.showPlayerTurnEventsFeed)
                          Positioned(
                            right: kMapOverlayEdgeInset,
                            top: 56,
                            child: PlayerTurnEventFeedCard(
                              entries: feedEntries,
                              emptyLabel: 'No player events last turn.',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (debugConsoleEnabled && _debugConsoleOpen)
                Positioned(
                  left: kEdgeSwipeStripWidth + 60,
                  top: 56,
                  child: DebugConsoleOverlayPanel(
                    bus: ref.read(appEventBusProvider),
                    humanPlayerId: _humanPlayerId,
                    readOnlyContextProvider: () {
                      final selectedTileKey =
                          ref.read(mapProvincePanelProvider).selectedTileKey;
                      final players = widget.game.players
                          .map(
                            (p) => DebugConsolePlayerSnapshot(
                              id: p.id,
                              displayName: p.displayName,
                              isHuman: p.isHuman,
                              capitalProvinceId: p.capitalProvinceId,
                            ),
                          )
                          .toList(growable: false);
                      return DebugConsoleReadOnlyContext(
                        selectedTileKey: selectedTileKey,
                        players: players,
                      );
                    },
                    onClose: () => setState(() => _debugConsoleOpen = false),
                  ),
                ),
              if (isNarrow)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GameMapNarrowDetailOverlaySlot(
                        game: widget.game,
                        region: projectedRegion,
                        humanPlayerId: _humanPlayerId,
                        playerView: humanPlayerView,
                        workTargetSelectionCache: _workTargetSelectionCache,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
