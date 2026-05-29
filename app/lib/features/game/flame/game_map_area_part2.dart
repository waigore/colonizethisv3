part of 'game_map_area.dart';

mixin _GameMapAreaStatePart2
    on _GameMapAreaStatePart1, ConsumerState<GameMapArea> {
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final mapTopology = widget.mapViewData.combinedTopology;
    final shell = ref.watch(shellPlayerContextProvider);
    final mapPlayerId = shell.mapPlayerIdFor(widget.game);
    final mapPlayerView =
        shell.playerView ?? buildPlayerView(widget.game, mapTopology, mapPlayerId);
    final l10n = appL10n(context);
    final projectedRegion = ref.watch(
          humanDraftProjectedRegionProvider(_currentRegion.regionId),
        ) ??
        _currentRegion;
    final turnNumber = widget.game.worldState.turnState.turnNumber;
    final year = turnToYear(turnNumber, widget.game.turnTimeMapping);
    final nextTurnText = shell.inObservePhase
        ? 'Observe — Turn $turnNumber ($year)'
        : l10n.game_nextTurnButton(turnNumber, year);
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
          cargoNotDefined: cargoSummary.notDefined,
          treasury: treasurySummary.treasury,
          treasuryDelta: treasurySummary.projectedDelta,
          treasuryNotDefined: treasurySummary.notDefined,
          observeBannerLabel: shell.observeBannerLabel,
          playerTurnEventsFeedCount: feedEntries.length,
          playerTurnEventsFeedNotDefined: !shell.showPlayerChrome,
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
                          humanPlayerId: mapPlayerId,
                          playerView: mapPlayerView,
                          visibilityMode: shell.mapVisibilityMode,
                          omniscientDetail: shell.omniscientDetail,
                          canMutateViaUi: shell.canMutateViaUi,
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
                            humanPlayerId: mapPlayerId,
                            narrow: isNarrow,
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
                            narrow: isNarrow,
                            onCycleBaseLayerDisplayMode:
                                _cycleBaseLayerDisplayMode,
                            onCenterOnHomeCapital: _centerOnHumanCapital,
                            homeToCapitalEnabled:
                                shell.effectiveHumanPlayerId != null,
                            onOpenMapDisplayOptions: () {
                              showDialog<void>(
                                context: context,
                                barrierColor: EditorialMonoclePalette
                                    .dialogScrim,
                                builder: (context) {
                                  return GameMapOptionsDialog(
                                    initialState: _mapViewState,
                                    onChanged: _setMapViewState,
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
                            child: GameSideMenuScrim(
                              onDismiss: () =>
                                  setState(() => _sideMenuOpen = false),
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
                                narrow: isNarrow,
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
                              if (!shell.showPlayerChrome ||
                                  !_mapViewState.showPlayerTurnEventsFeed) {
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
                        if (isNarrow &&
                            shell.showPlayerChrome &&
                            _mapViewState.showPlayerTurnEventsFeed)
                          Positioned(
                            right: kMapOverlayEdgeInset,
                            top: 56,
                            child: PlayerTurnEventFeedCard(
                              entries: feedEntries,
                              emptyLabel: 'No player events last turn.',
                              narrow: true,
                            ),
                          ),
                        if (!isNarrow && widget.game.victory == null)
                          GameMapPlayersBar(game: widget.game),
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
                    humanPlayerId: _debugConsolePlayerId ?? mapPlayerId,
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
                        humanPlayerId: mapPlayerId,
                        playerView: mapPlayerView,
                        omniscientDetail: shell.omniscientDetail,
                        canMutateViaUi: shell.canMutateViaUi,
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
